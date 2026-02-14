type 'value ref = { mutable current : 'value }
type domRef = CallbackDomRef of (Dom.element Js.nullable -> unit) | CurrentDomRef of Dom.element Js.nullable ref

module Ref = struct
  type t = domRef
  type currentDomRef = Dom.element Js.nullable ref
  type callbackDomRef = Dom.element Js.nullable -> unit

  let domRef (v : currentDomRef) = CurrentDomRef v
  let callbackDomRef (v : callbackDomRef) = CallbackDomRef v
end

let createRef () = { current = None }
let useRef value = { current = value }
let forwardRef f = f ()

module Event = struct
  type 'a synthetic

  module MakeEventWithType (Type : sig
    type t
  end) =
  struct
    let bubbles : Type.t -> bool = fun _ -> false
    let cancelable : Type.t -> bool = fun _ -> false
    let currentTarget : Type.t -> < .. > Js.t = fun _ -> object end
    let defaultPrevented : Type.t -> bool = fun _ -> false
    let eventPhase : Type.t -> int = fun _ -> 0
    let isTrusted : Type.t -> bool = fun _ -> false
    let nativeEvent : Type.t -> < .. > Js.t = fun _ -> object end
    let preventDefault : Type.t -> unit = fun _ -> ()
    let isDefaultPrevented : Type.t -> bool = fun _ -> false
    let stopPropagation : Type.t -> unit = fun _ -> ()
    let isPropagationStopped : Type.t -> bool = fun _ -> false
    let target : Type.t -> < .. > Js.t = fun _ -> object end
    let timeStamp : Type.t -> float = fun _ -> 0.
    let type_ : Type.t -> string = fun _ -> ""
    let persist : Type.t -> unit = fun _ -> ()
  end

  module Synthetic = struct
    type tag
    type t = tag synthetic

    let bubbles : 'a synthetic -> bool = fun _ -> false
    let cancelable : 'a synthetic -> bool = fun _ -> false
    let currentTarget : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let defaultPrevented : 'a synthetic -> bool = fun _ -> false
    let eventPhase : 'a synthetic -> int = fun _ -> 0
    let isTrusted : 'a synthetic -> bool = fun _ -> false
    let nativeEvent : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let preventDefault : 'a synthetic -> unit = fun _ -> ()
    let isDefaultPrevented : 'a synthetic -> bool = fun _ -> false
    let stopPropagation : 'a synthetic -> unit = fun _ -> ()
    let isPropagationStopped : 'a synthetic -> bool = fun _ -> false
    let target : 'a synthetic -> < .. > Js.t = fun _ -> object end
    let timeStamp : 'a synthetic -> float = fun _ -> 0.
    let type_ : 'a synthetic -> string = fun _ -> ""
    let persist : 'a synthetic -> unit = fun _ -> ()
  end

  (* let toSyntheticEvent : 'a synthetic -> Synthetic.t = i -> i *)

  module Clipboard = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let clipboardData : t -> < .. > Js.t = fun _ -> object end
  end

  module Composition = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let data : t -> string = fun _ -> ""
  end

  module Keyboard = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let charCode : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let key : t -> string = fun _ -> ""
    let keyCode : t -> int = fun _ -> 0
    let locale : t -> string = fun _ -> ""
    let location : t -> int = fun _ -> 0
    let metaKey : t -> bool = fun _ -> false
    let repeat : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let which : t -> int = fun _ -> 0
  end

  module Focus = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
  end

  module Form = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Mouse = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let shiftKey : t -> bool = fun _ -> false
  end

  module Pointer = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let detail : t -> int = fun _ -> 0

    (* let view : t -> Dom.window = fun _ -> object end *)
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let altKey : t -> bool = fun _ -> false
    let metaKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None

    (* let pointerId : t -> Dom.eventPointerId *)
    let width : t -> float = fun _ -> 0.
    let height : t -> float = fun _ -> 0.
    let pressure : t -> float = fun _ -> 0.
    let tangentialPressure : t -> float = fun _ -> 0.
    let tiltX : t -> int = fun _ -> 0
    let tiltY : t -> int = fun _ -> 0
    let twist : t -> int = fun _ -> 0
    let pointerType : t -> string = fun _ -> ""
    let isPrimary : t -> bool = fun _ -> false
  end

  module Selection = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Touch = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let changedTouches : t -> < .. > Js.t = fun _ -> object end
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let shiftKey : t -> bool = fun _ -> false
    let targetTouches : t -> < .. > Js.t = fun _ -> object end
    let touches : t -> < .. > Js.t = fun _ -> object end
  end

  module UI = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let detail : t -> int = fun _ -> 0
    (* let view : t -> Dom.window *)
  end

  module Wheel = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let deltaMode : t -> int = fun _ -> 0
    let deltaX : t -> float = fun _ -> 0.
    let deltaY : t -> float = fun _ -> 0.
    let deltaZ : t -> float = fun _ -> 0.
  end

  module Media = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Image = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)
  end

  module Animation = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let animationName : t -> string = fun _ -> ""
    let pseudoElement : t -> string = fun _ -> ""
    let elapsedTime : t -> float = fun _ -> 0.
  end

  module Transition = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let propertyName : t -> string = fun _ -> ""
    let pseudoElement : t -> string = fun _ -> ""
    let elapsedTime : t -> float = fun _ -> 0.
  end

  module Drag = struct
    type tag
    type t = tag synthetic

    include MakeEventWithType (struct
      type nonrec t = t [@@nonrec]
    end)

    let altKey : t -> bool = fun _ -> false
    let button : t -> int = fun _ -> 0
    let buttons : t -> int = fun _ -> 0
    let clientX : t -> int = fun _ -> 0
    let clientY : t -> int = fun _ -> 0
    let ctrlKey : t -> bool = fun _ -> false
    let getModifierState : t -> string -> bool = fun _ _ -> false
    let metaKey : t -> bool = fun _ -> false
    let movementX : t -> int = fun _ -> 0
    let movementY : t -> int = fun _ -> 0
    let pageX : t -> int = fun _ -> 0
    let pageY : t -> int = fun _ -> 0
    let relatedTarget : t -> < .. > Js.t option = fun _ -> None
    let screenX : t -> int = fun _ -> 0
    let screenY : t -> int = fun _ -> 0
    let shiftKey : t -> bool = fun _ -> false
    let dataTransfer : t -> < .. > Js.t option = fun _ -> None
  end
