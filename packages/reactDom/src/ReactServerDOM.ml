type json = Yojson.Basic.t
type env = [ `Dev | `Prod ]

let is_dev = function `Dev -> true | `Prod -> false

module Key_validation = struct
  type site = Value | Static_slot | Dynamic_item

  let to_json ~site ~key : Yojson.Basic.t =
    match (site, key) with
    | Static_slot, _ -> `Int 1
    | Dynamic_item, None -> `Int 2
    | Value, _ | Dynamic_item, Some _ -> `Int 0
end

let create_stack_trace () =
  let slots = Printexc.backtrace_slots (Printexc.get_raw_backtrace ()) |> Option.value ~default:[||] in
  let make_locations slot =
    let location = Printexc.Slot.location slot in
    let name = Printexc.Slot.name slot in
    match (location, name) with
    | Some location, Some name ->
        `List
          [
            `String (Printf.sprintf "[SERVER] %s" name);
            `String location.Printexc.filename;
            `Int location.Printexc.line_number;
            `Int location.Printexc.start_char;
          ]
    | _, _ -> `List [ `String "Unknown function name"; `String "Unknown filename"; `Int 0; `Int 0 ]
  in
  `List (Array.to_list (Array.map make_locations slots))

let uuid_rng = Random.State.make_self_init ()

let generate_uuid () =
  Printf.sprintf "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" (Random.State.int uuid_rng 0xFFFF)
    (Random.State.int uuid_rng 0xFFFF) (Random.State.int uuid_rng 0xFFFF)
    (0x4000 lor Random.State.int uuid_rng 0x0FFF)
    (0x8000 lor Random.State.int uuid_rng 0x3FFF)
    (Random.State.int uuid_rng 0xFFFF) (Random.State.int uuid_rng 0xFFFF) (Random.State.int uuid_rng 0xFFFF)

let default_filter_stack_frame filename _function_name = filename <> ""

