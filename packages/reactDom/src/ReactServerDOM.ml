type json = Yojson.Basic.t
type env = [ `Dev | `Prod ]

let is_dev = function `Dev -> true | `Prod -> false

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

(* Identity-only key over values of any type, mirroring React's written*
   maps (keyed on JS object identity): promises for writtenObjects, server
   function records for writtenServerReferences. Both hide their payload type
   (GADT / polymorphic record), so two occurrences can't be compared with
   ( == ) at their original type. [Obj.repr] is used purely to erase the type
   for a physical-identity comparison: the representation is never inspected
   or reinterpreted (no [Obj.magic]), and ( == ) on [Obj.t] compares identity
   exactly like ( == ) at the original type, which makes this sound. The
   abstract signature keeps the [Obj.t] from leaking. Both key kinds are
   always heap blocks, so identity is well-defined (no unboxed float
   pitfalls). *)
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
  type 'a t = {
    push : 'a -> unit;
    (* Import (I) rows bypass the pending-hints drain: React flushes
       completedImportChunks before completedHintChunks, so an import row
       encountered after a hint call still streams before the hint. *)
    push_import : 'a -> unit;
    close : unit -> unit;
    mutable closed : bool;
    (* Whether the $RX function definition was already streamed: it is injected once per stream, with whichever
       client-render instruction (errored Suspense boundary or timeout) streams first. *)
    mutable rx_injected : bool;
    mutable index : int;
    mutable pending : int;
    (* Async rows still rendering, in registration order (most recent first). On an abort/timeout every entry gets
       an error row rejecting its client-side reference, and [`Boundary] entries (Suspense content whose B:<id>
       placeholder already flushed) additionally get a $RX client-render instruction. *)
    mutable pending_rows : (int * [ `Boundary | `Model_row ]) list;
    written_client_references : (string * string, int) Hashtbl.t;
    written_symbols : (string, string) Hashtbl.t;
    (* React's request.hints set: one H row per dedup key per request. *)
    written_hints : (string, unit) Hashtbl.t;
    (* Hint rows buffered until the next regular row write, emulating React's
       flush order within a cycle: imports, hints, regular rows, errors. Hint
       rows are id-less (":H<code><json>") and never consume a row id. *)
    pending_hints : 'a Queue.t;
    (* React's writtenObjects for thenables: the same promise serialized twice
       in one stream resolves to the same "$@<id>" reference and a single
       resolution row. Keyed on the promise's PHYSICAL identity (an assoc list
       rather than a Hashtbl: structural hashing of a promise would traverse
       mutable state and change as it resolves; streams see few promises, so a
       linear scan is fine). *)
    mutable written_promises : (Physical_key.t * int) list;
    (* React's writtenServerReferences: the same server function serialized twice reuses one row. *)
    mutable written_server_references : (Physical_key.t * int) list;
    (* Rows produced synchronously while another row is being serialized but
       that React only writes after it: error chunks (completedErrorChunks)
       and retries of already-resolved thenables (pingedTasks) both flush
       after the regular model chunks of the same flush cycle. Stored in
       reverse order of deferral. *)
    mutable deferred_rows : (unit -> unit) list;
  }

  (* Closing is idempotent and pushes are guarded on [closed]: async work that completes after an abort/timeout must
     not push into (or re-close) the closed stream, which would raise Lwt_stream.Closed inside Lwt.async and crash the
     process. *)
  let close context =
    if not context.closed then (
      context.closed <- true;
      context.close ())

  (* Returns whether the caller must inline the $RX function definition before its $RX call, flipping the
     once-per-stream flag. *)
  let take_rx_definition context =
    if context.rx_injected then false
    else (
      context.rx_injected <- true;
      true)

  let push to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    if not context.closed then context.push (to_chunk index);
    index

  (* Mirror React's flush ordering: the row id is allocated at encounter time
     (React does request.nextChunkId++ eagerly) but the chunk itself is
     written only after the row currently being serialized. [to_chunk index]
     is evaluated at flush time, so deferred serialization (e.g. an
     already-resolved promise's model, which React renders in a later
     retryTask) allocates any nested row ids after the enclosing row's. *)
  let push_deferred to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    context.deferred_rows <- (fun () -> context.push (to_chunk index)) :: context.deferred_rows;
    index

  (* Runs after every task row (the root row and every async row): writes the
     rows deferred during that row's serialization. Deferred work can defer
     further rows (e.g. a resolved promise whose model errors), hence the
     loop. *)
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
        context.push_import (to_chunk index);
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

  (* Well-known symbols (e.g. react.suspense) are outlined once per stream and referenced by row id. Stores the formatted "$<hex>" reference so repeated boundaries allocate nothing. *)
  let push_symbol ~context ~symbol ~reference_of_index make_chunk =
    match Hashtbl.find_opt context.written_symbols symbol with
    | Some reference -> reference
    | None ->
        let index = push (make_chunk ()) ~context in
        let reference = reference_of_index index in
        Hashtbl.replace context.written_symbols symbol reference;
        reference

  (* An asynchronous task row: the id is allocated BEFORE [make_chunk] runs so rows pushed while the task's payload is serialized get later ids. The row is written when the promise resolves — unless the stream was aborted/closed in the meantime, in which case the chunk is dropped. *)
  let push_task ~kind make_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    context.pending <- context.pending + 1;
    context.pending_rows <- (index, kind) :: context.pending_rows;
    Lwt.async (fun () ->
        let%lwt to_chunk = make_chunk () in
        context.pending <- context.pending - 1;
        context.pending_rows <- List.filter (fun (i, _) -> i <> index) context.pending_rows;
        if not context.closed then (
          context.push (to_chunk index);
          (* Rows deferred during this row's serialization flush right after it, and may register new pending work, so flush before the close check. *)
          flush_deferred ~context;
          if context.pending = 0 then close context);
        Lwt.return ());
    index

  (* An async row of the RSC payload (a lazy element, a promise passed as prop, or the root task) with no placeholder in the flushed HTML. Tracked in [pending_rows] so an abort/timeout can reject its client-side reference with an error row. *)
  let push_async make_chunk ~context = push_task ~kind:`Model_row make_chunk ~context

  (* The async HTML content of a Suspense boundary whose placeholder (<template id="B:n">) and fallback were already flushed. Tracked in [pending_rows] so an abort/timeout can emit a $RX client-render instruction for it. *)
  let push_boundary_async make_chunk ~context = push_task ~kind:`Boundary make_chunk ~context

  let make ?(initial_index = 0) ?(pending = 0) () =
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
        closed = false;
        rx_injected = false;
        pending;
        index = initial_index;
        pending_rows = [];
        written_client_references = Hashtbl.create 16;
        written_symbols = Hashtbl.create 4;
        written_hints = Hashtbl.create 8;
        pending_hints;
        written_promises = [];
        written_server_references = [];
        deferred_rows = [];
      } )
end

(* Resources module maintains insertion order while deduplicating based on src/href *)
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
        (* Ensure if this resource already exists, it gets deduplicated *)
        let exists = List.exists (function Html.Node node -> resource_key node = Some key | _ -> false) resources in
        if exists then resources else Html.Node resource :: resources
end

module Fiber = struct
  type t = {
    context : Html.element Stream.t;
    env : env;
    (* Whether to emit debug-info rows (name/owner/stack) for components into the inlined RSC payload *)
    debug : bool;
    filter_stack_frame : string -> string -> bool;
    (* root_tag stores the tag of the first lower case element visited, useful to know if the root element is an html tag *)
    mutable root_tag : string option;
    (* head_element stores the <head> element's attributes and direct children *)
    mutable head_element : Html.node option;
    (* extra_head_children collects elements that should be in the document's <head> (title, meta, link, style) even if they weren't originally inside a <head> element *)
    mutable extra_head_children : Html.element list;
    (* resources collects link, script that should preload, prefetch to be in the document's <head> and deduplicates them based on "src" or "href" attributes, respectively *)
    mutable resources : Html.element list;
    (* inside_head tracks whether we're currently processing elements inside a <head> element *)
    mutable inside_head : bool;
    (* inside_body tracks whether we're currently processing elements inside a <body> element *)
    mutable inside_body : bool;
    (* Monotonic count of hoistable elements encountered (before dedup). Lets the Static/Writer branches detect that a prerendered subtree contained hoistables, whose raw HTML would otherwise render them a second time at their original position. *)
    mutable hoisted_count : int;
    (* html_attributes collects the attributes of the <html> tag for document reconstruction *)
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

(* Map children with tree context forking (sync). Works with any return type. *)
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

module Model = struct
  type chunk = Value of json | Debug_ref of json | Component_ref of json | Error of env * React.error

  let make_error_json ~env ~message ~stack ~digest : json =
    match is_dev env with
    | true ->
        `Assoc [ ("message", `String message); ("stack", stack); ("env", `String "Server"); ("digest", `String digest) ]
    (*
      In prod we don't emit any information about this Error object to avoid
      unintentional leaks. Use the digest to identify the registered error.
      REF: https://github.com/facebook/react/blob/e81fcfe3f201a8f626e892fb52ccbd0edba627cb/packages/react-client/src/ReactFlightClient.js#L2086-L2101
    *)
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

  (* User strings starting with '$' are escaped with an extra '$' mirrors escapeStringValue in React's ReactFlightServer.js *)
  let escape_string_value value =
    if String.length value > 0 && String.unsafe_get value 0 = '$' then "$" ^ value else value

  (* JSON.stringify prints integral floats without a decimal part (2.0 -> 2) while Yojson prints `Float 2.0 as "2.0", so integral floats are emitted as ints. *)
  (* 2^53: the largest range where every integer is exactly representable (ocamlopt does not fold [2. ** 53.]) *)
  let max_safe_integer = 9007199254740992.

  (* JSON values can't represent cross the wire as React's special strings
     ($NaN, $Infinity, $-Infinity, $-0); integral floats within the exact
     range collapse to ints; everything else is printed by [write_json]
     below the way JavaScript stringifies numbers. *)
  let float_to_json value : json =
    if Float.is_nan value then `String "$NaN"
    else if value = Float.infinity then `String "$Infinity"
    else if value = Float.neg_infinity then `String "$-Infinity"
    else if value = 0. && Float.sign_bit value then `String "$-0"
    else if Float.is_integer value && Float.abs value <= max_safe_integer then `Int (Float.to_int value)
    else `Float value

  (* Yojson prints floats with OCaml's %h-derived formats ("9e+18"); JavaScript
     prints integral doubles in full digits up to 1e21 ("9000000000000000000").
     Rows must match JSON.stringify, so floats go through the JS number
     printer; everything else delegates to Yojson. *)
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

  (* Normalize a user-provided JSON model: escape every string value (not object keys) and print numbers the way JavaScript stringifies them. *)
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

  (* Outlines a server function as its own {"id","bound"} row (deduplicated on physical identity, mirroring React's writtenServerReferences) and returns the "$F<hexid>" reference. *)
  let outline_server_function ~context ~to_chunk fn =
    let index =
      Stream.push_server_reference ~context ~key:(Physical_key.make fn) (to_chunk (Value (action_to_json fn)))
    in
    action_value index

  let prop_to_json (prop : React.JSX.prop) =
    match prop with
    (* We ignore the HTML name, and only use the JSX name *)
    | Bool (_, key, value) -> Some (key, `Bool value)
    (* Booleanish props are stringified in HTML attributes only; the Flight payload keeps the raw JSON boolean. *)
    | BooleanishString (_, key, value) -> Some (key, `Bool value)
    (* We exclude 'key' from props, since it's outside of the props object *)
    | String (_, key, _) when key = "key" -> None
    | String (_, key, value) -> Some (key, `String (escape_string_value value))
    | Int (_, key, value) -> Some (key, `Int value)
    | Float (_, key, value) -> Some (key, float_to_json value)
    | Style value -> Some ("style", style_to_json value)
    | DangerouslyInnerHtml html ->
        Some ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String (escape_string_value html)) ])
    | Ref _ -> None
    | Event _ -> None
    | Action _ -> None

  let props_to_json props = List.filter_map prop_to_json props
  let chunk_ref_or_null = function None -> `Null | Some idx -> `String (ref_value idx)

  (* React element tuple. In prod it's a 4-tuple ["$", type, key, props]; in dev it appends the debug fields [debugOwner, debugStack, validated]. *)
  let node ~env ~tag ?(key = None) ~props ?(owner = None) children : json =
    let key = match key with None -> `Null | Some key -> `String key in
    let props =
      match children with
      | [] -> props
      | [ one_children ] -> ("children", one_children) :: props
      | childrens -> ("children", `List childrens) :: props
    in
    match env with
    | `Prod -> `List [ `String "$"; `String tag; key; `Assoc props ]
    | `Dev -> `List [ `String "$"; `String tag; key; `Assoc props; chunk_ref_or_null owner; `Null; `Int 1 ]

  (* React outlines the suspense symbol once per stream as its own row
     (e.g. 1:"$Sreact.suspense", pushed before any row that references it,
     deduplicated via written_symbols) and uses the row reference ("$1") as
     the element type. [suspense_tag] pushes the row on first use and returns
     that reference. *)
  let suspense_tag ~context ~to_chunk =
    Stream.push_symbol ~context ~symbol:"react.suspense" ~reference_of_index:ref_value (fun () ->
        to_chunk (Value (`String "$Sreact.suspense")))

  (* Not using `node` because we need to add fallback prop as json directly.
     React serializes suspense props as {children, fallback}: children first.
     When the fallback prop is absent from the JSX, React omits the key from
     the props object entirely (an explicit fallback={null} serializes as
     "fallback":null and arrives here as [Some `Null]). *)
  let suspense_node ~env ~tag ~key ~fallback children : json =
    let fallback_prop = match fallback with None -> [] | Some fallback -> [ ("fallback", fallback) ] in
    let props =
      match children with
      | [] -> fallback_prop
      | [ one ] -> ("children", one) :: fallback_prop
      | _ -> ("children", `List children) :: fallback_prop
    in
    node ~env ~tag ~key ~props []

  let suspense_placeholder ~env ~tag ~key ~fallback index =
    suspense_node ~env ~tag ~key ~fallback [ `String (lazy_value index) ]

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

  (* Hint rows are id-less; the payload is plain JSON.stringify output, never $-escaped (React's emitHint stringifies outside the flight serializer). *)
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
      ~to_chunk ~env element =
    (* ~debug_info carries the (debug row id, owner row id) attached by the
       closest component above, so nested rows can reference their owner. [None]
       means no component has attached debug rows yet (the root row, id 0, owns
       the next one). *)
    let emit_debug_info ~name ~debug_info =
      emit_debug_info_row ~filter_stack_frame ~context ~to_chunk ~name ~debug_info
    in
    let outline_with_debug_ref ~name ~debug_info ~render_child =
      let model_index = context.index in
      context.index <- context.index + 1;
      let debug_info_idx, owner_idx = emit_debug_info ~name ~debug_info in
      let new_debug_info = Some (debug_info_idx, owner_idx) in
      let child_payload = render_child ~debug_info:new_debug_info in
      context.push (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) model_index);
      context.push (to_chunk (Value child_payload) model_index);
      `String (ref_value model_index)
    in
    let attach_debug_info ~name ~debug_info ~render_child =
      match debug_info with
      | None ->
          let debug_info_idx, _ = emit_debug_info ~name ~debug_info:None in
          context.push (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) 0);
          render_child ~debug_info:(Some (debug_info_idx, None))
      | Some _ -> outline_with_debug_ref ~name ~debug_info ~render_child
    in
    let rec turn_element_into_payload ~context ~debug_info element =
      match (element : React.element) with
      | Empty -> `Null
      | Static { original; _ } -> turn_element_into_payload ~context ~debug_info original
      | Writer { original; _ } -> turn_element_into_payload ~context ~debug_info (original ())
      | Text t -> `String (escape_string_value t)
      (* Numeric text nodes cross the wire as raw JSON numbers, like React;
         integral floats print without the decimal part (JSON.stringify). *)
      | Int i -> `Int i
      | Float f -> float_to_json f
      | Lower_case_element { key; tag; attributes; children } ->
          (* Action props are serialized directly to JSON here (instead of being rewritten into String props) so the internal "$F<id>" reference is not $$-escaped. *)
          let props =
            List.filter_map
              (fun (prop : React.JSX.prop) ->
                match prop with
                | React.JSX.Action (_, key, f) -> Some (key, `String (outline_server_function ~context ~to_chunk f))
                | _ -> prop_to_json prop)
              attributes
          in
          let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
          node ~env ~key ~tag ~props ~owner
            (map_children_with_tree_context (turn_element_into_payload ~context ~debug_info) children)
      | Fragment children -> turn_element_into_payload ~context ~debug_info children
      | List children ->
          `List (map_children_with_tree_context (turn_element_into_payload ~context ~debug_info) children)
      | Array children ->
          `List
            (map_children_with_tree_context (turn_element_into_payload ~context ~debug_info) (Array.to_list children))
      | Upper_case_component (name, component) -> (
          let saved_ctx = !React.current_tree_context in
          React.reset_component_id_state saved_ctx;
          match component () with
          | element ->
              let did_use_id = React.check_did_render_id_hook () in
              if did_use_id then
                React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
              let result =
                if debug then
                  attach_debug_info ~name ~debug_info ~render_child:(fun ~debug_info ->
                      turn_element_into_payload ~context ~debug_info element)
                else turn_element_into_payload ~context ~debug_info element
              in
              React.current_tree_context := saved_ctx;
              result
          | exception exn ->
              React.current_tree_context := saved_ctx;
              let error = exn_to_error exn in
              (* A sync throw below the task root is outlined ("$L<id>"); the E row flushes after the row being serialized *)
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
              let result =
                if debug then
                  attach_debug_info ~name ~debug_info ~render_child:(fun ~debug_info ->
                      turn_element_into_payload ~context ~debug_info element)
                else turn_element_into_payload ~context ~debug_info element
              in
              React.current_tree_context := saved_ctx;
              result
          | Sleep ->
              let did_use_id = React.check_did_render_id_hook () in
              if did_use_id then
                React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
              let promise =
                try%lwt
                  let%lwt element = promise in
                  let result = to_chunk (Value (turn_element_into_payload ~context ~debug_info element)) in
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
          (* The outlined symbol row is pushed first, then rows produced by the children (props are serialized in {children, fallback} order), then rows produced by the fallback. *)
          let tag = suspense_tag ~context ~to_chunk in
          let children = turn_element_into_payload ~context ~debug_info children in
          let fallback = Option.map (turn_element_into_payload ~context ~debug_info) fallback in
          suspense_node ~env ~tag ~key ~fallback [ children ]
      | Client_component { key; import_module; import_name; props; client = _ } ->
          let ref = component_ref ~module_:import_module ~name:import_name in
          let index = Stream.push_client_ref ~context ~import_module ~import_name (to_chunk (Component_ref ref)) in
          let client_props = models_to_payload ~context ~to_chunk ~env props in
          (* Client references are lazy references ("$L<id>"): the client must not block on the module row, it resolves it when the chunk loads. *)
          node ~env ~tag:(lazy_value index) ~key ~props:client_props []
      | Provider { children; push; _ } ->
          let pop = push () in
          let result = turn_element_into_payload ~context ~debug_info children in
          pop ();
          result
      | Consumer children -> turn_element_into_payload ~context ~debug_info children
    in
    turn_element_into_payload ~context ~debug_info element

  and model_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env value =
    match (value : React.model_value) with
    | Json json -> escape_model_json json
    | Error error ->
        let index = Stream.push_deferred ~context (to_chunk (Error (env, error))) in
        `String (error_value index)
    | Element element -> element_to_payload ~context ?debug ?filter_stack_frame ~to_chunk ~env element
    | Promise (promise, value_to_model) -> (
        (* The same promise serialized twice in one stream dedups to one row,
           keyed on the promise's physical identity like React's
           writtenObjects (the transform is an srr-side artifact with no React
           equivalent — a .then() in JS creates a distinct thenable — so the
           promise alone determines the reference). *)
        let written_key = Physical_key.make promise in
        match Stream.find_written_promise ~context written_key with
        | Some index -> `String (promise_value index)
        | None ->
            let index =
              match Lwt.state promise with
              | Return value ->
                  (* React retries an already-resolved thenable as its own task
                     AFTER the current one (pingedTasks), so the resolution row
                     is serialized and written after the row that references it. *)
                  Stream.push_deferred ~context (fun index ->
                      match model_to_payload ~context ~to_chunk ~env (value_to_model value) with
                      | payload -> to_chunk (Value payload) index
                      | exception exn -> to_chunk (Error (env, exn_to_error exn)) index)
              | Sleep ->
                  let promise =
                    try%lwt
                      let%lwt value = promise in
                      let model = value_to_model value in
                      let payload = model_to_payload ~context ~to_chunk ~env model in
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
        let list = List.map (fun element -> model_to_payload ~context ~to_chunk ~env element) list in
        `List list
    | Assoc assoc ->
        let assoc = List.map (fun (name, value) -> (name, model_to_payload ~context ~to_chunk ~env value)) assoc in
        `Assoc assoc
    | Function action -> `String (outline_server_function ~context ~to_chunk action)

  and models_to_payload ~context ~to_chunk ~env props =
    List.map (fun (name, value) -> (name, model_to_payload ~context ~to_chunk ~env value)) props

  (* React renders the model at a task's ROOT destructively (retryTask →
     renderModelDestructive): the chain of transparent wrappers and components
     between the task root and the first concrete node belongs to the SAME
     task. An async component on that chain suspends the whole task and
     resolves into the task's own row; a sync throw (or rejection) errors the
     task's own row (`<id>:E`, handled by the caller's catch). Only values
     BELOW the root chain — props, children, list items — are outlined into
     new rows (see element_to_payload). *)
  let element_to_root_payload ?(debug = false) ?(filter_stack_frame = default_filter_stack_frame) ~context ~to_chunk
      ~env element =
    let rec go ~debug_info (element : React.element) =
      match element with
      | React.Static { original; _ } -> go ~debug_info original
      | Writer { original; _ } -> go ~debug_info (original ())
      | Fragment children -> go ~debug_info children
      | Consumer children -> go ~debug_info children
      | Provider { children; push; _ } ->
          let pop = push () in
          let%lwt payload = go ~debug_info children in
          pop ();
          Lwt.return payload
      | (Upper_case_component _ | Async_component _) when debug && Option.is_some debug_info ->
          (* In debug mode only the FIRST component attaches its debug rows to
             the root row; components further down are outlined with their own
             debug ref by the sync serializer (outline_with_debug_ref). *)
          Lwt.return (element_to_payload ~debug ~filter_stack_frame ?debug_info ~context ~to_chunk ~env element)
      | Upper_case_component (name, component) ->
          let saved_ctx = !React.current_tree_context in
          React.reset_component_id_state saved_ctx;
          let element =
            try component ()
            with exn ->
              React.current_tree_context := saved_ctx;
              raise exn
          in
          let did_use_id = React.check_did_render_id_hook () in
          if did_use_id then React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
          let%lwt payload = continue_with_debug ~name ~debug_info element in
          React.current_tree_context := saved_ctx;
          Lwt.return payload
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
          Lwt.return (element_to_payload ~debug ~filter_stack_frame ?debug_info ~context ~to_chunk ~env element)
    and continue_with_debug ~name ~debug_info element =
      match (debug, debug_info) with
      | true, None ->
          (* Matches attach_debug_info: the root component's debug info row is
             referenced from the root row (id 0, allocated before this task's
             serialization started). *)
          let debug_info_idx, _ = emit_debug_info_row ~filter_stack_frame ~context ~to_chunk ~name ~debug_info:None in
          context.push (to_chunk (Debug_ref (`String (ref_value debug_info_idx))) 0);
          go ~debug_info:(Some (debug_info_idx, None)) element
      | _ -> go ~debug_info element
    in
    go ~debug_info:None element

  let model_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env (value : React.model_value) =
    match value with
    | Element element -> element_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env element
    (* Non-element roots (JSON, promises, errors…) have no root chain to
       resolve: React outlines thenables and error values even at the root. *)
    | other -> Lwt.return (model_to_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env other)

  (* The root row is a task like any other (React allocates its id first via
     createTask): its serialization may suspend (async component on the root
     chain) and its row is written when the payload resolves. A failure on the
     root chain errors the root row itself (`0:E{...}`). *)
  let push_root_task ?debug ?filter_stack_frame ~context ~env model =
    Stream.push_async ~context (fun () ->
        try%lwt
          let%lwt payload = model_to_root_payload ?debug ?filter_stack_frame ~context ~to_chunk ~env model in
          Lwt.return (to_chunk (Value payload))
        with exn -> Lwt.return (to_chunk (Error (env, exn_to_error exn))))

  let hint_sink ~context { Flight_hints.dedup_key; code; payload } =
    Stream.push_hint ~context ~dedup_key (hint_to_chunk code payload)

  let run_stream ~env ~debug ?filter_stack_frame ?subscribe model =
    let stream, context = Stream.make () in
    Flight_hints.with_sink (hint_sink ~context) (fun () ->
        let (_root_index : int) = push_root_task ~debug ?filter_stack_frame ~context ~env model in
        match subscribe with None -> Lwt.return () | Some subscribe -> Lwt_stream.iter_s subscribe stream)

  let render ?(env = `Dev) ?(debug = false) ?filter_stack_frame ?subscribe ?identifier_prefix model =
    React.reset_id_rendering ?prefix:identifier_prefix ();
    run_stream ~env ~debug ?filter_stack_frame ?subscribe model

  let create_action_response ?(env = `Dev) ?(debug = false) ?filter_stack_frame ?subscribe response =
    let%lwt response =
      try%lwt response
      with exn ->
        let message = Printexc.to_string exn in
        let stack = create_stack_trace () in
        let digest = generate_uuid () in
        Lwt.return (React.Model.Error { message; stack; env = "Server"; digest })
    in
    run_stream ~env ~debug ?filter_stack_frame ?subscribe response
