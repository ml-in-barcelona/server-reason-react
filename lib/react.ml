type domRef

module Ref = struct
  type t = domRef
  type currentDomRef (*  = React.ref(Js.nullable(Dom.element)); *)
  type callbackDomRef (*  = Js.nullable(Dom.element) => unit; *)
end

let createRef () = ref None
let useRef value = ref value
let forwardRef f = f ()

(* Self referencing modules to have recursive type records without collission *)
module rec Element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    ; children : Node.t list
    }
end =
  Element

and Closed_element : sig
  type t =
    { tag : string
    ; attributes : Attribute.t array
    }
end =
  Closed_element

and Node : sig
  type t =
    | Element of Element.t
    | Closed_element of Closed_element.t
    | Component of (unit -> t)
    | Text of string
    | Fragment of t list
    | Empty
    | Provider of (unit -> t) list
    | Consumer of (unit -> t list)
end =
  Node

and Attribute : sig
  type t =
    | Bool of (string * bool)
    | String of (string * string)
    | Style of (string * string) list
    | DangerouslyInnerHtml of string
    | Ref of Ref.t
end =
  Attribute

let is_self_closing_tag = function
  | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
  | "meta" | "param" | "source" | "track" | "wbr" ->
      true
  | _ -> false

exception Invalid_children of string

let compare_attribute left right =
  let open Attribute in
  match (left, right) with
  | Bool (left_key, _), Bool (right_key, _) -> String.compare left_key right_key
  | String (left_key, _), String (right_key, _) ->
      String.compare left_key right_key
  | Style left_styles, Style right_styles ->
      List.compare
        (fun (a, va) (b, vb) -> String.compare a b + String.compare va vb)
        left_styles right_styles
  | _ -> 0

let clone_attribute acc attr new_attr =
  let open Attribute in
  match (attr, new_attr) with
  | Bool (left, _), Bool (right, value) when left == right ->
      Bool (left, value) :: acc
  | String (left, _), String (right, value) when left == right ->
      String (left, value) :: acc
  | _ -> new_attr :: acc

module StringMap = Map.Make (String)

type attributes = Attribute.t StringMap.t

let attributes_to_map attrs =
  Array.fold_left
    (fun acc attr ->
      match attr with
      | Attribute.Bool (key, value) ->
          acc |> StringMap.add key (Attribute.Bool (key, value))
      | Attribute.String (key, value) ->
          acc |> StringMap.add key (Attribute.String (key, value))
      | Attribute.DangerouslyInnerHtml _ -> acc
      | Attribute.Ref _ -> acc
      | Attribute.Style _ -> acc)
    StringMap.empty attrs

let clone_attributes (attributes : 'a array) new_attributes =
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
  |> List.flatten |> List.rev
  |> List.sort compare_attribute
  |> Array.of_list

let createElement tag attributes children =
  match is_self_closing_tag tag with
  | true when List.length children > 0 ->
      (* TODO: Add test for this *)
      (* Q: should raise or return monad? *)
      raise @@ Invalid_children "closing tag with children isn't valid"
  | true -> Node.Closed_element { tag; attributes }
  | false -> Node.Element { tag; attributes; children }

(* cloneElements overrides childrens *)
let cloneElement element new_attributes new_childrens =
  let open Node in
  match element with
  | Element { tag; attributes; children = _ } ->
      Element
        { tag
        ; attributes = clone_attributes attributes new_attributes
        ; children = new_childrens
        }
  | Closed_element { tag; attributes } ->
      Closed_element
        { tag; attributes = clone_attributes attributes new_attributes }
  | Fragment _childrens -> Fragment new_childrens
  | Text t -> Text t
  | Empty -> Empty
  (* FIXME: How does cloneElement does with Provider/Consumer *)
  | Provider child -> Provider child
  | Consumer child -> Consumer child
  | Component f -> Component f

(* let currentDispatcher = ref dispacher *)
(* HooksDispatcherOnUpdateInDEV *)

type 'a context =
  { current_value : 'a ref
  ; provider : value:'a -> children:(unit -> Node.t) list -> Node.t
  ; consumer : children:('a -> Node.t list) -> Node.t
  }

let createContext (initial_value : 'a) : 'a context =
  let ref_value = ref initial_value in
  let provider ~value ~children =
    ref_value.contents <- value;
    Node.Provider children
  in
  let consumer ~children =
    Node.Consumer (fun () -> children ref_value.contents)
  in
  { current_value = ref_value; provider; consumer }

let useContext context = context.current_value.contents

let useState f_initial_value =
  let setState _ = () in
  (f_initial_value (), setState)

let useStateValue initial_value =
  let setState _ = () in
  (initial_value, setState)

let useMemo fn = fn ()
let useMemo1 fn _ = fn ()
let useMemo2 fn _ = fn ()
let useMemo3 fn _ = fn ()
let useMemo4 fn _ = fn ()
let useMemo5 fn _ = fn ()
let useMemo6 fn _ = fn ()
let useCallback fn = fn
let useCallback1 fn _ = fn
let useCallback2 fn _ = fn
let useCallback3 fn _ = fn
let useCallback4 fn _ = fn
let useCallback5 fn _ = fn
let useCallback6 (fn : 'a -> 'b) = fn

let useReducer :
    ('state -> 'action -> 'state) -> 'state -> 'state * ('action -> unit) =
 fun _ s -> (s, fun _ -> ())

let useEffect0 : (unit -> (unit -> unit) option) -> unit = fun _ -> ()

let useEffect1 : (unit -> (unit -> unit) option) -> 'dependency array -> unit =
 fun _ _ -> ()

let useEffect2 :
    (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit =
 fun _ _ -> ()

let useEffect3 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3
    -> unit =
 fun _ _ -> ()

let useEffect4 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4
    -> unit =
 fun _ _ -> ()

let useEffect5 :
       (unit -> (unit -> unit) option)
    -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4 * 'dependency5
    -> unit =
 fun _ _ -> ()

let useEffect6 :
       (unit -> (unit -> unit) option)
    -> 'dependency1
       * 'dependency2
       * 'dependency3
       * 'dependency4
       * 'dependency5
       * 'dependency6
    -> unit =
 fun _ _ -> ()

(* ReasonReact APIs *)
let string txt = Node.Text txt
let null = Node.Empty
let int i = Node.Text (string_of_int i)

(* FIXME: float_of_string might be different on the browser *)
let float f = Node.Text (string_of_float f)