let capture_component_stack ~filter_stack_frame =
  let bt = Printexc.get_callstack 10 in
  let slots = Printexc.backtrace_slots bt |> Option.value ~default:[||] in
  let frames =
    Array.to_list
      (Array.map
         (fun slot ->
           match (Printexc.Slot.location slot, Printexc.Slot.name slot) with
           | Some loc, name_opt ->
               let name = Option.value ~default:"" name_opt in
               if filter_stack_frame loc.Printexc.filename name then
                 Some
                   (`List
                      [
                        `String name;
                        `String loc.Printexc.filename;
                        `Int loc.Printexc.line_number;
                        `Int loc.Printexc.start_char;
                      ])
               else None
           | _ -> None)
         slots)
  in
  `List (List.filter_map Fun.id frames)

module Physical_key : sig
  type t

  val make : 'a -> t
  val equal : t -> t -> bool
end = struct
  type t = Obj.t

  let make = Obj.repr
  let equal = ( == )
end

module Stream = struct
  type task = { row : int; kind : [ `Boundary of bool Lwt.t | `Model_row ]; mutable promise : unit Lwt.t }
  type lifecycle = Open | Aborting | Closed

  type 'a t = {
    push : 'a -> unit;
    push_import : 'a -> unit;
    close : unit -> unit;
    mutable lifecycle : lifecycle;
    mutable rx_injected : bool;
    mutable index : int;
    mutable root_pending : bool;
    mutable active_tasks : task list;
    written_client_references : (string * string, int) Hashtbl.t;
    written_symbols : (string, string) Hashtbl.t;
    written_hints : (string, unit) Hashtbl.t;
    pending_hints : 'a Queue.t;
    mutable written_promises : (Physical_key.t * int) list;
    mutable written_server_references : (Physical_key.t * int) list;
    mutable deferred_rows : (unit -> unit) list;
  }

  let close context =
    match context.lifecycle with
    | Closed -> ()
    | Open | Aborting ->
        context.lifecycle <- Closed;
        context.close ()

  let write context chunk = match context.lifecycle with Open -> context.push chunk | Aborting | Closed -> ()

  let write_import context chunk =
    match context.lifecycle with Open -> context.push_import chunk | Aborting | Closed -> ()

  let write_settlement context chunk =
    match context.lifecycle with Aborting -> context.push chunk | Open | Closed -> ()

  let write_delayed context to_chunk index =
    match context.lifecycle with Open -> context.push (to_chunk index) | Aborting | Closed -> ()

  let take_rx_definition context =
    if context.rx_injected then false
    else (
      context.rx_injected <- true;
      true)

  let push to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    write_delayed context to_chunk index;
    index

  let push_deferred to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    context.deferred_rows <- (fun () -> write_delayed context to_chunk index) :: context.deferred_rows;
    index

  let rec flush_deferred ~context =
    match context.deferred_rows with
    | [] -> ()
    | deferred ->
        context.deferred_rows <- [];
        List.iter (fun flush -> flush ()) (List.rev deferred);
        flush_deferred ~context

  let push_client_ref ~context ~import_module ~import_name to_chunk =
    let key = (import_module, import_name) in
    match Hashtbl.find_opt context.written_client_references key with
    | Some existing_index -> existing_index
    | None ->
        let index = context.index in
        context.index <- context.index + 1;
        write_import context (to_chunk index);
        Hashtbl.replace context.written_client_references key index;
        index

  let push_hint ~context ~dedup_key row =
    if not (Hashtbl.mem context.written_hints dedup_key) then (
      Hashtbl.replace context.written_hints dedup_key ();
      Queue.add row context.pending_hints)

  let rec find_by_physical_key key = function
    | [] -> None
    | (k, index) :: rest -> if Physical_key.equal k key then Some index else find_by_physical_key key rest

  let find_written_promise ~context key = find_by_physical_key key context.written_promises
  let remember_written_promise ~context key index = context.written_promises <- (key, index) :: context.written_promises

  let push_server_reference ~context ~key to_chunk =
    match find_by_physical_key key context.written_server_references with
    | Some existing_index -> existing_index
    | None ->
        let index = push to_chunk ~context in
        context.written_server_references <- (key, index) :: context.written_server_references;
        index

  let push_symbol ~context ~symbol ~reference_of_index make_chunk =
    match Hashtbl.find_opt context.written_symbols symbol with
    | Some reference -> reference
    | None ->
        let index = push (make_chunk ()) ~context in
        let reference = reference_of_index index in
        Hashtbl.replace context.written_symbols symbol reference;
        reference

  let push_task ~kind make_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    let written, resolve_written = Lwt.wait () in
    (match context.lifecycle with
    | Aborting | Closed -> ()
    | Open ->
        let task = { row = index; kind; promise = Lwt.return_unit } in
        context.active_tasks <- task :: context.active_tasks;
        let promise =
          let%lwt to_chunk = Lwt.apply make_chunk () in
          (match context.lifecycle with
          | Aborting | Closed -> ()
          | Open ->
              context.active_tasks <- List.filter (fun other -> other != task) context.active_tasks;
              Option.iter (fun to_chunk -> context.push (to_chunk index)) to_chunk;
              flush_deferred ~context;
              (match (context.active_tasks, context.root_pending) with [], false -> close context | _ -> ());
              Lwt.wakeup_later resolve_written (Option.is_some to_chunk));
          Lwt.return ()
        in
        task.promise <- promise;
        Lwt.on_failure promise (function Lwt.Canceled -> () | exn -> !Lwt.async_exception_hook exn));
    (index, written)

  let push_async make_chunk ~context =
    fst (push_task ~kind:`Model_row (fun () -> Lwt.map Option.some (make_chunk ())) ~context)

  let push_boundary_async ~parent make_chunk ~context =
    push_task ~kind:(`Boundary parent)
      (fun () ->
        let%lwt to_chunk = make_chunk () in
        let%lwt parent_written = parent in
        Lwt.return (if parent_written then Some to_chunk else None))
      ~context

  let begin_abort context =
    match context.lifecycle with
    | Aborting | Closed -> None
    | Open ->
        context.lifecycle <- Aborting;
        let tasks = context.active_tasks in
        context.active_tasks <- [];
        context.root_pending <- false;
        Some tasks

  let task_rows tasks = List.sort Int.compare (List.map (fun task -> task.row) tasks)

  let boundary_rows tasks =
    List.rev
      (List.filter_map
         (fun task ->
           match task.kind with
           | `Boundary parent -> (
               match Lwt.state parent with Return true -> Some task.row | Return false | Fail _ | Sleep -> None)
           | `Model_row -> None)
         tasks)

  let close_and_cancel context tasks =
    close context;
    List.iter (fun task -> Lwt.cancel task.promise) tasks

  let make ?(initial_index = 0) ?(root_pending = false) () =
    let stream, push_raw, close_raw = Push_stream.make () in
    let pending_hints = Queue.create () in
    let drain_hints () =
      if not (Queue.is_empty pending_hints) then (
        Queue.iter push_raw pending_hints;
        Queue.clear pending_hints)
    in
    ( stream,
      {
        push =
          (fun chunk ->
            drain_hints ();
            push_raw chunk);
        push_import = push_raw;
        close =
          (fun () ->
            drain_hints ();
            close_raw ());
        lifecycle = Open;
        rx_injected = false;
        root_pending;
        index = initial_index;
        active_tasks = [];
        written_client_references = Hashtbl.create 16;
        written_symbols = Hashtbl.create 4;
        written_hints = Hashtbl.create 8;
        pending_hints;
        written_promises = [];
        written_server_references = [];
        deferred_rows = [];
      } )
end

module Resources = struct
  let get_attribute ~key:key_to_get (attributes : Html.attribute_list) =
    List.find_map
      (fun attr -> match attr with `Value (key, value) when String.equal key key_to_get -> Some value | _ -> None)
      attributes

  let resource_key item =
    match (item : Html.node) with
    | { tag = "script"; attributes; _ } -> get_attribute ~key:"src" attributes
    | { tag = "link"; attributes; _ } -> get_attribute ~key:"href" attributes
    | _ -> None

  let add resource resources =
    match resource_key resource with
    | None -> Html.Node resource :: resources
    | Some key ->
        let exists = List.exists (function Html.Node node -> resource_key node = Some key | _ -> false) resources in
        if exists then resources else Html.Node resource :: resources
end

module Fiber = struct
  type t = {
    context : Html.element Stream.t;
    env : env;
    nonce : string option;
    debug : bool;
    filter_stack_frame : string -> string -> bool;
    mutable root_tag : string option;
    mutable head_element : Html.node option;
    mutable extra_head_children : Html.element list;
    mutable resources : Html.element list;
    mutable inside_head : bool;
    mutable inside_body : bool;
    mutable hoisted_count : int;
    mutable shell_flushed : bool;
    mutable html_attributes : Html.attribute_list;
  }

  let set_html_attributes ~fiber attrs = fiber.html_attributes <- attrs
  let push_head_element ~fiber head = fiber.head_element <- Some head
  let push_resource ~fiber resource = fiber.resources <- Resources.add resource fiber.resources

  let push_extra_head_child ~fiber children =
    fiber.extra_head_children <- Html.Node children :: fiber.extra_head_children

  let root_tag ~fiber = fiber.root_tag
  let set_root_tag ~fiber value = fiber.root_tag <- Some value
end

let map_children_with_tree_context f children =
  match children with
  | [] -> []
  | [ single ] -> [ f single ]
  | _ ->
      let saved_ctx = !React.current_tree_context in
      let total = List.length children in
      let results =
        List.mapi
          (fun i el ->
            React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:total ~index:i;
            f el)
          children
      in
      React.current_tree_context := saved_ctx;
      results

let with_provider_value ~push ~async_key ~async_value fn =
  let pop = push () in
  try%lwt
    let%lwt result = Lwt.with_value async_key (Some async_value) fn in
    pop ();
    Lwt.return result
  with exn ->
    pop ();
    Lwt.reraise exn

type abort_reason = Timeout | Aborted

let abort_message = function Timeout -> "The render timed out." | Aborted -> "The render was aborted."
let abort_error reason = { React.message = abort_message reason; stack = `Null; env = "Server"; digest = "" }

module Model = struct
  type chunk = Value of json | Debug_ref of json | Component_ref of json | Error of env * React.error

  let make_error_json ~env ~message ~stack ~digest : json =
    match is_dev env with
    | true ->
        `Assoc [ ("message", `String message); ("stack", stack); ("env", `String "Server"); ("digest", `String digest) ]
    | false -> `Assoc [ ("digest", `String digest) ]

  let exn_to_error exn =
    let message = Printexc.to_string exn in
    let stack = create_stack_trace () in
    { React.message; stack; env = "Server"; digest = "" }

  let lazy_value id = Printf.sprintf "$L%x" id
  let promise_value id = Printf.sprintf "$@%x" id
  let ref_value id = Printf.sprintf "$%x" id
  let error_value id = Printf.sprintf "$Z%x" id
  let action_value id = Printf.sprintf "$F%x" id

  let escape_string_value value =
    if String.length value > 0 && String.unsafe_get value 0 = '$' then "$" ^ value else value

  let max_safe_integer = 9007199254740992.

  let float_to_json value : json =
    if Float.is_nan value then `String "$NaN"
    else if value = Float.infinity then `String "$Infinity"
    else if value = Float.neg_infinity then `String "$-Infinity"
    else if value = 0. && Float.sign_bit value then `String "$-0"
    else if Float.is_integer value && Float.abs value <= max_safe_integer then `Int (Float.to_int value)
    else `Float value

  let rec write_json buf (json : json) =
    match json with
    | `Float value -> Buffer.add_string buf (Js.Float.toString value)
    | `List items ->
        Buffer.add_char buf '[';
        List.iteri
          (fun i item ->
            if i > 0 then Buffer.add_char buf ',';
            write_json buf item)
          items;
        Buffer.add_char buf ']'
    | `Assoc pairs ->
        Buffer.add_char buf '{';
        List.iteri
          (fun i (key, value) ->
            if i > 0 then Buffer.add_char buf ',';
            Yojson.Basic.write_json buf (`String key);
            Buffer.add_char buf ':';
            write_json buf value)
          pairs;
        Buffer.add_char buf '}'
    | (`String _ | `Int _ | `Bool _ | `Null) as scalar -> Yojson.Basic.write_json buf scalar

  let rec map_sharing f = function
    | [] -> []
    | x :: rest as list ->
        let x' = f x in
        let rest' = map_sharing f rest in
        if x' == x && rest' == rest then list else x' :: rest'

  let rec escape_model_json (json : json) : json =
    match json with
    | `String value ->
        let escaped = escape_string_value value in
        if escaped == value then json else `String escaped
    | `Float value -> float_to_json value
    | `List items ->
        let items' = map_sharing escape_model_json items in
        if items' == items then json else `List items'
    | `Assoc pairs ->
        let escape_pair ((key, value) as pair) =
          let value' = escape_model_json value in
          if value' == value then pair else (key, value')
        in
        let pairs' = map_sharing escape_pair pairs in
        if pairs' == pairs then json else `Assoc pairs'
    | (`Bool _ | `Int _ | `Null) as scalar -> scalar

  let style_to_json style =
    `Assoc (List.map (fun (_, jsx_key, value) -> (jsx_key, `String (escape_string_value value))) style)

  let action_to_json (action : _ Runtime.server_function) =
    `Assoc [ ("id", `String (escape_string_value action.id)); ("bound", `Null) ]

  let outline_server_function ~context ~to_chunk fn =
    let index =
      Stream.push_server_reference ~context ~key:(Physical_key.make fn) (to_chunk (Value (action_to_json fn)))
    in
    action_value index

  let prop_to_json ~context ~to_chunk (prop : React.JSX.prop) =
    match prop with
    | Bool (_, key, value) -> Some (key, `Bool value)
    | BooleanishString (_, key, value) -> Some (key, `Bool value)
    | String (_, key, _) when key = "key" -> None
    | String (_, key, value) -> Some (key, `String (escape_string_value value))
    | Int (_, key, value) -> Some (key, `Int value)
    | Float (_, key, value) -> Some (key, float_to_json value)
    | Style value -> Some ("style", style_to_json value)
    | DangerouslyInnerHtml html ->
        Some ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String (escape_string_value html)) ])
    | Ref _ -> None
    | Event _ -> None
    | Action (_, key, f) -> Some (key, `String (outline_server_function ~context ~to_chunk f))

  let props_to_json ~context ~to_chunk props = List.filter_map (prop_to_json ~context ~to_chunk) props
  let chunk_ref_or_null = function None -> `Null | Some idx -> `String (ref_value idx)

  let node ~env ~site ~tag ?(key = None) ~props ?(owner = None) children : json =
    let tail =
      match env with `Prod -> [] | `Dev -> [ chunk_ref_or_null owner; `Null; Key_validation.to_json ~site ~key ]
    in
    let key = match key with None -> `Null | Some key -> `String key in
    let props =
      match children with
      | [] -> props
      | [ one_children ] -> ("children", one_children) :: props
      | childrens -> ("children", `List childrens) :: props
    in
    `List (`String "$" :: `String tag :: key :: `Assoc props :: tail)

  let symbol_tag ~context ~to_chunk symbol =
    Stream.push_symbol ~context ~symbol ~reference_of_index:ref_value (fun () ->
        to_chunk (Value (`String ("$S" ^ symbol))))

  let suspense_node ~env ~site ~tag ~key ~fallback children : json =
    let fallback_prop = match fallback with None -> [] | Some fallback -> [ ("fallback", fallback) ] in
    let props =
      match children with
      | [] -> fallback_prop
      | [ one ] -> ("children", one) :: fallback_prop
      | _ -> ("children", `List children) :: fallback_prop
    in
    node ~env ~site ~tag ~key ~props []

  let suspense_placeholder ~env ~site ~tag ~key ~fallback index =
    suspense_node ~env ~site ~tag ~key ~fallback [ `String (lazy_value index) ]

  let component_ref ~module_ ~name =
    let id = `String module_ in
    let chunks = `List [] in
    let component_name = `String name in
    `List [ id; chunks; component_name ]

  let value_to_chunk id value =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    write_json buf value;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let debug_info_to_chunk id debug_info =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:D" id);
    write_json buf debug_info;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let client_reference_to_chunk id ref =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:I" id);
    write_json buf ref;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let error_to_chunk id error =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:E" id);
    write_json buf error;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let hint_to_chunk code payload =
    let buf = Buffer.create 64 in
    Buffer.add_string buf ":H";
    Buffer.add_string buf code;
    write_json buf payload;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let to_chunk value id =
    match value with
    | Value value -> value_to_chunk id value
    | Debug_ref debug_info -> debug_info_to_chunk id debug_info
    | Component_ref ref -> client_reference_to_chunk id ref
    | Error (env, error) ->
        let error_json = make_error_json ~env ~message:error.message ~stack:error.stack ~digest:error.digest in
        error_to_chunk id error_json

  let make_debug_info ?owner ~stack name =
    `Assoc
      [
        ("name", `String name);
        ("env", `String "Server");
        ("key", `Null);
        ("owner", chunk_ref_or_null owner);
        ("stack", stack);
        ("props", `Assoc []);
      ]

  let emit_debug_info_row ~filter_stack_frame ~context ~to_chunk ~name ~debug_info =
    let owner_idx = Option.map fst debug_info in
    let stack = capture_component_stack ~filter_stack_frame in
    let chunk = make_debug_info ?owner:owner_idx ~stack name in
    let debug_info_idx = Stream.push ~context (to_chunk (Value chunk)) in
    (debug_info_idx, owner_idx)

  let rec element_to_payload ?(debug = false) ?(filter_stack_frame = default_filter_stack_frame) ?debug_info ~context
      ~to_chunk ~env ~site element =
    let emit_debug_info ~name ~debug_info =
      emit_debug_info_row ~filter_stack_frame ~context ~to_chunk ~name ~debug_info
    in
    let outline_with_debug_ref ~name ~debug_info ~render_child =
      let model_index = context.index in
      context.index <- context.index + 1;
      let debug_info_idx, owner_idx = emit_debug_info ~name ~debug_info in
      let new_debug_info = Some (debug_info_idx, owner_idx) in
      let child_payload = render_child ~debug_info:new_debug_info in
      Stream.write context (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) model_index);
      Stream.write context (to_chunk (Value child_payload) model_index);
      `String (ref_value model_index)
    in
    let attach_debug_info ~name ~debug_info ~render_child =
      match debug_info with
      | None ->
          let debug_info_idx, _ = emit_debug_info ~name ~debug_info:None in
          Stream.write context (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) 0);
          render_child ~debug_info:(Some (debug_info_idx, None))
      | Some _ -> outline_with_debug_ref ~name ~debug_info ~render_child
    in
    let rec turn_element_into_payload ~context ~debug_info ~(site : Key_validation.site) element =
      match (element : React.element) with
      | Empty -> `Null
      | Static_list children -> items ~context ~debug_info ~site:Key_validation.Static_slot children
      | Static { original; _ } -> turn_element_into_payload ~context ~debug_info ~site original
      | Writer { original; _ } -> turn_element_into_payload ~context ~debug_info ~site (original ())
      | Text t -> `String (escape_string_value t)
      | Int i -> `Int i
      | Float f -> float_to_json f
      | Lower_case_element { key; tag; attributes; children } ->
          let props = props_to_json ~context ~to_chunk attributes in
          let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
          node ~env ~site ~key ~tag ~props ~owner
            (map_children_with_tree_context (turn_element_into_payload ~context ~debug_info ~site:Static_slot) children)
      | Fragment { key = None; children } -> turn_element_into_payload ~context ~debug_info ~site:Static_slot children
      | Fragment { key; children } ->
          let tag = symbol_tag ~context ~to_chunk "react.fragment" in
          let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
          node ~env ~site ~key ~tag ~props:[] ~owner
            [ turn_element_into_payload ~context ~debug_info ~site:Static_slot children ]
      | List children -> items ~context ~debug_info ~site:Key_validation.Dynamic_item children
      | Array children -> items ~context ~debug_info ~site:Key_validation.Dynamic_item (Array.to_list children)
      | Upper_case_component (name, component) -> (
          let saved_ctx = !React.current_tree_context in
          React.reset_component_id_state saved_ctx;
          let render element =
            let did_use_id = React.check_did_render_id_hook () in
            if did_use_id then
              React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
            let result = component_result ~context ~debug_info ~name element in
            React.current_tree_context := saved_ctx;
            result
          in
          let render_error exn =
            React.current_tree_context := saved_ctx;
            to_chunk (Error (env, exn_to_error exn))
          in
          let rec retry replayed =
            React.reset_component_id_state saved_ctx;
            match React.call_with_promise_replay replayed component with
            | Ok element -> Lwt.return (to_chunk (Value (render element)))
            | Error (any_promise, used) ->
                React.current_tree_context := saved_ctx;
                retry_after any_promise used
            | exception exn -> Lwt.return (render_error exn)
          and retry_after (React.Any_promise promise) used =
            try%lwt
              let%lwt _ = promise in
              retry used
            with exn -> Lwt.return (render_error exn)
          in
          match React.call_with_promise_replay [] component with
          | Ok element -> render element
          | Error (any_promise, used) ->
              React.current_tree_context := saved_ctx;
              let index = Stream.push_async (fun () -> retry_after any_promise used) ~context in
              `String (lazy_value index)
          | exception exn ->
              React.current_tree_context := saved_ctx;
              let error = exn_to_error exn in
              let index = Stream.push_deferred ~context (to_chunk (Error (env, error))) in
              `String (lazy_value index))
      | Async_component (name, component) -> (
          let saved_ctx = !React.current_tree_context in
          React.reset_component_id_state saved_ctx;
          let promise =
            try component ()
            with exn ->
              React.current_tree_context := saved_ctx;
              raise exn
          in
          match Lwt.state promise with
          | Fail exn ->
              React.current_tree_context := saved_ctx;
              let error = exn_to_error exn in
              let index = Stream.push_deferred ~context (to_chunk (Error (env, error))) in
              `String (lazy_value index)
          | Return element ->
              let did_use_id = React.check_did_render_id_hook () in
              if did_use_id then
                React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
              let result = component_result ~context ~debug_info ~name element in
              React.current_tree_context := saved_ctx;
              result
          | Sleep ->
              let did_use_id = React.check_did_render_id_hook () in
              if did_use_id then
                React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
              let promise =
                try%lwt
                  let%lwt element = promise in
                  let payload = component_result ~context ~debug_info ~name element in
                  let result = to_chunk (Value payload) in
                  React.current_tree_context := saved_ctx;
                  Lwt.return result
                with exn ->
                  React.current_tree_context := saved_ctx;
                  let error = exn_to_error exn in
                  Lwt.return (to_chunk (Error (env, error)))
              in
              let index = Stream.push_async (fun () -> promise) ~context in
              `String (lazy_value index))
      | Suspense { key; children; fallback } ->
          let tag = symbol_tag ~context ~to_chunk "react.suspense" in
          let children = turn_element_into_payload ~context ~debug_info ~site:Static_slot children in
          let fallback = Option.map (turn_element_into_payload ~context ~debug_info ~site:Static_slot) fallback in
          suspense_node ~env ~site ~tag ~key ~fallback [ children ]
      | Client_component { key; import_module; import_name; props; client = _ } ->
          let ref = component_ref ~module_:import_module ~name:import_name in
          let index = Stream.push_client_ref ~context ~import_module ~import_name (to_chunk (Component_ref ref)) in
          let client_props = models_to_payload ~context ~debug ~filter_stack_frame ~to_chunk ~env props in
          node ~env ~site ~tag:(lazy_value index) ~key ~props:client_props []
      | Provider { children; push; async_key; async_value } ->
          let pop = push () in
          Fun.protect ~finally:pop (fun () ->
              Lwt.with_value async_key (Some async_value) (fun () ->
                  turn_element_into_payload ~context ~debug_info ~site:Static_slot children))
      | Consumer children -> turn_element_into_payload ~context ~debug_info ~site:Static_slot children
    and items ~context ~debug_info ~site children =
      `List (map_children_with_tree_context (turn_element_into_payload ~context ~debug_info ~site) children)
    and component_result ~context ~debug_info ~name element =
      if debug then
        attach_debug_info ~name ~debug_info ~render_child:(fun ~debug_info ->
            turn_element_into_payload ~context ~debug_info ~site:Static_slot element)
      else turn_element_into_payload ~context ~debug_info ~site:Static_slot element
    in
    turn_element_into_payload ~context ~debug_info ~site element

  and model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site value =
    match (value : React.model_value) with
    | Json json -> escape_model_json json
    | Error error ->
        let index = Stream.push_deferred ~context (to_chunk (Error (env, error))) in
        `String (error_value index)
    | Element element -> element_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site element
    | Promise (promise, value_to_model) -> (
        let written_key = Physical_key.make promise in
        match Stream.find_written_promise ~context written_key with
        | Some index -> `String (promise_value index)
        | None ->
            let index =
              match Lwt.state promise with
              | Return value ->
                  Stream.push_deferred ~context (fun index ->
                      match
                        model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site:Value
                          (value_to_model value)
                      with
                      | payload -> to_chunk (Value payload) index
                      | exception exn -> to_chunk (Error (env, exn_to_error exn)) index)
              | Sleep ->
                  let promise =
                    try%lwt
                      let%lwt value = promise in
                      let model = value_to_model value in
                      let payload =
                        model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site:Value model
                      in
                      Lwt.return (to_chunk (Value payload))
                    with exn ->
                      let error = exn_to_error exn in
                      Lwt.return (to_chunk (Error (env, error)))
                  in
                  Stream.push_async (fun () -> promise) ~context
              | Fail exn ->
                  let error = exn_to_error exn in
                  Stream.push_deferred ~context (to_chunk (Error (env, error)))
            in
            Stream.remember_written_promise ~context written_key index;
            `String (promise_value index))
    | List list ->
        `List (List.map (model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site:Dynamic_item) list)
    | Assoc assoc -> `Assoc (models_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env assoc)
    | Function action -> `String (outline_server_function ~context ~to_chunk action)

  and models_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env props =
    List.map
      (fun (name, value) ->
        (name, model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env ~site:Value value))
      props

  let element_to_root_payload ?(debug = false) ?(filter_stack_frame = default_filter_stack_frame) ~context ~to_chunk
      ~env element =
    let rec go ~debug_info ~(site : Key_validation.site) (element : React.element) =
      match element with
      | React.Static { original; _ } -> go ~debug_info ~site original
      | Writer { original; _ } -> go ~debug_info ~site (original ())
      | Fragment { key = None; children } -> go ~debug_info ~site:Static_slot children
      | Consumer children -> go ~debug_info ~site:Static_slot children
      | Provider { children; push; async_key; async_value } ->
          with_provider_value ~push ~async_key ~async_value (fun () -> go ~debug_info ~site:Static_slot children)
      | (Upper_case_component _ | Async_component _) when debug && Option.is_some debug_info ->
          Lwt.return (element_to_payload ~debug ~filter_stack_frame ?debug_info ~context ~to_chunk ~env ~site element)
      | Upper_case_component (name, component) ->
          let saved_ctx = !React.current_tree_context in
          let rec render replayed =
            React.reset_component_id_state saved_ctx;
            match React.call_with_promise_replay replayed component with
            | Ok element ->
                let did_use_id = React.check_did_render_id_hook () in
                if did_use_id then
                  React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
                let%lwt payload = continue_with_debug ~name ~debug_info element in
                React.current_tree_context := saved_ctx;
                Lwt.return payload
            | Error (Any_promise promise, used) -> (
                React.current_tree_context := saved_ctx;
                try%lwt
                  let%lwt _ = promise in
                  render used
                with exn ->
                  React.current_tree_context := saved_ctx;
                  Lwt.reraise exn)
            | exception exn ->
                React.current_tree_context := saved_ctx;
                raise exn
          in
          render []
      | Async_component (name, component) -> (
          let saved_ctx = !React.current_tree_context in
          React.reset_component_id_state saved_ctx;
          let promise =
            try component ()
            with exn ->
              React.current_tree_context := saved_ctx;
              raise exn
          in
          let did_use_id = React.check_did_render_id_hook () in
          if did_use_id then React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
          try%lwt
            let%lwt element = promise in
            let%lwt payload = continue_with_debug ~name ~debug_info element in
            React.current_tree_context := saved_ctx;
            Lwt.return payload
          with exn ->
            React.current_tree_context := saved_ctx;
            Lwt.reraise exn)
      | element ->
          Lwt.return (element_to_payload ~debug ~filter_stack_frame ?debug_info ~context ~to_chunk ~env ~site element)
    and continue_with_debug ~name ~debug_info element =
      match (debug, debug_info) with
      | true, None ->
          let debug_info_idx, _ = emit_debug_info_row ~filter_stack_frame ~context ~to_chunk ~name ~debug_info:None in
          Stream.write context (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) 0);
          go ~debug_info:(Some (debug_info_idx, None)) ~site:Static_slot element
      | _ -> go ~debug_info ~site:Static_slot element
    in
    go ~debug_info:None ~site:Value element

  let model_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env (value : React.model_value) =
    match value with
    | Element element -> element_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env element
    | other -> Lwt.return (model_to_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env ~site:Value other)

  let push_root_task ?debug ?filter_stack_frame ~context ~env model =
    Stream.push_async ~context (fun () ->
        try%lwt
          let%lwt model = model in
          let%lwt payload = model_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env model in
          Lwt.return (to_chunk (Value payload))
        with exn -> Lwt.return (to_chunk (Error (env, exn_to_error exn))))

  let hint_sink ~context { Flight_hints.dedup_key; code; payload } =
    Stream.push_hint ~context ~dedup_key (hint_to_chunk code payload)

  let abort ~env ~reason context =
    match Stream.begin_abort context with
    | None -> ()
    | Some tasks ->
        let error = abort_error reason in
        List.iter
          (fun index -> Stream.write_settlement context (to_chunk (Error (env, error)) index))
          (Stream.task_rows tasks);
        Stream.close_and_cancel context tasks

  let abort_signal_trigger abort =
    Lwt.try_bind (fun () -> Lwt.protected abort) (fun () -> Lwt.return Aborted) (fun _exn -> Lwt.return Aborted)

  let abort_triggers ~timeout ~abort =
    let timeout =
      match timeout with
      | None -> []
      | Some seconds ->
          [
            (let%lwt () = Lwt_unix.sleep seconds in
             Lwt.return Timeout);
          ]
    in
    let abort = match abort with None -> [] | Some abort -> [ abort_signal_trigger abort ] in
    timeout @ abort

  let run_stream ~env ~debug ?filter_stack_frame ?subscribe ?timeout ?abort:abort_signal model =
    let stream, context = Stream.make () in
    Flight_hints.with_sink (hint_sink ~context) (fun () ->
        let (_root_index : int) = push_root_task ~debug ?filter_stack_frame ~context ~env model in
        match (subscribe, abort_triggers ~timeout ~abort:abort_signal) with
        | None, [] -> Lwt.return ()
        | subscribe, triggers ->
            let subscribe = Option.value subscribe ~default:(fun _ -> Lwt.return ()) in
            let subscription = Lwt_stream.iter_s subscribe stream in
            let watcher =
              match triggers with
              | [] -> None
              | triggers ->
                  Some
                    (let%lwt reason = Lwt.pick triggers in
                     abort ~env ~reason context;
                     Lwt.return ())
            in
            let stop_watching () = Option.iter Lwt.cancel watcher in
            Lwt.try_bind
              (fun () -> subscription)
              (fun () ->
                stop_watching ();
                Lwt.return ())
              (fun exn ->
                (match Stream.begin_abort context with
                | None -> ()
                | Some tasks -> Stream.close_and_cancel context tasks);
                stop_watching ();
                Lwt.reraise exn))

  let render ?(env = `Prod) ?(debug = false) ?filter_stack_frame ?subscribe ?timeout ?abort ?identifier_prefix model =
    React.reset_id_rendering ?prefix:identifier_prefix ();
    run_stream ~env ~debug ?filter_stack_frame ?subscribe ?timeout ?abort (Lwt.return model)

  let create_action_response ?(env = `Prod) ?(debug = false) ?filter_stack_frame ?subscribe ?timeout ?abort response =
    let root =
      try%lwt response
      with exn ->
        let message = Printexc.to_string exn in
        let stack = create_stack_trace () in
        let digest = generate_uuid () in
        Lwt.return (React.Model.Error { message; stack; env = "Server"; digest })
    in
    let run root = run_stream ~env ~debug ?filter_stack_frame ?subscribe ?timeout ?abort root in
    match (subscribe, timeout, abort) with
    | None, None, None ->
        let%lwt root = root in
        run (Lwt.return root)
    | _ -> run root