end

module JSX = struct
  type event =
    | Drag of (Event.Drag.t -> unit)
    | Mouse of (Event.Mouse.t -> unit)
    | Selection of (Event.Selection.t -> unit)
    | Touch of (Event.Touch.t -> unit)
    | UI of (Event.UI.t -> unit)
    | Wheel of (Event.Wheel.t -> unit)
    | Clipboard of (Event.Clipboard.t -> unit)
    | Composition of (Event.Composition.t -> unit)
    | Transition of (Event.Transition.t -> unit)
    | Animation of (Event.Animation.t -> unit)
    | Pointer of (Event.Pointer.t -> unit)
    | Keyboard of (Event.Keyboard.t -> unit)
    | Focus of (Event.Focus.t -> unit)
    | Form of (Event.Form.t -> unit)
    | Media of (Event.Media.t -> unit)
    | Inline of string

  type prop =
    | Action : (string * string * _ Runtime.server_function) -> prop
    | Bool of (string * string * bool)
    | String of (string * string * string)
    | Style of (string * string * string) list
    | DangerouslyInnerHtml of string
    | Ref of Ref.t
    | Event of string * event

  let bool name jsxName value = Bool (name, jsxName, value)
  let string name jsxName value = String (name, jsxName, value)
  let style value = Style value
  let int name jsxName value = String (name, jsxName, Int.to_string value)
  let float name jsxName value = String (name, jsxName, Float.to_string value)
  let dangerouslyInnerHtml value = DangerouslyInnerHtml value#__html
  let ref value = Ref value
  let event key value = Event (key, value)

  module Event = struct
    let drag key value = event key (Drag value)
    let mouse key value = event key (Mouse value)
    let selection key value = event key (Selection value)
    let touch key value = event key (Touch value)
    let ui key value = event key (UI value)
    let wheel key value = event key (Wheel value)
    let clipboard key value = event key (Clipboard value)
    let composition key value = event key (Composition value)
    let transition key value = event key (Transition value)
    let animation key value = event key (Animation value)
    let pointer key value = event key (Pointer value)
    let keyboard key value = event key (Keyboard value)
    let focus key value = event key (Focus value)
    let form key value = event key (Form value)
    let media key value = event key (Media value)
  end
end

type error = { message : string; stack : Yojson.Basic.t; env : string; digest : string }