end

let rsc_start_script =
  Html.node "script" []
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
let rc_function_script = Html.node "script" [] [ Html.raw rc_function_definition ]
let rx_function_definition = Fizz_instructions.client_render_boundary

let timeout_error_message =
  "Switched to client rendering because the server rendering aborted due to:\n\nThe render timed out."

(* The error used to reject every still-pending row of the RSC payload when the render times out, mirroring React
   Flight's abort which errors all pending tasks with the abort reason. Error detail is dev-only (make_error_json
   emits only the digest in prod). *)
let timeout_error = { React.message = "The render timed out."; stack = `Null; env = "Server"; digest = "" }

let client_render_boundary_to_chunk ~env ~message ~include_definition index =
  let rx_call =
    (* Error detail is dev-only: in production React passes only the digest to avoid leaking server internals. *)
    match env with
    | `Prod -> Printf.sprintf {|$RX("B:%x","")|} index
    | `Dev -> Printf.sprintf {|$RX("B:%x","","%s")|} index (Html.escape_for_inline_script message)
  in
  Html.node "script" [] [ Html.raw (if include_definition then rx_function_definition ^ ";" ^ rx_call else rx_call) ]

let client_render_error_message exn =
  "Switched to client rendering because the server rendering errored:\n\n" ^ Printexc.to_string exn

let payload_to_html_chunk payload =
  Html.raw
    (Printf.sprintf "<script data-payload='%s'>window.srr_stream.push()</script>" (Html.escape_attribute_value payload))

let model_to_chunk model index = payload_to_html_chunk (Model.to_chunk model index)
let hint_row_to_html_chunk code payload = payload_to_html_chunk (Model.hint_to_chunk code payload)

let boundary_to_chunk html index =
  let rc_replacement b s = Html.node "script" [] [ Html.raw (Printf.sprintf "$RC('B:%x', 'S:%x')" b s) ] in
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

(* A Suspense boundary whose children errored before its placeholder was flushed: written directly in errored form
   (<!--$!-->), telling the hydrating client to client-render the boundary. Error detail is dev-only, mirroring
   ReactDOM.write_suspense_fallback_error and react-dom's errored boundary output. *)
let html_suspense_client_render ~env ~exn ~fallback =
  let template =
    match env with
    | `Prod -> Html.node "template" [] []
    | `Dev ->
        let backtrace = Printexc.get_backtrace () in
        Html.node "template" [ Html.attribute "data-msg" (Printexc.to_string exn ^ "\n" ^ backtrace) ] []
  in
  Html.list [ Html.raw "<!--$!-->"; template; fallback; Html.raw "<!--/$-->" ]

let chunk_stream_end_script = Html.node "script" [] [ Html.raw "window.srr_stream.close()" ]

let map_children_with_tree_context_lwt f children =
  match children with
  | [] -> Lwt.return []
  | [ single ] ->
      let%lwt result = f single in
      Lwt.return [ result ]
  | _ ->
      let saved_ctx = !React.current_tree_context in
      let total = List.length children in
      let%lwt results =
        Lwt_list.mapi_s
          (fun i el ->
            React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:total ~index:i;
            f el)
          children
      in
      React.current_tree_context := saved_ctx;
      Lwt.return results

(* For form elements with server actions, augment html_props with action="" and method="POST",
   and produce a hidden <input> carrying the $ACTION_ID_<hash> name. *)
let apply_form_action_attrs html_props action_id =
  let has_method =
    List.exists (function `Value (name, _) when String.equal name "method" -> true | _ -> false) html_props
  in
  let extra_attrs = Html.attribute "action" "" :: (if has_method then [] else [ Html.attribute "method" "POST" ]) in
  let hidden =
    Html.node "input"
      [
        Html.attribute "type" "hidden";
        Html.attribute "name" (Printf.sprintf "$ACTION_ID_%s" action_id);
        Html.attribute "value" "";
      ]
      []
  in
  (html_props @ extra_attrs, hidden)