end

let script ?nonce attributes children =
  let attributes = match nonce with None -> attributes | Some nonce -> Html.attribute "nonce" nonce :: attributes in
  Html.node "script" attributes children

let rsc_start_script ?nonce () =
  script ?nonce []
    [
      Html.raw
        {|
let enc = new TextEncoder();
let srr_stream = (window.srr_stream = {});
srr_stream.push = () => {
  srr_stream._c.enqueue(enc.encode(document.currentScript.dataset.payload));
};
srr_stream.close = () => {
  srr_stream._c.close();
};
srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });
|};
    ]

let rc_function_definition = Fizz_instructions.complete_boundary
let rc_function_script ?nonce () = script ?nonce [] [ Html.raw rc_function_definition ]
let rx_function_definition = Fizz_instructions.client_render_boundary

let client_render_abort_message reason =
  "Switched to client rendering because the server rendering aborted due to:\n\n" ^ abort_message reason

let client_render_boundary_to_chunk ?nonce ~env ~message ~include_definition index =
  let rx_call =
    match env with
    | `Prod -> Printf.sprintf {|$RX("B:%x","")|} index
    | `Dev -> Printf.sprintf {|$RX("B:%x","","%s")|} index (Html.escape_for_inline_script message)
  in
  script ?nonce [] [ Html.raw (if include_definition then rx_function_definition ^ ";" ^ rx_call else rx_call) ]

