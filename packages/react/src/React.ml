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
    (* Action prop makes difference between a action as a string and a action as a server action *)
    (* (name, jsxName, action_id) *)
    | Action : (string * string * 'f Runtime.React.server_function) -> prop
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

type element =
  | Lower_case_element of { key : string option; tag : string; attributes : JSX.prop list; children : element list }
  | Upper_case_component of string * (unit -> element)
  | Async_component of (unit -> element Lwt.t)
  | Client_component of { props : client_props; client : element; import_module : string; import_name : string }
  | List of element list
  | Array of element array
  | Text of string
  | InnerHtml of string
  | Fragment of element
  | Empty
  | Provider of element
  | Consumer of element
  | Suspense of { key : string option; children : element; fallback : element }

and client_props = (string * client_value) list

and client_value =
  (* TODO: Do we need to add more types here? *)
  | Function : 'f Runtime.React.server_function -> client_value
  | Json : Yojson.Basic.t -> client_value
  | Element : element -> client_value
  | Promise : 'a Js.Promise.t * ('a -> Yojson.Basic.t) -> client_value

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
      | Style _ -> acc
      | Action _ -> acc)
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

let create_element_with_key ?(key = None) tag attributes children =
  match Html.is_self_closing_tag tag with
  | true when List.length children > 0 ->
      (* TODO: Add test for this *)
      raise (Invalid_children "closing tag with children isn't valid")
  | true -> Lower_case_element { key; tag; attributes; children = [] }
  | false -> Lower_case_element { key; tag; attributes; children }

let createElement = create_element_with_key ~key:None
let createElementWithKey = create_element_with_key

(* `cloneElement` overrides childrens and props on lower case components, It raises Invalid_argument for the rest.
    React.js can clone uppercase components, since it stores their props on each element's object but since we just store the fn and don't have the props, we can't clone them).
   TODO: Check original implementation for exact error message/exception type *)
let cloneElement element new_attributes =
  match element with
  | Lower_case_element { key; tag; attributes; children } ->
      Lower_case_element { key; tag; attributes = clone_attributes attributes new_attributes; children }
  | Upper_case_component _ -> raise (Invalid_argument "In server-reason-react, a component can't be cloned")
  | Fragment _ -> raise (Invalid_argument "can't clone a fragment")
  | Text _ -> raise (Invalid_argument "can't clone a text element")
  | InnerHtml _ -> raise (Invalid_argument "can't clone a dangerouslySetInnerHTML element")
  | Empty -> raise (Invalid_argument "can't clone a null element")
  | List _ -> raise (Invalid_argument "can't clone a list element")
  | Array _ -> raise (Invalid_argument "can't clone an array element")
  | Provider _ -> raise (Invalid_argument "can't clone a Provider")
  | Consumer _ -> raise (Invalid_argument "can't clone a Consumer")
  | Async_component _ -> raise (Invalid_argument "can't clone an async component")
  | Suspense _ -> raise (Invalid_argument "can't clone a Supsense component")
  | Client_component _ -> raise (Invalid_argument "can't clone a Client component")

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
type 'a context = { current_value : 'a ref; provider : 'a provider; consumer : children:element -> element }

module Context = struct
  type 'a t = 'a context

  let provider ctx = ctx.provider
end

let createContext (initial_value : 'a) : 'a Context.t =
  let ref_value = { current = initial_value } in
  let provider ~value ~children () =
    ref_value.current <- value;
    Provider children
  in
  let consumer ~children = Consumer children in
  { current_value = ref_value; provider; consumer }

module Suspense = struct
  let or_react_null = function None -> null | Some x -> x

  let make ?(key = None) ?fallback ?children () =
    Suspense { key; fallback = or_react_null fallback; children = or_react_null children }
end

(* let memo f : 'props * 'props -> bool = f
   let memoCustomCompareProps f _compare : 'props * 'props -> bool = f *)

let useContext context = context.current_value.current

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
let internal_id = ref 0

let useId () =
  internal_id := !internal_id + 1;
  Int.to_string !internal_id

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
let useDebugValue : 'value -> ?format:('value -> string) -> unit = fun [@warning "-16"] _ ?format:_ -> ()
let useDeferredValue value = value

(* `exception Suspend of 'a Lwt`
    exceptions can't have type params, this is called existential wrapper *)
type any_promise = Any_promise : 'a Lwt.t -> any_promise

exception Suspend of any_promise

let suspend promise = raise (Suspend (Any_promise promise))

module Experimental = struct
  let use promise =
    match Lwt.state promise with
    | Sleep -> suspend promise
    (* TODO: Fail should raise a FailedSupense and catch at renderTo*? *)
    | Fail e -> raise e
    | Return v -> v
end