(* Rewrite Action props into String props containing $F<index> RSC references. *)
let rewrite_action_props ~context attributes =
  List.map
    (fun prop ->
      match prop with
      | React.JSX.Action (_, key, f) ->
          React.JSX.String (key, key, Model.outline_server_function ~context ~to_chunk:model_to_chunk f)
      | _ -> prop)
    attributes

let rec client_to_html ~(fiber : Fiber.t) (element : React.element) =
  match element with
  | Empty -> Lwt.return Html.null
  | Static { prerendered; _ } -> Lwt.return (Html.raw prerendered)
  (* Writer subtrees can contain client components/Suspense below the prerendered markup, which the emit closure (ReactDOM.write_to_buffer) cannot serialize — walk the original tree instead. *)
  | Writer { original; _ } -> client_to_html ~fiber (original ())
  | Text text -> Lwt.return (Html.string text)
  | Int i -> Lwt.return (Html.string (Int.to_string i))
  | Float f -> Lwt.return (Html.string (Js.Float.toString f))
  | Fragment children -> client_to_html ~fiber children
  | List childrens ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) childrens in
      Lwt.return (Html.list html)
  | Array childrens ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) (Array.to_list childrens) in
      Lwt.return (Html.list html)
  | Lower_case_element { key; tag; attributes; children } when String.equal tag "form" ->
      let context = fiber.context in
      let form_action_id =
        List.find_map
          (fun (prop : React.JSX.prop) -> match prop with Action (_, _, f) -> Some f.id | _ -> None)
          attributes
      in
      let attributes = rewrite_action_props ~context attributes in
      render_lower_case ~fiber ~key ~tag ~attributes ~children ~form_action_id
  | Lower_case_element { key; tag; attributes; children } ->
      let context = fiber.context in
      let attributes = rewrite_action_props ~context attributes in
      render_lower_case ~fiber ~key ~tag ~attributes ~children ~form_action_id:None
  | Upper_case_component (_name, component) ->
      let saved_ctx = !React.current_tree_context in
      React.reset_component_id_state saved_ctx;
      let rec wait_for_suspense_to_resolve () =
        match component () with
        | exception React.Suspend (Any_promise promise) ->
            let%lwt _ = promise in
            wait_for_suspense_to_resolve ()
        | exception exn ->
            (* Propagate like the Async_component branch below: a Suspense boundary above turns the error into a
               client-rendered boundary; without one the render fails, matching react-dom's shell error. *)
            React.current_tree_context := saved_ctx;
            raise exn
        | output ->
            let did_use_id = React.check_did_render_id_hook () in
            if did_use_id then
              React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
            let%lwt result = client_to_html ~fiber output in
            React.current_tree_context := saved_ctx;
            Lwt.return result
      in
      wait_for_suspense_to_resolve ()
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
      try%lwt
        let promise = client_to_html ~fiber children in
        match Lwt.state promise with
        | Return html -> Lwt.return (html_suspense_immediate html)
        | Sleep ->
            let async =
              try%lwt
                let%lwt html = promise in
                Lwt.return (boundary_to_chunk html)
              with exn ->
                (* The placeholder already flushed: stream a $RX client-render instruction so the client flips the
                   boundary to errored and retries rendering it there, mirroring react-dom's post-flush errored
                   boundary. take_rx_definition runs at push time, keeping the $RX definition once-per-stream. *)
                Lwt.return (fun index ->
                    client_render_boundary_to_chunk ~env:fiber.env ~message:(client_render_error_message exn)
                      ~include_definition:(Stream.take_rx_definition context) index)
            in
            let index = Stream.push_boundary_async ~context (fun () -> async) in
            Lwt.return (html_suspense_placeholder ~fallback:fallback_html index)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        (* The boundary errored before its placeholder was flushed: write it directly in errored form, telling the
           hydrating client to client-render it. *)
        Lwt.return (html_suspense_client_render ~env:fiber.env ~exn ~fallback:fallback_html))
  | Client_component { client; _ } -> client_to_html ~fiber client
  | Provider { children; push; async_key; async_value } ->
      let pop = push () in
      let result = Lwt.with_value async_key (Some async_value) (fun () -> client_to_html ~fiber children) in
      let%lwt result = result in
      pop ();
      Lwt.return result
  | Consumer children -> client_to_html ~fiber children