let client_render_error_message exn =
  "Switched to client rendering because the server rendering errored:\n\n" ^ Printexc.to_string exn

let payload_to_html_chunk ?nonce payload =
  match nonce with
  | None ->
      Html.raw
        (Printf.sprintf "<script data-payload='%s'>window.srr_stream.push()</script>"
           (Html.escape_attribute_value payload))
  | Some nonce -> script ~nonce [ Html.attribute "data-payload" payload ] [ Html.raw "window.srr_stream.push()" ]

let model_to_chunk ?nonce model index = payload_to_html_chunk ?nonce (Model.to_chunk model index)
let hint_row_to_html_chunk ?nonce code payload = payload_to_html_chunk ?nonce (Model.hint_to_chunk code payload)

let boundary_to_chunk ?nonce html index =
  let rc_replacement b s = script ?nonce [] [ Html.raw (Printf.sprintf "$RC('B:%x', 'S:%x')" b s) ] in
  Html.list ~separator:"\n"
    [
      Html.node "div" [ Html.present "hidden"; Html.attribute "id" (Printf.sprintf "S:%x" index) ] [ html ];
      rc_replacement index index;
    ]

let html_suspense_immediate inner = Html.list [ Html.raw "<!--$-->"; inner; Html.raw "<!--/$-->" ]

let html_suspense_placeholder ~fallback id =
  Html.list
    [
      Html.raw "<!--$?-->";
      Html.node "template" [ Html.attribute "id" (Printf.sprintf "B:%x" id) ] [];
      fallback;
      Html.raw "<!--/$-->";
    ]

let html_suspense_client_render ~env ~exn ~fallback =
  let template =
    match env with
    | `Prod -> Html.node "template" [] []
    | `Dev ->
        let backtrace = Printexc.get_backtrace () in
        Html.node "template" [ Html.attribute "data-msg" (Printexc.to_string exn ^ "\n" ^ backtrace) ] []
  in
  Html.list [ Html.raw "<!--$!-->"; template; fallback; Html.raw "<!--/$-->" ]

let chunk_stream_end_script ?nonce () = script ?nonce [] [ Html.raw "window.srr_stream.close()" ]

let map_children_with_tree_context_lwt f children =
  match children with
  | [] -> Lwt.return []
  | [ single ] -> (
      let promise = f single in
      match Lwt.state promise with
      | Return result -> Lwt.return [ result ]
      | Sleep | Fail _ ->
          let%lwt result = promise in
          Lwt.return [ result ])
  | _ -> (
      let saved_ctx = !React.current_tree_context in
      let total = List.length children in
      let rec loop i results = function
        | [] ->
            React.current_tree_context := saved_ctx;
            Lwt.return (List.rev results)
        | el :: rest -> (
            React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:total ~index:i;
            let promise = f el in
            match Lwt.state promise with
            | Return result -> loop (i + 1) (result :: results) rest
            | Sleep | Fail _ ->
                let%lwt result = promise in
                loop (i + 1) (result :: results) rest)
      in
      try%lwt loop 0 [] children
      with exn ->
        React.current_tree_context := saved_ctx;
        Lwt.reraise exn)

