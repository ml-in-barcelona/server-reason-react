[@@@js.stop]

type undefined
type element
type 'a node_list = 'a Js_of_ocaml.Dom.nodeList

val node_list_of_js : (Ojs.t -> 'value) -> Ojs.t -> 'value node_list
val node_list_to_js : ('value -> Ojs.t) -> 'value node_list -> Ojs.t
val unsafe_to_element : 'a Js_of_ocaml.Js.t -> element

[@@@js.start]

[@@@js.implem
type undefined = Ojs.t

let undefined = Ojs.variable "undefined"
let undefined_to_js x = x
let undefined_of_js x = x

type element = Js_of_ocaml.Dom_html.element

external element_of_js : Ojs.t -> Js_of_ocaml.Dom_html.element = "%identity"
external element_to_js : Js_of_ocaml.Dom_html.element -> Ojs.t = "%identity"

type 'a node_list = 'a Js_of_ocaml.Dom.nodeList

external node_list_of_ojs : Ojs.t -> 'value node_list = "%identity"
external node_list_to_js : 'value node_list -> Ojs.t = "%identity"

let node_list_of_js _f x = node_list_of_ojs x
let node_list_to_js _f x = node_list_to_js x

external unsafe_to_element : 'a Js_of_ocaml.Js.t -> element = "%identity"]

val act : (unit -> unit) -> unit
  [@@js.custom
    val act : (unit -> undefined) -> unit
      [@@js.global "__LIB__reactDOMTestUtils.act"]

    let act f =
      act (fun () ->
          f ();
          undefined)]

module Simulate : sig
  val click : element -> unit
    [@@js.global "__LIB__reactDOMTestUtils.Simulate.click"]
end

val querySelectorAll : element -> string -> element array
  [@@js.custom
    val querySelectorAll : element -> string -> element node_list [@@js.call]

    val arrayFrom : element node_list -> element array
      [@@js.global "Array.from"]

    let querySelectorAll element selector =
      arrayFrom (querySelectorAll element selector)]

module DOM : sig
  val findBySelectorAndPartialTextContent :
    element -> string -> string -> element
    [@@js.custom
      let find f a =
        let rec find a f n = if f a.(n) then a.(n) else find a f (n + 1) in
        find a f 0

      val textContent : element -> string [@@js.get]
      val includes : string -> string -> bool [@@js.call]

      let findBySelectorAndPartialTextContent element selector content =
        querySelectorAll element selector
        |> find (fun node -> textContent node |> includes content)]
end