and render_lower_case ~fiber ~key:_ ~tag ~attributes ~children ~form_action_id =
  let html_props = ReactDOM.attributes_to_html attributes in
  match (form_action_id, ReactDOM.getDangerouslyInnerHtml attributes) with
  | _, Some inner_html -> Lwt.return (Html.node tag html_props [ Html.raw inner_html ])
  | Some action_id, None ->
      let html_props, hidden = apply_form_action_attrs html_props action_id in
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) children in
      Lwt.return (Html.node tag html_props (hidden :: html))
  | None, None ->
      let%lwt html = map_children_with_tree_context_lwt (client_to_html ~fiber) children in
      Lwt.return (Html.node tag html_props html)

let is_async props =
  let open React.JSX in
  let has_async prop = match prop with Bool ("async", _, value) -> value | _ -> false in
  List.exists has_async props

let has_precedence_and_rel_stylesheet props =
  let open React.JSX in
  let has_precedence prop = match prop with String ("precedence", _, _) -> true | _ -> false in
  let has_rel_stylesheet prop = match prop with String ("rel", _, "stylesheet") -> true | _ -> false in
  List.exists has_precedence props && List.exists has_rel_stylesheet props

(* Classification of lower-case elements for head hoisting.
   Head elements (meta, style, title, etc) might be scattered throughout the component tree
   but need to be rendered in the <head> section. This type makes the routing decisions
   explicit and documented. *)