let action_id_prefix = "$ACTION_ID_"

let host_attributes_to_html ~tag attributes =
  let server_action_id name =
    List.find_map
      (fun (prop : React.JSX.prop) ->
        match prop with
        | Action (prop_name, _, f) when String.equal (String.lowercase_ascii prop_name) name -> Some f.id
        | _ -> None)
      attributes
  in
  let attributes_to_html_without names extra =
    let kept =
      List.filter (fun prop -> not (List.mem (String.lowercase_ascii (React.prop_key prop)) names)) attributes
    in
    ReactDOM.attributes_to_html kept @ extra
  in
  match tag with
  | "form" -> (
      match server_action_id "action" with
      | None -> (ReactDOM.attributes_to_html attributes, [])
      | Some id ->
          ( attributes_to_html_without [ "method"; "enctype"; "target" ]
              [
                Html.attribute "action" "";
                Html.attribute "encType" "multipart/form-data";
                Html.attribute "method" "POST";
              ],
            [
              Html.node "input"
                [
                  Html.attribute "type" "hidden";
                  Html.attribute "name" (action_id_prefix ^ id);
                  Html.attribute "value" "";
                ]
                [];
            ] ))
  | "button" | "input" -> (
      match server_action_id "formaction" with
      | None -> (ReactDOM.attributes_to_html attributes, [])
      | Some id ->
          ( attributes_to_html_without
              [ "name"; "formmethod"; "formenctype"; "formtarget" ]
              [
                Html.attribute "name" (action_id_prefix ^ id);
                Html.attribute "formAction" "";
                Html.attribute "formEncType" "multipart/form-data";
                Html.attribute "formMethod" "POST";
              ],
            [] ))
  | _ -> (ReactDOM.attributes_to_html attributes, [])

let segment_written_key : bool Lwt.t Lwt.key = Lwt.new_key ()
let segment_written () = Option.value (Lwt.get segment_written_key) ~default:(Lwt.return true)

let with_segment render =
  let written, resolve = Lwt.wait () in
  let settle outcome = Lwt.on_success outcome (Lwt.wakeup_later resolve) in
  (settle, fun () -> Lwt.with_value segment_written_key (Some written) render)

let written_with promise ~chunk_written =
  Lwt.try_bind (fun () -> promise) (fun _ -> chunk_written) (fun _ -> Lwt.return false)

let rec client_to_html ~(fiber : Fiber.t) (element : React.element) =
  match element with
  | Empty -> Lwt.return Html.null
  | Static { prerendered; _ } -> Lwt.return (Html.raw prerendered)
  | Writer { original; _ } -> client_to_html ~fiber (original ())
  | Text text -> Lwt.return (Html.string text)
  | Int i -> Lwt.return (Html.string (Int.to_string i))
  | Float f -> Lwt.return (Html.string (Js.Float.toString f))
  | Fragment { children; _ } -> client_to_html ~fiber children
  | List childrens | Static_list childrens ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) childrens in
      Lwt.return (Html.list html)
  | Array childrens ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) (Array.to_list childrens) in
      Lwt.return (Html.list html)
  | Lower_case_element { tag; attributes; children; _ } -> render_lower_case ~fiber ~tag ~attributes ~children
  | Upper_case_component (_name, component) ->
      let saved_ctx = !React.current_tree_context in
      React.reset_component_id_state saved_ctx;
      let rec wait_for_suspense_to_resolve replayed =
        match React.call_with_promise_replay replayed component with
        | Error (Any_promise promise, used) ->
            let%lwt _ = promise in
            wait_for_suspense_to_resolve used
        | exception exn ->
            React.current_tree_context := saved_ctx;
            raise exn
        | Ok output ->
            let did_use_id = React.check_did_render_id_hook () in
            if did_use_id then
              React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
            let%lwt result = client_to_html ~fiber output in
            React.current_tree_context := saved_ctx;
            Lwt.return result
      in
      wait_for_suspense_to_resolve []
  | Async_component (_, component) -> (
      let saved_ctx = !React.current_tree_context in
      React.reset_component_id_state saved_ctx;
      try%lwt
        let%lwt element = component () in
        let did_use_id = React.check_did_render_id_hook () in
        if did_use_id then React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
        let%lwt result = client_to_html ~fiber element in
        React.current_tree_context := saved_ctx;
        Lwt.return result
      with exn ->
        React.current_tree_context := saved_ctx;
        raise exn)
  | Suspense { key = _; children; fallback } -> (
      let%lwt fallback_html = client_to_html ~fiber (Option.value fallback ~default:React.null) in
      let context = fiber.context in
      let parent = segment_written () in
      let settle, render_children = with_segment (fun () -> client_to_html ~fiber children) in
      try%lwt
        let promise = render_children () in
        match Lwt.state promise with
        | Return html ->
            settle parent;
            Lwt.return (html_suspense_immediate html)
        | Sleep ->
            let async =
              try%lwt
                let%lwt html = promise in
                Lwt.return (boundary_to_chunk ?nonce:fiber.nonce html)
              with exn ->
                Lwt.return (fun index ->
                    client_render_boundary_to_chunk ?nonce:fiber.nonce ~env:fiber.env
                      ~message:(client_render_error_message exn) ~include_definition:(Stream.take_rx_definition context)
                      index)
            in
            let index, chunk_written = Stream.push_boundary_async ~parent ~context (fun () -> async) in
            settle (written_with promise ~chunk_written);
            Lwt.return (html_suspense_placeholder ~fallback:fallback_html index)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        settle (Lwt.return false);
        Lwt.return (html_suspense_client_render ~env:fiber.env ~exn ~fallback:fallback_html))
  | Client_component { client; _ } -> client_to_html ~fiber client
  | Provider { children; push; async_key; async_value } ->
      with_provider_value ~push ~async_key ~async_value (fun () -> client_to_html ~fiber children)
  | Consumer children -> client_to_html ~fiber children

and render_lower_case ~fiber ~tag ~attributes ~children =
  let html_props, action_input = host_attributes_to_html ~tag attributes in
  match ReactDOM.getDangerouslyInnerHtml attributes with
  | Some inner_html -> Lwt.return (Html.node tag html_props (action_input @ [ Html.raw inner_html ]))
  | None ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) children in
      Lwt.return (Html.node tag html_props (action_input @ html))

let is_async props =
  let open React.JSX in
  let has_async prop = match prop with Bool ("async", _, value) -> value | _ -> false in
  List.exists has_async props

let has_precedence_and_rel_stylesheet props =
  let open React.JSX in
  let has_precedence prop = match prop with String ("precedence", _, _) -> true | _ -> false in
  let has_rel_stylesheet prop = match prop with String ("rel", _, "stylesheet") -> true | _ -> false in
  List.exists has_precedence props && List.exists has_rel_stylesheet props

type element_role = Html_root | Head_section | Body_section | Hoistable_resource | Hoistable_meta | Regular

let classify_element ~(fiber : Fiber.t) ~tag ~attributes =
  if fiber.inside_head && not fiber.inside_body then Regular
  else
    match tag with
    | "html" -> ( match Fiber.root_tag ~fiber with Some "html" -> Html_root | _ -> Regular)
    | "head" -> Head_section
    | "body" -> Body_section
    | _ when tag = "script" && is_async attributes -> Hoistable_resource
    | _ when tag = "link" && has_precedence_and_rel_stylesheet attributes -> Hoistable_resource
    | "title" | "meta" | "link" -> Hoistable_meta
    | _ -> Regular