module Model = struct
  type 'element t =
    | Function : 'server_function Runtime.server_function -> 'element t
    | List : 'element t list -> 'element t
    | Assoc : (string * 'element t) list -> 'element t
    | Json : Yojson.Basic.t -> 'element t
    | Error : error -> 'element t
    | Element : 'element -> 'element t
    | Promise : 'a Js.Promise.t * ('a -> 'element t) -> 'element t
end

type element =
  | Lower_case_element of lower_case_element
  | Upper_case_component of string * (unit -> element)
  | Async_component of string * (unit -> element Lwt.t)
  | Client_component of { props : client_props; client : element; import_module : string; import_name : string }
  | List of element list
  | Array of element array
  | Text of string
  | Static of { prerendered : string; original : element }
  | Fragment of element
  | Empty
  | Provider of { children : element; push : unit -> unit -> unit }
  | Consumer of element
  | Suspense of { key : string option; children : element; fallback : element }

and lower_case_element = { key : string option; tag : string; attributes : JSX.prop list; children : element list }
and client_props = (string * element Model.t) list
and model_value = element Model.t

exception Invalid_children of string

let compare_attribute (left : JSX.prop) (right : JSX.prop) =
  match (left, right) with
  | Bool (left_key, _, _), Bool (right_key, _, _) | String (left_key, _, _), String (right_key, _, _) ->
      String.compare left_key right_key
  | Style left_styles, Style right_styles ->
      List.compare
        (fun (left_property, _, left_value) (right_property, _, right_value) ->
          Int.compare (String.compare left_property right_property) (String.compare left_value right_value))
        left_styles right_styles
  | _ -> 0

let clone_attribute acc (attr : JSX.prop) (new_attr : JSX.prop) =
  match (attr, new_attr) with
  | Bool (left, _, _), Bool (right, _, _) when left == right -> new_attr :: acc
  | String (left, _, _), String (right, _, _) when left == right -> new_attr :: acc
  | _ -> new_attr :: acc

module StringMap = Map.Make (String)

let attributes_to_map attributes =
  List.fold_left
    (fun acc (attr : JSX.prop) ->
      match attr with
      | (Bool (key, _, _) | String (key, _, _)) as prop -> acc |> StringMap.add key prop
      (* The following constructors shoudn't be part of the StringMap *)
      | DangerouslyInnerHtml _ -> acc
      | Ref _ -> acc
      | Event _ -> acc
      | Action _ -> acc
      | Style _ -> acc)
    StringMap.empty attributes

let clone_attributes attributes new_attributes =
  let attribute_map = attributes_to_map attributes in
  let new_attribute_map = attributes_to_map new_attributes in
  StringMap.merge
    (fun _key attr new_attr ->
      match (attr, new_attr) with
      | Some attr, Some new_attr -> Some (clone_attribute [] attr new_attr)
      | Some attr, None -> Some [ attr ]
      | None, Some new_attr -> Some [ new_attr ]
      | None, None -> None)
    attribute_map new_attribute_map
  |> StringMap.bindings
  |> List.map (fun (_, attrs) -> attrs)
  |> List.flatten |> List.rev |> List.sort compare_attribute

let create_element_with_key ?key tag attributes children =
  match Html.is_self_closing_tag tag with
  | true when List.length children > 0 ->
      raise (Invalid_children (Printf.sprintf {|"%s" is a self-closing tag and must not have "children".\n|} tag))
  | true when List.exists (function JSX.DangerouslyInnerHtml _ -> true | _ -> false) attributes ->
      raise
        (Invalid_children
           (Printf.sprintf {|"%s" is a self-closing tag and must not have "dangerouslySetInnerHTML".\n|} tag))
  | true -> Lower_case_element { key; tag; attributes; children = [] }
  | false -> Lower_case_element { key; tag; attributes; children }

let createElement = create_element_with_key ?key:None
let createElementWithKey = create_element_with_key

let clone_component_error name =
  Printf.sprintf
    "React.cloneElement: cannot clone '%s'. In server-reason-react, component props are compile-time labelled \
     arguments (and extending them with new props at runtime is not supported). React.cloneElement only works with \
     lowercase DOM elements."
    name

let cloneElement element new_attributes =
  match element with
  | Lower_case_element { key; tag; attributes; children } ->
      Lower_case_element { key; tag; attributes = clone_attributes attributes new_attributes; children }
  | Upper_case_component (name, _) -> raise (Invalid_argument (clone_component_error name))
  | Async_component (name, _) -> raise (Invalid_argument (clone_component_error name))
  | Client_component { import_name; _ } -> raise (Invalid_argument (clone_component_error import_name))
  | Static _ -> raise (Invalid_argument "React.cloneElement: cannot clone a Static element")
  | Fragment _ -> raise (Invalid_argument "React.cloneElement: cannot clone a Fragment")
  | Text _ -> raise (Invalid_argument "React.cloneElement: cannot clone a Text element")
  | Empty -> raise (Invalid_argument "React.cloneElement: cannot clone a null element")
  | List _ -> raise (Invalid_argument "React.cloneElement: cannot clone a List")
  | Array _ -> raise (Invalid_argument "React.cloneElement: cannot clone an Array")
  | Provider { children = _; push = _ } -> raise (Invalid_argument "React.cloneElement: cannot clone a Provider")
  | Consumer _ -> raise (Invalid_argument "React.cloneElement: cannot clone a Consumer")
  | Suspense _ -> raise (Invalid_argument "React.cloneElement: cannot clone a Suspense")

module Fragment = struct
  let make ~children ?key:_ () = Fragment children
end

let fragment children = Fragment.make ~children ?key:None ()

(* ReasonReact APIs *)
let string txt = Text txt
let null = Empty
let int i = Text (string_of_int i)

(* FIXME: float_of_string might be different from the browser *)
let float f = Text (string_of_float f)
let array arr = Array arr
let list l = List l

type 'a provider = value:'a -> children:element -> unit -> element

module Context = struct
  type 'a t = { current_value : 'a ref; provider : 'a provider; consumer : children:element -> element }

  let provider ctx = ctx.provider
end

let createContext (initial_value : 'a) : 'a Context.t =
  let ref_value = { current = initial_value } in
  let provider ~value ~children () =
    Provider
      {
        children;
        push =
          (fun () ->
            let prev = ref_value.current in
            ref_value.current <- value;
            fun () -> ref_value.current <- prev);
      }
  in
  let consumer ~children = Consumer children in
  { current_value = ref_value; provider; consumer }

module Suspense = struct
  let or_react_null = function None -> null | Some x -> x

  let make ?key ?fallback ?children () =
    Suspense { key; fallback = or_react_null fallback; children = or_react_null children }
end

module Cache = struct
  type cache_entry = Ok of Obj.t | Error of exn
  type fn_cache = (Obj.t, cache_entry) Hashtbl.t
  type request_cache = (int, fn_cache) Hashtbl.t

  let current : request_cache option Stdlib.ref = Stdlib.ref None
  let fn_id_counter : int Stdlib.ref = Stdlib.ref 0

  let with_request_cache f =
    let prev = !current in
    current := Some (Hashtbl.create 16);
    Fun.protect ~finally:(fun () -> current := prev) f

  let with_request_cache_async f =
    let prev = !current in
    current := Some (Hashtbl.create 16);
    Lwt.finalize f (fun () ->
        current := prev;
        Lwt.return ())
end

module UseId = struct
  type t = {
    identifier_prefix : string;
    mutable tree_context_id : int;
    mutable tree_context_overflow : string;
    mutable tree_context_stack : (int * string) list;
    mutable local_id_counter : int;
    mutable local_id_counter_stack : int list;
  }

  let current : t option Stdlib.ref = Stdlib.ref None
  let fallback_id_counter = ref 0

  let int_to_base32 n =
    if n = 0 then "0"
    else
      let chars = "0123456789abcdefghijklmnopqrstuv" in
      let rec loop value acc =
        if value = 0 then acc
        else
          let digit = value mod 32 in
          let next = value / 32 in
          loop next (String.make 1 chars.[digit] :: acc)
      in
      String.concat "" (loop n [])

  let get_bit_length n =
    if n <= 0 then 0
    else
      let rec loop value bits = if value = 0 then bits else loop (value lsr 1) (bits + 1) in
      loop n 0

  let with_state state f =
    let prev = !current in
    current := Some state;
    Fun.protect ~finally:(fun () -> current := prev) f

  let with_state_async state f =
    let prev = !current in
    current := Some state;
    Lwt.finalize f (fun () ->
        current := prev;
        Lwt.return ())

  let create ?(identifierPrefix = "") () =
    {
      identifier_prefix = identifierPrefix;
      (* Starts with a leading bit. Root useId materializes as "0". *)
      tree_context_id = 1;
      tree_context_overflow = "";
      tree_context_stack = [];
      local_id_counter = 0;
      local_id_counter_stack = [];
    }

  let push_tree_id state ~total_children ~index =
    state.tree_context_stack <- (state.tree_context_id, state.tree_context_overflow) :: state.tree_context_stack;
    let base_id_with_leading_bit = state.tree_context_id in
    let base_overflow = state.tree_context_overflow in
    let base_length = get_bit_length base_id_with_leading_bit - 1 in
    let base_id = base_id_with_leading_bit land lnot (1 lsl base_length) in
    let slot = index + 1 in
    let length = get_bit_length total_children + base_length in
    if length > 30 then (
      let number_of_overflow_bits = base_length - (base_length mod 5) in
      let new_overflow_bits = (1 lsl number_of_overflow_bits) - 1 in
      let new_overflow = int_to_base32 (base_id land new_overflow_bits) in
      let rest_of_base_id = base_id lsr number_of_overflow_bits in
      let rest_of_base_length = base_length - number_of_overflow_bits in
      let rest_of_length = get_bit_length total_children + rest_of_base_length in
      let rest_of_new_bits = slot lsl rest_of_base_length in
      let id = rest_of_new_bits lor rest_of_base_id in
      let overflow = new_overflow ^ base_overflow in
      state.tree_context_id <- (1 lsl rest_of_length) lor id;
      state.tree_context_overflow <- overflow)
    else
      let new_bits = slot lsl base_length in
      let id = new_bits lor base_id in
      state.tree_context_id <- (1 lsl length) lor id;
      state.tree_context_overflow <- base_overflow

  let pop_tree_id state =
    match state.tree_context_stack with
    | (previous_id, previous_overflow) :: rest ->
        state.tree_context_id <- previous_id;
        state.tree_context_overflow <- previous_overflow;
        state.tree_context_stack <- rest
    | [] -> ()

  let with_tree_id ~total_children ~index f =
    match !current with
    | None -> f ()
    | Some state ->
        push_tree_id state ~total_children ~index;
        Fun.protect ~finally:(fun () -> pop_tree_id state) f

  let with_tree_id_async ~total_children ~index f =
    match !current with
    | None -> f ()
    | Some state ->
        push_tree_id state ~total_children ~index;
        Lwt.finalize f (fun () ->
            pop_tree_id state;
            Lwt.return ())

  let with_materialized_tree_id f = with_tree_id ~total_children:1 ~index:0 f
  let with_materialized_tree_id_async f = with_tree_id_async ~total_children:1 ~index:0 f

  let begin_component state =
    state.local_id_counter_stack <- state.local_id_counter :: state.local_id_counter_stack;
    state.local_id_counter <- 0

  let end_component state =
    let did_render_id = state.local_id_counter <> 0 in
    (match state.local_id_counter_stack with
    | previous :: rest ->
        state.local_id_counter <- previous;
        state.local_id_counter_stack <- rest
    | [] -> state.local_id_counter <- 0);
    did_render_id

  let with_component f =
    match !current with
    | None -> (f (), false)
    | Some state -> (
        begin_component state;
        match f () with
        | result ->
            let did_render_id = end_component state in
            (result, did_render_id)
        | exception exn ->
            let _ = end_component state in
            raise exn)

  let get_tree_id state =
    let id_with_leading_bit = state.tree_context_id in
    let base_length = get_bit_length id_with_leading_bit - 1 in
    let id = id_with_leading_bit land lnot (1 lsl base_length) in
    int_to_base32 id ^ state.tree_context_overflow

  let next_id () =
    match !current with
    | Some state ->
        let tree_id = get_tree_id state in
        let local_id = state.local_id_counter in
        state.local_id_counter <- local_id + 1;
        let hook_suffix = if local_id > 0 then "H" ^ int_to_base32 local_id else "" in
        ":" ^ state.identifier_prefix ^ "R" ^ tree_id ^ hook_suffix ^ ":"
    | None ->
        fallback_id_counter := !fallback_id_counter + 1;
        Int.to_string !fallback_id_counter
end

let memo f _component = f
let memoCustomCompareProps f _compare _component = f

let cache fn =
  let fn_id = !Cache.fn_id_counter in
  Cache.fn_id_counter := fn_id + 1;
  fun arg ->
    match !Cache.current with
    | None -> fn arg
    | Some cache_map -> (
        let fn_cache =
          match Hashtbl.find_opt cache_map fn_id with
          | Some cache -> cache
          | None ->
              let cache = Hashtbl.create 8 in
              Hashtbl.add cache_map fn_id cache;
              cache
        in
        let arg_key = Obj.repr arg in
        match Hashtbl.find_opt fn_cache arg_key with
        | Some (Cache.Ok value) -> Obj.obj value
        | Some (Cache.Error error) -> raise error
        | None -> (
            try
              let result = fn arg in
              Hashtbl.add fn_cache arg_key (Cache.Ok (Obj.repr result));
              result
            with exn ->
              Hashtbl.add fn_cache arg_key (Cache.Error exn);
              raise exn))

let useContext (context : 'a Context.t) = context.current_value.current

let useState (make_initial_value : unit -> 'state) =
  let initial_value : 'state = make_initial_value () in
  let setState (fn : 'state -> 'state) =
    let _ = fn initial_value in
    ()
  in
  (initial_value, setState)

type ('input, 'output) callback = 'input -> 'output

let useSyncExternalStore ~subscribe:_ ~getSnapshot = getSnapshot ()
let useSyncExternalStoreWithServer ~subscribe:_ ~getSnapshot:_ ~getServerSnapshot = getServerSnapshot ()
let useId () = UseId.next_id ()
let useMemo fn = fn ()
let useMemo0 fn = fn ()
let useMemo1 fn _ = fn ()
let useMemo2 fn _ = fn ()
let useMemo3 fn _ = fn ()
let useMemo4 fn _ = fn ()
let useMemo5 fn _ = fn ()
let useMemo6 fn _ = fn ()
let useCallback fn = fn
let useCallback0 fn = fn
let useCallback1 fn _ = fn
let useCallback2 fn _ = fn
let useCallback3 fn _ = fn
let useCallback4 fn _ = fn
let useCallback5 fn _ = fn
let useCallback6 fn _ = fn
let useReducer _ s = (s, fun _ -> ())
let useReducerWithMapState _ s mapper = (mapper s, fun _ -> ())
let useEffect _ = ()
let useEffect0 _ = ()
let useEffect1 _ _ = ()
let useEffect2 _ _ = ()
let useEffect3 _ _ = ()
let useEffect4 _ _ = ()
let useEffect5 _ _ = ()
let useEffect6 _ _ = ()
let useLayoutEffect0 _ = ()
let useLayoutEffect1 _ _ = ()
let useLayoutEffect2 _ _ = ()
let useLayoutEffect3 _ _ = ()
let useLayoutEffect4 _ _ = ()
let useLayoutEffect5 _ _ = ()
let useLayoutEffect6 _ _ = ()

module Children = struct
  let map element fn =
    match element with
    | List children -> List.map fn children |> list
    | Array children -> Array.map fn children |> array
    | _ -> fn element

  let mapWithIndex element fn =
    match element with
    | List children -> List.mapi (fun index element -> fn element index) children |> list
    | Array children -> Array.mapi (fun index element -> fn element index) children |> array
    | _ -> fn element 0

  let forEach element fn =
    match element with
    | List children -> List.iter fn children
    | Array children -> Array.iter fn children
    | _ ->
        let _ = fn element in
        ()

  let forEachWithIndex element fn =
    match element with
    | List children -> List.iteri (fun index element -> fn element index) children
    | Array children -> Array.iteri (fun index element -> fn element index) children
    | _ ->
        let _ = fn element 0 in
        ()

  let count element =
    match element with
    | List children -> List.length children
    | Array children -> Array.length children
    | Empty -> 0
    | _ -> 1

  let only element =
    match element with
    | List (child :: _) -> child
    | List [] -> raise (Invalid_argument "Expected at least one child")
    | Array children ->
        if Array.length children >= 1 then Array.get children 0
        else raise (Invalid_argument "Expected at least one child")
    | _ -> element

  (* TODO: silly way to convert children to array, but isn't necessary in most cases *)
  let toArray element = [| element |]
end

let setDisplayName _ _ = ()
let useTransition () = (false, fun (_cb : unit -> unit) -> ())
let useDebugValue : 'value -> ?format:('value -> string) -> unit = fun[@warning "-16"] _ ?format:_ -> ()
let useDeferredValue value = value

(* `exception Suspend of 'a Lwt`
    exceptions can't have type params, this is called existential wrapper *)
type any_promise = Any_promise : 'a Lwt.t -> any_promise

exception Suspend of any_promise

let suspend promise = raise (Suspend (Any_promise promise))

module Experimental = struct
  let usePromise promise =
    match Lwt.state promise with
    | Sleep -> suspend promise
    (* TODO: Fail should raise a FailedSupense and catch at renderTo*? *)
    | Fail e -> raise e
    | Return v -> v
end
