type t = private Ojs.t

val t_of_js : Ojs.t -> t
val t_to_js : t -> Ojs.t
val make : html:string -> t [@@js.new "__LIB__jsdom"]

[@@@js.stop]

type window = Js_of_ocaml.Dom_html.window Js_of_ocaml.Js.t

[@@@js.start]

[@@@js.implem
type window = Js_of_ocaml.Dom_html.window Js_of_ocaml.Js.t

external window_of_js : t -> window = "%identity"
external window_to_js : window -> t = "%identity"]

val window : t -> window [@@js.get]

[@@@js.stop]

type document = Js_of_ocaml.Dom_html.document Js_of_ocaml.Js.t

[@@@js.start]

[@@@js.implem
type document = Js_of_ocaml.Dom_html.document Js_of_ocaml.Js.t

external document_of_js : t -> document = "%identity"
external document_to_js : document -> t = "%identity"]

val document : window -> document [@@js.get]