let rec render_element_to_html ~(fiber : Fiber.t) ~debug_info ~(site : Key_validation.site) (element : React.element) :
    (Html.element * json) Lwt.t =
  match element with
  | Static_list list -> elements_to_html ~fiber ~debug_info ~site:Static_slot list
  | Empty -> Lwt.return (Html.null, `Null)
  | Static { prerendered; original } ->
      let hoisted_before = fiber.hoisted_count in
      let%lwt html, model = render_element_to_html ~fiber ~debug_info ~site original in
      if fiber.hoisted_count = hoisted_before then Lwt.return (Html.raw prerendered, model) else Lwt.return (html, model)
  | Writer { original; _ } -> render_element_to_html ~fiber ~debug_info ~site (original ())
  | Text s -> Lwt.return (Html.string s, `String (Model.escape_string_value s))
  | Int i -> Lwt.return (Html.string (Int.to_string i), `Int i)
  | Float f -> Lwt.return (Html.string (Js.Float.toString f), Model.float_to_json f)
  | Fragment { key = None; children } -> render_element_to_html ~fiber ~debug_info ~site:Static_slot children
  | Fragment { key; children } ->
      let tag =
        Model.symbol_tag ~context:fiber.context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) "react.fragment"
      in
      let%lwt html, model = render_element_to_html ~fiber ~debug_info ~site:Static_slot children in
      let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
      Lwt.return (html, Model.node ~env:fiber.env ~site ~tag ~key ~props:[] ~owner [ model ])
  | List list -> elements_to_html ~fiber ~debug_info ~site:Dynamic_item list
  | Array arr -> elements_to_html ~fiber ~debug_info ~site:Dynamic_item (Array.to_list arr)
  | Upper_case_component (name, component) ->
      let saved_ctx = !React.current_tree_context in
      let rec render replayed =
        React.reset_component_id_state saved_ctx;
        match React.call_with_promise_replay replayed component with
        | Ok element ->
            let did_use_id = React.check_did_render_id_hook () in
            if did_use_id then
              React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
            continue_with_debug_html ~fiber ~name ~debug_info element
        | Error (Any_promise promise, used) ->
            React.current_tree_context := saved_ctx;
            let%lwt _ = promise in
            render used
      in
      Lwt.finalize
        (fun () -> render [])
        (fun () ->
          React.current_tree_context := saved_ctx;
          Lwt.return_unit)
  | Async_component (name, component) -> (
      let saved_ctx = !React.current_tree_context in
      React.reset_component_id_state saved_ctx;
      try%lwt
        let%lwt element = component () in
        let did_use_id = React.check_did_render_id_hook () in
        if did_use_id then React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
        let%lwt result = continue_with_debug_html ~fiber ~name ~debug_info element in
        React.current_tree_context := saved_ctx;
        Lwt.return result
      with exn ->
        React.current_tree_context := saved_ctx;
        raise exn)
  | Client_component { key; import_module; import_name; props; client } ->
      let context = fiber.context in
      let env = fiber.env in
      let props =
        Model.models_to_payload ~debug:fiber.debug ~filter_stack_frame:fiber.filter_stack_frame ~context
          ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) ~env props
      in
      let%lwt html = client_to_html ~fiber client in
      let ref : json = Model.component_ref ~module_:import_module ~name:import_name in
      let index =
        Stream.push_client_ref ~context ~import_module ~import_name
          (model_to_chunk ?nonce:fiber.nonce (Component_ref ref))
      in
      let model = Model.node ~env ~site ~tag:(Model.lazy_value index) ~key ~props [] in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } -> (
      let context = fiber.context in
      let%lwt html_fallback, model_fallback =
        match fallback with
        | None -> Lwt.return (Html.null, None)
        | Some fallback ->
            let%lwt html, model = render_element_to_html ~fiber ~debug_info ~site:Static_slot fallback in
            Lwt.return (html, Some model)
      in
      let tag = Model.symbol_tag ~context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) "react.suspense" in
      let parent = segment_written () in
      let settle, render_children =
        with_segment (fun () -> render_element_to_html ~fiber ~debug_info ~site:Static_slot children)
      in
      try%lwt
        let children = render_children () in
        match Lwt.state children with
        | Sleep ->
            let promise =
              try%lwt
                let%lwt html, model = children in
                let to_chunk index =
                  Html.list
                    [
                      boundary_to_chunk ?nonce:fiber.nonce html index;
                      model_to_chunk ?nonce:fiber.nonce (Value model) index;
                    ]
                in
                Lwt.return to_chunk
              with exn ->
                let error = Model.exn_to_error exn in
                let to_chunk index =
                  Html.list
                    [
                      model_to_chunk ?nonce:fiber.nonce (Error (fiber.env, error)) index;
                      client_render_boundary_to_chunk ?nonce:fiber.nonce ~env:fiber.env
                        ~message:(client_render_error_message exn)
                        ~include_definition:(Stream.take_rx_definition context) index;
                    ]
                in
                Lwt.return to_chunk
            in
            let index, chunk_written = Stream.push_boundary_async ~parent ~context (fun () -> promise) in
            settle (written_with children ~chunk_written);
            Lwt.return
              ( html_suspense_placeholder ~fallback:html_fallback index,
                Model.suspense_placeholder ~env:fiber.env ~site ~tag ~key ~fallback:model_fallback index )
        | Return (html, model) ->
            settle parent;
            let model = Model.suspense_node ~env:fiber.env ~site ~tag ~key ~fallback:model_fallback [ model ] in
            Lwt.return (html_suspense_immediate html, model)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        settle (Lwt.return false);
        let context = fiber.context in
        let error = Model.exn_to_error exn in
        let to_chunk index =
          Html.list
            [
              model_to_chunk ?nonce:fiber.nonce (Error (fiber.env, error)) index;
              boundary_to_chunk ?nonce:fiber.nonce Html.null index;
            ]
        in
        let index, _ = Stream.push_boundary_async ~parent ~context (fun () -> Lwt.return to_chunk) in
        let html = html_suspense_placeholder ~fallback:html_fallback index in
        Lwt.return (html, Model.suspense_placeholder ~env:fiber.env ~site ~tag ~key ~fallback:model_fallback index))
  | Provider { children; push; async_key; async_value } ->
      with_provider_value ~push ~async_key ~async_value (fun () ->
          render_element_to_html ~fiber ~debug_info ~site:Static_slot children)
  | Consumer children -> render_element_to_html ~fiber ~debug_info ~site:Static_slot children
  | Lower_case_element { key; tag; attributes; children } ->
      render_lower_case_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ()

and continue_with_debug_html ~(fiber : Fiber.t) ~name ~debug_info element =
  if not fiber.debug then render_element_to_html ~fiber ~debug_info ~site:Static_slot element
  else
    let context = fiber.context in
    let filter_stack_frame = fiber.filter_stack_frame in
    match debug_info with
    | None ->
        let debug_info_idx, _ =
          Model.emit_debug_info_row ~filter_stack_frame ~context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) ~name
            ~debug_info:None
        in
        Stream.write context
          (model_to_chunk ?nonce:fiber.nonce (Debug_ref (`String (Model.ref_value debug_info_idx))) 0);
        render_element_to_html ~fiber ~debug_info:(Some (debug_info_idx, None)) ~site:Static_slot element
    | Some _ ->
        let model_index = context.index in
        context.index <- context.index + 1;
        let debug_info_idx, owner_idx =
          Model.emit_debug_info_row ~filter_stack_frame ~context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) ~name
            ~debug_info
        in
        let%lwt html, child_model =
          render_element_to_html ~fiber ~debug_info:(Some (debug_info_idx, owner_idx)) ~site:Static_slot element
        in
        Stream.write context
          (model_to_chunk ?nonce:fiber.nonce (Debug_ref (`String (Model.ref_value debug_info_idx))) model_index);
        Stream.write context (model_to_chunk ?nonce:fiber.nonce (Value child_model) model_index);
        Lwt.return (html, `String (Model.ref_value model_index))

and render_lower_case_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children () =
  let inner_html = ReactDOM.getDangerouslyInnerHtml attributes in
  (match Fiber.root_tag ~fiber with Some _ -> () | None -> Fiber.set_root_tag ~fiber tag);
  match classify_element ~fiber ~tag ~attributes with
  | Regular -> render_regular_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html ()
  | Html_root ->
      Fiber.set_html_attributes ~fiber (ReactDOM.attributes_to_html attributes);
      let%lwt html, model =
        render_regular_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html ()
      in
      let html_children = match html with Html.Node { children; _ } -> Html.list children | _ -> html in
      Lwt.return (html_children, model)
  | Head_section ->
      fiber.inside_head <- true;
      let%lwt value =
        handle_hoistable_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html
          ~on_push:Fiber.push_head_element ()
      in
      fiber.inside_head <- false;
      Lwt.return value
  | Body_section ->
      fiber.inside_body <- true;
      let%lwt value = render_regular_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html () in
      fiber.inside_body <- false;
      Lwt.return value
  | Hoistable_resource ->
      handle_hoistable_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html
        ~on_push:Fiber.push_resource ()
  | Hoistable_meta ->
      handle_hoistable_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html
        ~on_push:Fiber.push_extra_head_child ()

and handle_hoistable_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html ~on_push () =
  fiber.hoisted_count <- fiber.hoisted_count + 1;
  let props = Model.props_to_json ~context:fiber.context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) attributes in
  let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
  let create_model children =
    match (Html.is_self_closing_tag tag, inner_html) with
    | _, Some _ | true, _ -> Model.node ~env:fiber.env ~site ~tag ~key ~props ~owner []
    | false, None ->
        let children = match children with `List l -> l | other -> [ other ] in
        Model.node ~env:fiber.env ~site ~tag ~key ~props ~owner children
  in
  let create_html_node ~html_props ~children_html =
    match inner_html with
    | Some inner_html -> Html.{ tag; attributes = html_props; children = [ Html.raw inner_html ] }
    | None -> Html.{ tag; attributes = html_props; children = [ children_html ] }
  in

  let html_props = ReactDOM.attributes_to_html attributes in
  let%lwt children_html, children_model = elements_to_html ~fiber ~debug_info ~site:Static_slot children in
  let html = create_html_node ~html_props ~children_html in
  if fiber.shell_flushed then Lwt.return (Html.Node html, create_model children_model)
  else (
    on_push ~fiber html;
    Lwt.return (Html.null, create_model children_model))

and render_regular_element ~fiber ~debug_info ~site ~key ~tag ~attributes ~children ~inner_html () =
  let html_props, action_input = host_attributes_to_html ~tag attributes in
  let json_props =
    Model.props_to_json ~context:fiber.context ~to_chunk:(model_to_chunk ?nonce:fiber.nonce) attributes
  in
  let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
  match (Html.is_self_closing_tag tag, inner_html) with
  | true, _ ->
      Lwt.return (Html.node tag html_props [], Model.node ~env:fiber.env ~site ~tag ~key ~props:json_props ~owner [])
  | false, Some inner_html ->
      Lwt.return
        ( Html.node tag html_props (action_input @ [ Html.raw inner_html ]),
          Model.node ~env:fiber.env ~site ~tag ~key ~props:json_props ~owner [] )
  | false, None ->
      let%lwt html, model = elements_to_html ~fiber ~debug_info ~site:Static_slot children in
      let model_children = match model with `List l -> l | other -> [ other ] in
      Lwt.return
        ( Html.node tag html_props (action_input @ [ html ]),
          Model.node ~env:fiber.env ~site ~tag ~key ~props:json_props ~owner model_children )

and elements_to_html ~fiber ~debug_info ~(site : Key_validation.site) elements =
  let%lwt html_and_models =
    map_children_with_tree_context_lwt (render_element_to_html ~fiber ~debug_info ~site) elements
  in
  let rec split_rev acc_a acc_b = function
    | [] -> (List.rev acc_a, List.rev acc_b)
    | (a, b) :: rest -> split_rev (a :: acc_a) (b :: acc_b) rest
  in
  let htmls, model = split_rev [] [] html_and_models in
  let html = match htmls with [ one ] -> one | many -> Html.list many in
  Lwt.return (html, `List model)

let is_body_node element = match (element : Html.element) with Html.Node { tag = "body"; _ } -> true | _ -> false

let push_children_into ~children:new_children html =
  let open Html in
  match html with
  | Node { tag; children; attributes } -> Node { tag; attributes; children = children @ new_children }
  | _ -> html

let get_html_attr key (attrs : Html.attribute_list) =
  List.find_map (function `Value (k, v) when String.equal k key -> Some v | _ -> None) attrs

let has_html_attr key (attrs : Html.attribute_list) =
  List.exists
    (function
      | `Value (k, _) when String.equal k key -> true | `Present k' when String.equal k' key -> true | _ -> false)
    attrs

type head_bucket = Charset | Viewport | Stylesheet_resource | Async_script | Other

let classify_head_element (element : Html.element) =
  match element with
  | Html.Node { tag = "meta"; attributes; _ } -> (
      if has_html_attr "charset" attributes then Charset
      else match get_html_attr "name" attributes with Some "viewport" -> Viewport | _ -> Other)
  | Html.Node { tag = "link"; attributes; _ } ->
      if has_html_attr "precedence" attributes then
        match get_html_attr "rel" attributes with Some "stylesheet" -> Stylesheet_resource | _ -> Other
      else Other
  | Html.Node { tag = "style"; attributes; _ } ->
      if has_html_attr "href" attributes && has_html_attr "precedence" attributes then Stylesheet_resource else Other
  | Html.Node { tag = "script"; attributes; _ } ->
      if has_html_attr "async" attributes && has_html_attr "src" attributes then Async_script else Other
  | _ -> Other

let sort_head_children children =
  let charset = ref [] in
  let viewport = ref [] in
  let stylesheets = ref [] in
  let scripts = ref [] in
  let other = ref [] in
  let push_resource bucket ~key_attr el =
    let key_of = function Html.Node { attributes; _ } -> get_html_attr key_attr attributes | _ -> None in
    let key = key_of el in
    if Option.is_none key || not (List.exists (fun e -> key_of e = key) !bucket) then bucket := el :: !bucket
  in
  let rec distribute = function
    | [] -> ()
    | Html.Null :: rest -> distribute rest
    | Html.List (_, nested) :: rest ->
        distribute nested;
        distribute rest
    | el :: rest ->
        (match classify_head_element el with
        | Charset -> charset := el :: !charset
        | Viewport -> viewport := el :: !viewport
        | Stylesheet_resource -> push_resource stylesheets ~key_attr:"href" el
        | Async_script -> push_resource scripts ~key_attr:"src" el
        | Other -> other := el :: !other);
        distribute rest
  in
  distribute children;
  let acc = List.rev !other in
  let acc = List.rev_append !scripts acc in
  let acc = List.rev_append !stylesheets acc in
  let acc = List.rev_append !viewport acc in
  List.rev_append !charset acc

let reconstruct_document ~(fiber : Fiber.t) ~root_html ~user_scripts ~skip_root =
  let root_element_is_html_tag = match Fiber.root_tag ~fiber with Some tag -> tag = "html" | None -> false in
  let all_head_content = List.rev_append fiber.resources (List.rev fiber.extra_head_children) in
  if root_element_is_html_tag then
    let body =
      match (is_body_node root_html, skip_root) with
      | true, false -> push_children_into ~children:user_scripts root_html
      | true, true | false, true -> Html.list user_scripts
      | false, false -> Html.list (root_html :: user_scripts)
    in
    match fiber.head_element with
    | Some node ->
        let combined = sort_head_children (all_head_content @ node.children) in
        let head = Html.Node { node with children = combined } in
        Html.node "html" fiber.html_attributes [ head; body ]
    | None ->
        let sorted = sort_head_children all_head_content in
        Html.node "html" fiber.html_attributes [ Html.node "head" [] sorted; body ]
  else
    let hoisted =
      match fiber.head_element with
      | Some node -> [ Html.Node { node with children = sort_head_children (all_head_content @ node.children) } ]
      | None -> sort_head_children all_head_content
    in
    let rest = if skip_root then user_scripts else root_html :: user_scripts in
    Html.list (hoisted @ rest)

let default_progressive_chunk_size = 12800

let create_preload_link href =
  Html.Node
    {
      tag = "link";
      attributes =
        [ Html.attribute "rel" "modulepreload"; Html.attribute "fetchPriority" "low"; Html.attribute "href" href ];
      children = [];
    }

let create_initial_resources ~bootstrap_scripts ~bootstrap_modules =
  match bootstrap_scripts with
  | Some scripts -> List.map create_preload_link scripts
  | None -> ( match bootstrap_modules with Some modules -> List.map create_preload_link modules | None -> [])

let create_user_scripts ~root_data_payload ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules ?nonce () =
  let bootstrap_script_content =
    match bootstrapScriptContent with
    | None -> Html.null
    | Some content -> script ?nonce [] [ Html.raw (Html.escape_entire_inline_script content) ]
  in
  let bootstrap_scripts_nodes =
    match bootstrapScripts with
    | None -> Html.null
    | Some scripts ->
        scripts
        |> List.map (fun src -> script ?nonce [ Html.attribute "src" src; Html.attribute "async" "" ] [])
        |> Html.list
  in
  let bootstrap_modules_nodes =
    match bootstrapModules with
    | None -> Html.null
    | Some modules ->
        modules
        |> List.map (fun src ->
            script ?nonce [ Html.attribute "src" src; Html.attribute "async" ""; Html.attribute "type" "module" ] [])
        |> Html.list
  in
  [
    rc_function_script ?nonce ();
    rsc_start_script ?nonce ();
    root_data_payload;
    bootstrap_script_content;
    bootstrap_scripts_nodes;
    bootstrap_modules_nodes;
  ]

let render_html ?(skipRoot = false) ?(env = `Prod) ?(debug = false) ?(filter_stack_frame = default_filter_stack_frame)
    ?timeout ?abort ?(progressive_chunk_size = default_progressive_chunk_size) ?bootstrapScriptContent ?bootstrapScripts
    ?bootstrapModules ?nonce ?identifier_prefix element =
  React.reset_id_rendering ?prefix:identifier_prefix ();
  React.Cache.with_request_cache_async (fun () ->
      let progressive_chunk_size = max 1 progressive_chunk_size in
      let initial_resources =
        create_initial_resources ~bootstrap_scripts:bootstrapScripts ~bootstrap_modules:bootstrapModules
      in
      let stream, context = Stream.make ~initial_index:1 ~root_pending:true () in
      let hint_sink { Flight_hints.dedup_key; code; payload } =
        Stream.push_hint ~context ~dedup_key (hint_row_to_html_chunk ?nonce code payload)
      in
      Flight_hints.with_sink hint_sink @@ fun () ->
      let fiber : Fiber.t =
        {
          context;
          env;
          nonce;
          debug;
          filter_stack_frame;
          head_element = None;
          extra_head_children = [];
          html_attributes = [];
          resources = List.rev initial_resources;
          root_tag = None;
          inside_head = false;
          inside_body = false;
          hoisted_count = 0;
          shell_flushed = false;
        }
      in
      let%lwt root_html, root_model = render_element_to_html ~fiber ~debug_info:None ~site:Value element in
      let root_data_payload = model_to_chunk ?nonce (Value root_model) 0 in
      Stream.flush_deferred ~context;
      context.root_pending <- false;
      (match context.active_tasks with [] -> Stream.close context | _ :: _ -> ());
      let user_scripts =
        create_user_scripts ~root_data_payload ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules ?nonce ()
      in
      let html = reconstruct_document ~fiber ~root_html ~user_scripts ~skip_root:skipRoot in
      fiber.shell_flushed <- true;
      let subscribe fn =
        let buf = Buffer.create progressive_chunk_size in
        let flush () =
          let contents = Buffer.contents buf in
          Buffer.clear buf;
          fn contents
        in
        let buffered v =
          Buffer.add_string buf (Html.to_string v);
          if Buffer.length buf >= progressive_chunk_size then flush () else Lwt.return ()
        in
        let finished = ref false in
        let finish () =
          if !finished then Lwt.return ()
          else begin
            finished := true;
            Buffer.add_string buf (Html.to_string (chunk_stream_end_script ?nonce ()));
            flush ()
          end
        in
        let subscription =
          let%lwt () = Push_stream.subscribe ~fn:buffered stream in
          finish ()
        in
        match Model.abort_triggers ~timeout ~abort with
        | [] -> subscription
        | triggers ->
            Lwt.pick
              [
                subscription;
                (let%lwt reason = Lwt.pick triggers in
                 match Stream.begin_abort context with
                 | None -> fst (Lwt.task ())
                 | Some tasks ->
                     let pending_boundaries = Stream.boundary_rows tasks in
                     let pending_rows = Stream.task_rows tasks in
                     let error = abort_error reason in
                     let message = client_render_abort_message reason in
                     List.iter
                       (fun index ->
                         Buffer.add_string buf (Html.to_string (model_to_chunk ?nonce (Error (env, error)) index)))
                       pending_rows;
                     List.iter
                       (fun index ->
                         Buffer.add_string buf
                           (Html.to_string
                              (client_render_boundary_to_chunk ?nonce ~env ~message
                                 ~include_definition:(Stream.take_rx_definition context) index)))
                       pending_boundaries;
                     Stream.close_and_cancel context tasks;
                     finish ());
              ]
      in
      Lwt.return (Html.to_string html, subscribe))

let render_model_value ?(env = `Prod) ?(debug = false) ?filter_stack_frame ?subscribe ?timeout ?abort model =
  React.Cache.with_request_cache_async (fun () ->
      Model.render ~env ~debug ?filter_stack_frame ?subscribe ?timeout ?abort model)

let render_model ?(env = `Prod) ?(debug = false) ?filter_stack_frame ?subscribe ?timeout ?abort model =
  render_model_value ~env ~debug ?filter_stack_frame ?subscribe ?timeout ?abort (React.Model.Element model)

let create_action_response ?env ?debug ?filter_stack_frame ?subscribe ?timeout ?abort response =
  React.Cache.with_request_cache_async (fun () ->
      Model.create_action_response ?env ?debug ?filter_stack_frame ?subscribe ?timeout ?abort response)

let hex_to_formdata_key hex_id = Option.map string_of_int (int_of_string_opt ("0x" ^ hex_id))

let resolve_from_formdata formData hex_id =
  match hex_to_formdata_key hex_id with
  | Some key -> (
      try
        let (`String json_str) = Js.FormData.get formData key in
        match Yojson.Basic.from_string json_str with
        | json -> Ok json
        | exception Yojson.Json_error msg ->
            Error (Printf.sprintf "decodeReply: invalid JSON in outlined entry %s: %s" key msg)
      with Not_found -> Ok `Null)
  | None -> Ok `Null

let resolve_raw_from_formdata formData hex_id =
  match hex_to_formdata_key hex_id with
  | Some key -> (
      try
        let (`String data) = Js.FormData.get formData key in
        Ok (`String data)
      with Not_found -> Error (Printf.sprintf "decodeReply: Blob ($B) entry not found in FormData for key %s" key))
  | None -> Error (Printf.sprintf "decodeReply: Blob ($B) invalid hex ID: %s" hex_id)

let unsupported name = Error (Printf.sprintf "decodeReply: %s is not supported" name)
let ( let* ) = Result.bind

let map_result f list =
  let rec aux acc = function
    | [] -> Ok (List.rev acc)
    | x :: rest ->
        let* v = f x in
        aux (v :: acc) rest
  in
  aux [] list

type decode_ctx = {
  formData : Js.FormData.t option;
  temporaryReferences : (string -> json option) option;
  resolving : string list;
  decoded : (string, json) Hashtbl.t;
}

let resolve_temporary_reference ctx id =
  match ctx.temporaryReferences with
  | Some lookup -> (
      match lookup id with
      | Some resolved -> Ok resolved
      | None ->
          let message =
            Printf.sprintf "decodeReply: Temporary Reference $T%s not found in the provided temporaryReferences map" id
          in
          Error message)
  | None -> Error "decodeReply: Temporary Reference ($T) requires a temporaryReferences resolver"

let rec decode_value (ctx : decode_ctx) (json : json) : (json, string) result =
  match json with
  | `String value when String.length value >= 2 && String.get value 0 = '$' -> decode_prefixed_value ctx value
  | `List items -> decode_list ctx items
  | `Assoc pairs -> decode_assoc ctx pairs
  | other -> Ok other

and decode_prefixed_value ctx value =
  let len = String.length value in
  let payload = String.sub value 2 (len - 2) in
  match String.get value 1 with
  | '$' -> Ok (`String (String.sub value 1 (len - 1)))
  | 'u' -> Ok `Null
  | 'K' -> Ok `Null
  | 'D' -> Ok (`String payload)
  | 'n' -> Ok (`String payload)
  | 'N' -> Ok (`Float Float.nan)
  | 'I' -> Ok (`Float Float.infinity)
  | '-' -> Ok (if String.equal value "$-0" then `Float (-0.) else `Float Float.neg_infinity)
  | 'Q' -> decode_outlined_map ctx payload
  | 'W' -> resolve_outlined ctx "Set ($W)" payload
  | 'i' -> resolve_outlined ctx "Iterator ($i)" payload
  | 'F' -> resolve_outlined ctx "Server Reference ($F)" payload
  | 'T' -> resolve_temporary_reference ctx payload
  | '@' -> unsupported "Promise ($@)"
  | ('A' | 'O' | 'o' | 'U' | 'S' | 's' | 'L' | 'l' | 'G' | 'g' | 'M' | 'm' | 'V') as prefix ->
      unsupported (Printf.sprintf "TypedArray/ArrayBuffer ($%c)" prefix)
  | 'B' -> (
      match ctx.formData with
      | Some formData -> resolve_raw_from_formdata formData payload
      | None -> Error "decodeReply: Blob ($B) requires FormData for resolution")
  | 'R' -> unsupported "ReadableStream ($R)"
  | 'r' -> unsupported "ReadableStream bytes ($r)"
  | 'X' -> unsupported "AsyncIterable ($X)"
  | 'x' -> unsupported "AsyncIterator ($x)"
  | _ -> (
      match ctx.formData with
      | Some formData -> resolve_and_decode_outlined ctx formData (String.sub value 1 (len - 1))
      | None -> Ok `Null)

and decode_list ctx items =
  let* items = map_result (decode_value ctx) items in
  Ok (`List items)