type element_role =
  | Html_root (* <html> at document root - strip wrapper, collect attributes for reconstruction *)
  | Head_section (* <head> - hoist entire element, render children normally inside it *)
  | Body_section (* <body> - track inside_body flag for nested elements *)
  | Hoistable_resource (* async <script>, <link rel="stylesheet" precedence="..."> *)
  | Hoistable_meta (* <title>, <meta>, <link> outside head - promoted to <head> *)
  | Regular (* all other elements, including elements already inside <head> *)

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

let rec render_element_to_html ~(fiber : Fiber.t) ~debug_info (element : React.element) : (Html.element * json) Lwt.t =
  match element with
  | Empty -> Lwt.return (Html.null, `Null)
  | Static { prerendered; original } ->
      (* Static carries HTML prerendered at compile time (ppx optimization). The model walk below hoists any <title>/<meta>/<link>/async <script> in the subtree into the fiber — but the prerendered bytes still contain them at their original position. When that happens, use the walked HTML to avoid emitting them twice. *)
      let hoisted_before = fiber.hoisted_count in
      let%lwt html, model = render_element_to_html ~fiber ~debug_info original in
      if fiber.hoisted_count = hoisted_before then Lwt.return (Html.raw prerendered, model) else Lwt.return (html, model)
  | Writer { original; _ } ->
      (* Writer subtrees can contain components below the prerendered markup. We render the original tree instead of the prerendered *)
      render_element_to_html ~fiber ~debug_info (original ())
  | Text s -> Lwt.return (Html.string s, `String (Model.escape_string_value s))
  | Int i -> Lwt.return (Html.string (Int.to_string i), `Int i)
  | Float f ->
      (* HTML stringifies numbers the way JavaScript does while the model keeps the raw JSON number. *)
      Lwt.return (Html.string (Js.Float.toString f), Model.float_to_json f)
  | Fragment children -> render_element_to_html ~fiber ~debug_info children
  | List list -> elements_to_html ~fiber ~debug_info list
  | Array arr -> elements_to_html ~fiber ~debug_info (Array.to_list arr)
  | Upper_case_component (name, component) -> (
      let saved_ctx = !React.current_tree_context in
      React.reset_component_id_state saved_ctx;
      match component () with
      | element ->
          let did_use_id = React.check_did_render_id_hook () in
          if did_use_id then React.current_tree_context := React.Tree_context.push saved_ctx ~total_children:1 ~index:0;
          let%lwt result = continue_with_debug_html ~fiber ~name ~debug_info element in
          React.current_tree_context := saved_ctx;
          Lwt.return result
      | exception exn ->
          React.current_tree_context := saved_ctx;
          raise exn)
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
      let props = Model.models_to_payload ~context ~to_chunk:model_to_chunk ~env props in
      let%lwt html = client_to_html ~fiber client in
      let ref : json = Model.component_ref ~module_:import_module ~name:import_name in
      let index = Stream.push_client_ref ~context ~import_module ~import_name (model_to_chunk (Component_ref ref)) in
      (* Client references are lazy references ("$L<id>"), see Model.element_to_payload. *)
      let model = Model.node ~env ~tag:(Model.lazy_value index) ~key ~props [] in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } -> (
      let context = fiber.context in
      let%lwt html_fallback, model_fallback =
        match fallback with
        | None -> Lwt.return (Html.null, None)
        | Some fallback ->
            let%lwt html, model = render_element_to_html ~fiber ~debug_info fallback in
            Lwt.return (html, Some model)
      in
      (* The outlined suspense symbol row must be pushed before any row that references it (see Model.suspense_tag). *)
      let tag = Model.suspense_tag ~context ~to_chunk:model_to_chunk in
      try%lwt
        let promise = render_element_to_html ~fiber ~debug_info children in
        match Lwt.state promise with
        | Sleep ->
            let promise =
              try%lwt
                let%lwt html, model = promise in
                let to_chunk index = Html.list [ boundary_to_chunk html index; model_to_chunk (Value model) index ] in
                Lwt.return to_chunk
              with exn ->
                let error = Model.exn_to_error exn in
                let to_chunk index = model_to_chunk (Error (fiber.env, error)) index in
                Lwt.return to_chunk
            in
            let index = Stream.push_boundary_async ~context (fun () -> promise) in
            Lwt.return
              ( html_suspense_placeholder ~fallback:html_fallback index,
                Model.suspense_placeholder ~env:fiber.env ~tag ~key ~fallback:model_fallback index )
        | Return (html, model) ->
            let model = Model.suspense_node ~env:fiber.env ~tag ~key ~fallback:model_fallback [ model ] in
            Lwt.return (html_suspense_immediate html, model)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        let context = fiber.context in
        let error = Model.exn_to_error exn in
        let to_chunk index =
          Html.list [ model_to_chunk (Error (fiber.env, error)) index; boundary_to_chunk Html.null index ]
        in
        let index = Stream.push ~context to_chunk in
        let html = html_suspense_placeholder ~fallback:html_fallback index in
        Lwt.return (html, Model.suspense_placeholder ~env:fiber.env ~tag ~key ~fallback:model_fallback index))
  | Provider { children; push; async_key; async_value } ->
      let pop = push () in
      let result =
        Lwt.with_value async_key (Some async_value) (fun () -> render_element_to_html ~fiber ~debug_info children)
      in
      let%lwt result = result in
      pop ();
      Lwt.return result
  | Consumer children -> render_element_to_html ~fiber ~debug_info children
  | Lower_case_element { key; tag; attributes; children } ->
      render_lower_case_element ~fiber ~debug_info ~key ~tag ~attributes ~children ()

(* The HTML-path twin of Model.attach_debug_info/outline_with_debug_ref: the first component attaches its debug rows to the root row (id 0, embedded in the shell); nested components are outlined into their own model row with a D ref while their HTML stays inline. *)
and continue_with_debug_html ~(fiber : Fiber.t) ~name ~debug_info element =
  if not fiber.debug then render_element_to_html ~fiber ~debug_info element
  else
    let context = fiber.context in
    let filter_stack_frame = fiber.filter_stack_frame in
    match debug_info with
    | None ->
        let debug_info_idx, _ =
          Model.emit_debug_info_row ~filter_stack_frame ~context ~to_chunk:model_to_chunk ~name ~debug_info:None
        in
        context.push (model_to_chunk (Debug_ref (`String (Model.ref_value debug_info_idx))) 0);
        render_element_to_html ~fiber ~debug_info:(Some (debug_info_idx, None)) element
    | Some _ ->
        let model_index = context.index in
        context.index <- context.index + 1;
        let debug_info_idx, owner_idx =
          Model.emit_debug_info_row ~filter_stack_frame ~context ~to_chunk:model_to_chunk ~name ~debug_info
        in
        let%lwt html, child_model =
          render_element_to_html ~fiber ~debug_info:(Some (debug_info_idx, owner_idx)) element
        in
        context.push (model_to_chunk (Debug_ref (`String (Model.ref_value debug_info_idx))) model_index);
        context.push (model_to_chunk (Value child_model) model_index);
        Lwt.return (html, `String (Model.ref_value model_index))

and render_lower_case_element ~fiber ~debug_info ~key ~tag ~attributes ~children () =
  let inner_html = ReactDOM.getDangerouslyInnerHtml attributes in
  (* Record the root tag on first lower-case element visit *)
  (match Fiber.root_tag ~fiber with Some _ -> () | None -> Fiber.set_root_tag ~fiber tag);
  match classify_element ~fiber ~tag ~attributes with
  | Regular when String.equal tag "form" ->
      render_form_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html ()
  | Regular -> render_regular_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html ()
  | Html_root ->
      (* Skip rendering the <html> wrapper since we reconstruct it in reconstruct_document *)
      Fiber.set_html_attributes ~fiber (ReactDOM.attributes_to_html attributes);
      let%lwt html, model = render_regular_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html () in
      let html_children = match html with Html.Node { children; _ } -> Html.list children | _ -> html in
      Lwt.return (html_children, model)
  | Head_section ->
      fiber.inside_head <- true;
      let%lwt value =
        handle_hoistable_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html
          ~on_push:Fiber.push_head_element ()
      in
      fiber.inside_head <- false;
      Lwt.return value
  | Body_section ->
      fiber.inside_body <- true;
      let%lwt value = render_regular_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html () in
      fiber.inside_body <- false;
      Lwt.return value
  | Hoistable_resource ->
      handle_hoistable_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html
        ~on_push:Fiber.push_resource ()
  | Hoistable_meta ->
      handle_hoistable_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html
        ~on_push:Fiber.push_extra_head_child ()

and handle_hoistable_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html ~on_push () =
  fiber.hoisted_count <- fiber.hoisted_count + 1;
  let props = Model.props_to_json attributes in
  let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
  let create_model children =
    (* In case of the model, we don't care about inner_html as a children since we need it as a prop. This is the opposite from html rendering *)
    match (Html.is_self_closing_tag tag, inner_html) with
    | _, Some _ | true, _ -> Model.node ~env:fiber.env ~tag ~key ~props ~owner []
    | false, None ->
        let children = match children with `List l -> l | other -> [ other ] in
        Model.node ~env:fiber.env ~tag ~key ~props ~owner children
  in
  let create_html_node ~html_props ~children_html =
    match inner_html with
    | Some inner_html -> Html.{ tag; attributes = html_props; children = [ Html.raw inner_html ] }
    | None -> Html.{ tag; attributes = html_props; children = [ children_html ] }
  in

  let html_props = ReactDOM.attributes_to_html attributes in
  let%lwt children_html, children_model = elements_to_html ~fiber ~debug_info children in
  let html = create_html_node ~html_props ~children_html in
  on_push ~fiber html;
  Lwt.return (Html.null, create_model children_model)

and process_attributes ~context ?form_action_id attributes =
  let html_props =
    List.map
      (fun (prop : React.JSX.prop) ->
        match (form_action_id, prop) with
        | Some _, Action (_, _, _) ->
            (* Omit the original Action attribute; action="" and method="POST" are added by apply_form_action_attrs *)
            Html.omitted ()
        | _ -> ReactDOM.attribute_to_html prop)
      attributes
  in
  let json_props =
    List.filter_map
      (fun (prop : React.JSX.prop) ->
        match prop with
        | Action (_, key, f) -> Some (key, `String (Model.outline_server_function ~context ~to_chunk:model_to_chunk f))
        | _ -> Model.prop_to_json prop)
      attributes
  in
  (html_props, json_props)

and render_regular_element ~fiber ~debug_info ~key ~tag ~attributes ~children ~inner_html () =
  let html_props, json_props = process_attributes ~context:fiber.context attributes in
  let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
  match (Html.is_self_closing_tag tag, inner_html) with
  | true, _ -> Lwt.return (Html.node tag html_props [], Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner [])
  | false, Some inner_html ->
      Lwt.return
        ( Html.node tag html_props [ Html.raw inner_html ],
          Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner [] )
  | false, None ->
      let%lwt html, model = elements_to_html ~fiber ~debug_info children in
      let model_children = match model with `List l -> l | other -> [ other ] in
      Lwt.return
        (Html.node tag html_props [ html ], Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner model_children)

and render_form_element ~(fiber : Fiber.t) ~debug_info ~key ~tag ~attributes ~children ~inner_html () =
  let context = fiber.context in
  let action_id =
    List.find_map
      (fun (prop : React.JSX.prop) -> match prop with Action (_, _, f) -> Some f.id | _ -> None)
      attributes
  in
  let html_props, json_props = process_attributes ~context ?form_action_id:action_id attributes in
  let owner = Option.bind debug_info (fun (_, owner_idx) -> owner_idx) in
  match (inner_html, action_id) with
  | Some inner_html, _ ->
      Lwt.return
        ( Html.node tag html_props [ Html.raw inner_html ],
          Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner [] )
  | None, Some action_id ->
      let html_props, hidden = apply_form_action_attrs html_props action_id in
      let%lwt html, model = elements_to_html ~fiber ~debug_info children in
      let model_children = match model with `List l -> l | other -> [ other ] in
      Lwt.return
        ( Html.node tag html_props [ Html.list [ hidden; html ] ],
          Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner model_children )
  | None, None ->
      let%lwt html, model = elements_to_html ~fiber ~debug_info children in
      let model_children = match model with `List l -> l | other -> [ other ] in
      Lwt.return
        (Html.node tag html_props [ html ], Model.node ~env:fiber.env ~tag ~key ~props:json_props ~owner model_children)

and elements_to_html ~fiber ~debug_info elements =
  let%lwt html_and_models = map_children_with_tree_context_lwt (render_element_to_html ~fiber ~debug_info) elements in
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

(* Head children are reordered to match React's Fizz priority buckets (issue #303).
   See arch/server/head-ordering.js for concrete React 19.1 output. *)

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
        | Stylesheet_resource -> stylesheets := el :: !stylesheets
        | Async_script -> scripts := el :: !scripts
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
  (* resources and extra_head_children are accumulated in reverse order (cons-prepend) for O(1) insertion *)
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
    (* React's Fizz writes the preamble unconditionally for non-document renders: hoistables
       (charset → viewport → stylesheets → async scripts → other) stream at the very start of
       the shell, before the root HTML, without a <head> wrapper. A literal <head> in the tree
       keeps its wrapper around the merged hoisted content. *)
    let hoisted =
      match fiber.head_element with
      | Some node -> [ Html.Node { node with children = sort_head_children (all_head_content @ node.children) } ]
      | None -> sort_head_children all_head_content
    in
    let rest = if skip_root then user_scripts else root_html :: user_scripts in
    Html.list (hoisted @ rest)

(* Default heuristic for how to split up the HTML content into progressive loading https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-server/src/ReactFizzServer.js#L310-L323 *)
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

let create_user_scripts ~root_data_payload ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules () =
  let bootstrap_script_content =
    match bootstrapScriptContent with
    | None -> Html.null
    | Some content -> Html.node "script" [] [ Html.raw (Html.escape_entire_inline_script content) ]
  in
  let bootstrap_scripts_nodes =
    match bootstrapScripts with
    | None -> Html.null
    | Some scripts ->
        scripts
        |> List.map (fun src -> Html.node "script" [ Html.attribute "src" src; Html.attribute "async" "" ] [])
        |> Html.list
  in
  let bootstrap_modules_nodes =
    match bootstrapModules with
    | None -> Html.null
    | Some modules ->
        modules
        |> List.map (fun src ->
            Html.node "script"
              [ Html.attribute "src" src; Html.attribute "async" ""; Html.attribute "type" "module" ]
              [])
        |> Html.list
  in
  [
    rc_function_script;
    rsc_start_script;
    root_data_payload;
    bootstrap_script_content;
    bootstrap_scripts_nodes;
    bootstrap_modules_nodes;
  ]

let render_html ?(skipRoot = false) ?(env = `Dev) ?(debug = false) ?(filter_stack_frame = default_filter_stack_frame)
    ?timeout ?(progressive_chunk_size = default_progressive_chunk_size) ?bootstrapScriptContent ?bootstrapScripts
    ?bootstrapModules ?identifier_prefix element =
  React.reset_id_rendering ?prefix:identifier_prefix ();
  React.Cache.with_request_cache_async (fun () ->
      let progressive_chunk_size = max 1 progressive_chunk_size in
      let initial_resources =
        create_initial_resources ~bootstrap_scripts:bootstrapScripts ~bootstrap_modules:bootstrapModules
      in
      (* Since we don't push the root_data_payload to the stream but return it immediately with the initial HTML,
         the stream's initial index starts at 1, with index 0 reserved for the root_data_payload.

         The root is also treated as a pending segment that must complete before the stream can be closed,
         as we don't push_async it to the stream, the pending counter starts at 1.
         Similar on how react does: https://github.com/facebook/react/blob/7d9f876cbc7e9363092e60436704cf8ae435b969/packages/react-server/src/ReactFizzServer.js#L572-L581
         *)
      let stream, context = Stream.make ~initial_index:1 ~pending:1 () in
      let hint_sink { Flight_hints.dedup_key; code; payload } =
        Stream.push_hint ~context ~dedup_key (hint_row_to_html_chunk code payload)
      in
      (* Installed before boundary tasks are created so their Lwt resumptions carry the sink: hints from
         late-resolving boundaries still land. *)
      Flight_hints.with_sink hint_sink @@ fun () ->
      let fiber : Fiber.t =
        {
          context;
          env;
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
        }
      in
      let%lwt root_html, root_model = render_element_to_html ~fiber ~debug_info:None element in
      (* To return the model value immediately, we don't push it to the stream but return it as a payload script together with the user_scripts *)
      let root_data_payload = model_to_chunk (Value root_model) 0 in
      (* Rows deferred while serializing the root model (error rows, resolved
         promise rows) stream right after the initial document, which embeds
         the root payload itself. *)
      Stream.flush_deferred ~context;
      (* Decrement the pending counter to signal that the root data payload is complete. *)
      context.pending <- context.pending - 1;
      (* In case of not having any task pending, we can close the stream *)
      if context.pending = 0 then Stream.close context;
      let user_scripts =
        create_user_scripts ~root_data_payload ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules ()
      in
      let html = reconstruct_document ~fiber ~root_html ~user_scripts ~skip_root:skipRoot in
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
            Buffer.add_string buf (Html.to_string chunk_stream_end_script);
            flush ()
          end
        in
        let subscription =
          let%lwt () = Push_stream.subscribe ~fn:buffered stream in
          finish ()
        in
        match timeout with
        | None -> subscription
        | Some seconds ->
            Lwt.pick
              [
                subscription;
                (* On timeout, emit a $RX client-render instruction per still-pending Suspense boundary (the client flips each boundary to errored and retries rendering it there), then close the stream.

                  The $RX scripts are written straight into the subscriber's buffer since the stream subscription is about to be cancelled by Lwt.pick. Closing sets [closed], which guards the async pushes of boundary promises that resolve later. *)
                (let%lwt () = Lwt_unix.sleep seconds in
                 if not context.closed then (
                   let pending_boundaries =
                     List.rev
                       (List.filter_map
                          (fun (index, kind) -> match kind with `Boundary -> Some index | `Model_row -> None)
                          context.pending_rows)
                   in
                   let pending_rows = List.sort compare (List.map fst context.pending_rows) in
                   context.pending_rows <- [];
                   (* Reject every still-pending row of the RSC payload (lazy elements, promises passed as props and the content of pending Suspense boundaries) with an error row so the client-side $L/$@ references settle instead of hanging forever. *)
                   List.iter
                     (fun index ->
                       Buffer.add_string buf (Html.to_string (model_to_chunk (Error (env, timeout_error)) index)))
                     pending_rows;
                   List.iter
                     (fun index ->
                       Buffer.add_string buf
                         (Html.to_string
                            (client_render_boundary_to_chunk ~env ~message:timeout_error_message
                               ~include_definition:(Stream.take_rx_definition context) index)))
                     pending_boundaries;
                   context.pending <- 0;
                   Stream.close context);
                 finish ());
              ]
      in
      Lwt.return (Html.to_string html, subscribe))

let render_model_value ?(env = `Dev) ?(debug = false) ?filter_stack_frame ?subscribe model =
  React.Cache.with_request_cache_async (fun () -> Model.render ~env ~debug ?filter_stack_frame ?subscribe model)

let render_model ?(env = `Dev) ?(debug = false) ?filter_stack_frame ?subscribe model =
  render_model_value ~env ~debug ?filter_stack_frame ?subscribe (React.Model.Element model)

let create_action_response ?env ?debug ?filter_stack_frame ?subscribe response =
  React.Cache.with_request_cache_async (fun () ->
      Model.create_action_response ?env ?debug ?filter_stack_frame ?subscribe response)

(* Reply decoding: deserialize client-to-server action arguments. Handles React's special $-prefixed string encoding from processReply/encodeReply.
   Reference: https://github.com/facebook/react/blob/main/packages/react-server/src/ReactFlightReplyServer.js

   All supported prefixes:
     $$  → Escaped string (literal $ prefix)
     $u  → undefined ($undefined) → Null
     $K  → FormData reference (handled at top level, not by decode_value)
     $D  → Date (ISO 8601 string)
     $n  → BigInt (decimal string)
     $N  → NaN
     $I  → Infinity
     $-0 → Negative zero
     $-  → Negative infinity

   Outlined model types (resolved from FormData entries):
     $Q  → Map → Assoc (if all keys are strings) or List of [key, value] pairs
     $W  → Set → List
     $i  → Iterator → List
     $F  → Server Reference → Assoc {id, bound}

   Unsupported (raise Invalid_argument with descriptive message):
     $T  → Temporary Reference (no infrastructure)
     $@  → Promise (not representable as synchronous JSON)
     $A/$O/$o/$U/$S/$s/$L/$l/$G/$g/$M/$m/$V → TypedArrays/ArrayBuffer (binary data)
     $B  → Blob (binary data)
     $R/$r → ReadableStream (streaming)
     $X/$x → AsyncIterable/AsyncIterator (streaming)

   Unknown $-prefixed strings are treated as outlined model references when FormData is available, or as Null otherwise. React's processReply escapes all user strings starting with $ to $$, so unrecognized prefixes indicate protocol-level references. *)

(* Convert a hex-encoded part ID to a decimal FormData key.
   React's processReply references use hex encoding, while FormData entries
   are keyed by the decimal representation of the part ID. *)
let hex_to_formdata_key hex_id = Option.map string_of_int (int_of_string_opt ("0x" ^ hex_id))

(* Look up an outlined model entry from FormData by hex-encoded ID and parse it as JSON. *)
let resolve_from_formdata formData hex_id =
  match hex_to_formdata_key hex_id with
  | Some key -> (
      try
        let (`String json_str) = Js.FormData.get formData key in
        Yojson.Basic.from_string json_str
      with Not_found -> `Null)
  | None -> `Null

(* Look up a raw string entry from FormData by hex-encoded ID (for Blobs and other binary data). *)
let resolve_raw_from_formdata formData hex_id =
  match hex_to_formdata_key hex_id with
  | Some key -> (
      try
        let (`String data) = Js.FormData.get formData key in
        Ok (`String data)
      with Not_found -> Error (Printf.sprintf "decodeReply: Blob ($B) entry not found in FormData for key %s" key))
  | None -> Error (Printf.sprintf "decodeReply: Blob ($B) invalid hex ID: %s" hex_id)

let unsupported name = Error (Printf.sprintf "decodeReply: %s is not supported" name)

type decode_ctx = { formData : Js.FormData.t option; temporaryReferences : (string -> json option) option }

(* Recursively decode a JSON value, resolving $-prefixed special strings. When formData is provided, outlined model references ($Q, $W, $F, $i) are resolved by looking up the corresponding FormData entry and recursively decoding it. *)
let rec decode_value (ctx : decode_ctx) (json : json) : (json, string) result =
  match json with
  | `String value when String.length value >= 2 && String.get value 0 = '$' -> (
      let len = String.length value in
      let rest = String.sub value 2 (len - 2) in
      match String.get value 1 with
      (* Escaped user string: drop only the escaping '$' *)
      | '$' -> Ok (`String (String.sub value 1 (len - 1)))
      | 'u' -> Ok `Null
      | 'K' -> Ok `Null
      | 'D' -> Ok (`String rest)
      | 'n' -> Ok (`String rest)
      | 'N' -> Ok (`Float Float.nan)
      | 'I' -> Ok (`Float Float.infinity)
      | '-' -> Ok (if String.equal value "$-0" then `Float (-0.) else `Float Float.neg_infinity)
      | 'Q' -> decode_outlined_map ctx rest
      | 'W' -> resolve_outlined ctx "Set ($W)" rest
      | 'i' -> resolve_outlined ctx "Iterator ($i)" rest
      | 'F' -> resolve_outlined ctx "Server Reference ($F)" rest
      | 'T' -> (
          match ctx.temporaryReferences with
          | Some lookup -> (
              match lookup rest with
              | Some resolved -> Ok resolved
              | None ->
                  Error
                    (Printf.sprintf
                       "decodeReply: Temporary Reference $T%s not found in the provided temporaryReferences map" rest))
          | None -> Error "decodeReply: Temporary Reference ($T) requires a temporaryReferences resolver")
      | '@' -> unsupported "Promise ($@)"
      | ('A' | 'O' | 'o' | 'U' | 'S' | 's' | 'L' | 'l' | 'G' | 'g' | 'M' | 'm' | 'V') as c ->
          unsupported (Printf.sprintf "TypedArray/ArrayBuffer ($%c)" c)
      | 'B' -> (
          match ctx.formData with
          | Some fd -> resolve_raw_from_formdata fd rest
          | None -> Error "decodeReply: Blob ($B) requires FormData for resolution")
      | 'R' -> unsupported "ReadableStream ($R)"
      | 'r' -> unsupported "ReadableStream bytes ($r)"
      | 'X' -> unsupported "AsyncIterable ($X)"
      | 'x' -> unsupported "AsyncIterator ($x)"
      | _ -> (
          match ctx.formData with
          | Some fd ->
              let resolved = resolve_from_formdata fd (String.sub value 1 (len - 1)) in
              decode_value ctx resolved
          | None -> Ok `Null))
  | `List items -> decode_list ctx items
  | `Assoc pairs -> decode_assoc ctx pairs
  | other -> Ok other

and decode_list ctx items =
  let rec aux acc = function
    | [] -> Ok (`List (List.rev acc))
    | item :: rest -> ( match decode_value ctx item with Ok v -> aux (v :: acc) rest | Error _ as err -> err)
  in
  aux [] items

and decode_assoc ctx pairs =
  let rec aux acc = function
    | [] -> Ok (`Assoc (List.rev acc))
    | (k, v) :: rest -> ( match decode_value ctx v with Ok v -> aux ((k, v) :: acc) rest | Error _ as err -> err)
  in
  aux [] pairs

and resolve_outlined ctx type_name hex_id =
  match ctx.formData with
  | None -> Error (Printf.sprintf "decodeReply: %s requires FormData for outlined model resolution" type_name)
  | Some fd ->
      let resolved = resolve_from_formdata fd hex_id in
      decode_value ctx resolved

(* Maps are serialized as [[key, value], ...]. If all keys are strings, converts to Assoc for ergonomic use with Melange_json decoders. Otherwise preserves the List of pairs representation. *)
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

let decodeReply ?temporaryReferences body =
  let ctx = { formData = None; temporaryReferences } in
  match Yojson.Basic.from_string body with
  | `List args ->
      let rec aux acc = function
        | [] -> Ok (Array.of_list (List.rev acc))
        | arg :: rest -> ( match decode_value ctx arg with Ok v -> aux (v :: acc) rest | Error _ as err -> err)
      in
      aux [] args
  | _ -> Error "Invalid args, this request was not created by server-reason-react"
  | exception Yojson.Json_error msg -> Error (Printf.sprintf "Invalid JSON: %s" msg)

let decodeFormDataReply ?temporaryReferences formData =
  let ctx = { formData = Some formData; temporaryReferences } in
  let input_prefix = ref None in
  let is_formdata_ref = function
    | `String value ->
        let len = String.length value in
        if len > 2 && String.get value 0 = '$' && String.get value 1 = 'K' then Some (String.sub value 2 (len - 2))
        else None
    | _ -> None
  in
  let formDataEntries = Js.FormData.entries formData in
  let model_str =
    try
      let (`String s) = Js.FormData.get formData "0" in
      Ok s
    with Not_found -> Error "decodeReply: FormData is missing the root entry at key \"0\""
  in
  match model_str with
  | Error _ as err -> err
  | Ok model_str -> (
      match Yojson.Basic.from_string model_str with
      | exception Yojson.Json_error msg -> Error (Printf.sprintf "Invalid JSON in FormData root: %s" msg)
      | `List items -> (
          let rec aux_args acc = function
            | [] -> Ok (Array.of_list (List.rev acc))
            | item :: rest -> (
                match is_formdata_ref item with
                | Some id ->
                    input_prefix := Some id;
                    aux_args acc rest
                | None -> ( match decode_value ctx item with Ok v -> aux_args (v :: acc) rest | Error _ as err -> err))
          in
          let args_result = aux_args [] items in
          match args_result with
          | Error _ as err -> err
          | Ok args ->
              let form_prefix = Option.map (fun id -> (id ^ "_", String.length id + 1)) !input_prefix in
              let rec aux_entries acc = function
                | [] -> acc
                | (key, value) :: entries -> (
                    if key = "0" then aux_entries acc entries
                    else
                      match form_prefix with
                      | Some (prefix, prefix_len) ->
                          if String.starts_with ~prefix key then (
                            Js.FormData.append acc (String.sub key prefix_len (String.length key - prefix_len)) value;
                            aux_entries acc entries)
                          else aux_entries acc entries
                      | None ->
                          Js.FormData.append acc key value;
                          aux_entries acc entries)
              in
              Ok (args, aux_entries (Js.FormData.make ()) formDataEntries))
      | _ -> Error "Invalid args, this request was not created by server-reason-react")

let action_id_prefix = "$ACTION_ID_"
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