and decode_assoc ctx pairs =
  let* pairs =
    map_result
      (fun (key, value) ->
        let* value = decode_value ctx value in
        Ok (key, value))
      pairs
  in
  Ok (`Assoc pairs)

and resolve_and_decode_outlined ctx fd hex_id =
  let entry_key = Option.value (hex_to_formdata_key hex_id) ~default:hex_id in
  if List.mem entry_key ctx.resolving then
    Error (Printf.sprintf "decodeReply: cyclic reference to outlined entry %s" entry_key)
  else
    match Hashtbl.find_opt ctx.decoded entry_key with
    | Some decoded -> Ok decoded
    | None ->
        let* resolved = resolve_from_formdata fd hex_id in
        let* decoded = decode_value { ctx with resolving = entry_key :: ctx.resolving } resolved in
        Hashtbl.replace ctx.decoded entry_key decoded;
        Ok decoded

and resolve_outlined ctx type_name hex_id =
  match ctx.formData with
  | None -> Error (Printf.sprintf "decodeReply: %s requires FormData for outlined model resolution" type_name)
  | Some fd -> resolve_and_decode_outlined ctx fd hex_id

and decode_outlined_map ctx hex_id =
  match resolve_outlined ctx "Map ($Q)" hex_id with
  | Error _ as err -> err
  | Ok resolved -> (
      match resolved with
      | `List pairs ->
          let all_string_keys, assoc_pairs =
            List.fold_left
              (fun (all_ok, acc) pair ->
                match pair with `List [ `String k; v ] -> (all_ok, (k, v) :: acc) | _ -> (false, acc))
              (true, []) pairs
          in
          Ok (if all_string_keys then `Assoc (List.rev assoc_pairs) else resolved)
      | other -> Ok other)

let protect_reply_decode decode = try decode () with Stack_overflow -> Error "decodeReply: payload nesting too deep"

let parse_reply_arguments ~invalid_json input =
  match Yojson.Basic.from_string input with
  | `List arguments -> Ok arguments
  | _ -> Error "Invalid args, this request was not created by server-reason-react"
  | exception Yojson.Json_error message -> Error (Printf.sprintf "%s: %s" invalid_json message)

let decode_arguments ctx arguments =
  let* arguments = map_result (decode_value ctx) arguments in
  Ok (Array.of_list arguments)

let decodeReply ?temporaryReferences body =
  protect_reply_decode (fun () ->
      let context = { formData = None; temporaryReferences; resolving = []; decoded = Hashtbl.create 0 } in
      let* arguments = parse_reply_arguments ~invalid_json:"Invalid JSON" body in
      decode_arguments context arguments)

let form_data_field_prefix = function
  | `String value when String.length value > 2 && String.get value 0 = '$' && String.get value 1 = 'K' ->
      Some (String.sub value 2 (String.length value - 2) ^ "_")
  | _ -> None

let read_form_data_reply formData =
  let* model =
    try
      let (`String model) = Js.FormData.get formData "0" in
      Ok model
    with Not_found -> Error "decodeReply: FormData is missing the root entry at key \"0\""
  in
  let* items = parse_reply_arguments ~invalid_json:"Invalid JSON in FormData root" model in
  let arguments, prefix =
    List.fold_left
      (fun (arguments, prefix) item ->
        match form_data_field_prefix item with
        | Some prefix -> (arguments, Some prefix)
        | None -> (item :: arguments, prefix))
      ([], None) items
  in
  Ok (List.rev arguments, prefix)

let extract_user_form_data formData ~prefix =
  let field_name key =
    match prefix with
    | None -> Some key
    | Some prefix ->
        let len = String.length prefix in
        if String.starts_with ~prefix key then Some (String.sub key len (String.length key - len)) else None
  in
  let user_fd = Js.FormData.make () in
  List.iter
    (fun (key, value) ->
      if not (String.equal key "0") then
        Option.iter (fun name -> Js.FormData.append user_fd name value) (field_name key))
    (Js.FormData.entries formData);
  user_fd

let decodeFormDataReply ?temporaryReferences formData =
  protect_reply_decode (fun () ->
      let context = { formData = Some formData; temporaryReferences; resolving = []; decoded = Hashtbl.create 8 } in
      let* arguments, prefix = read_form_data_reply formData in
      let* arguments = decode_arguments context arguments in
      Ok (arguments, extract_user_form_data formData ~prefix))

let action_prefix = "$ACTION_"

let decodeAction formData =
  let action_id = ref None in
  let user_fd = Js.FormData.make () in
  let action_id_prefix_len = String.length action_id_prefix in
  Js.FormData.entries formData
  |> List.iter (fun (key, value) ->
      if String.starts_with ~prefix:action_id_prefix key then
        action_id := Some (String.sub key action_id_prefix_len (String.length key - action_id_prefix_len))
      else if not (String.starts_with ~prefix:action_prefix key) then Js.FormData.append user_fd key value);
  match !action_id with None -> None | Some id -> Some (id, user_fd)

type server_function =
  | FormData of (Yojson.Basic.t array -> Js.FormData.t -> React.model_value Lwt.t)
  | Body of (Yojson.Basic.t array -> React.model_value Lwt.t)

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end
