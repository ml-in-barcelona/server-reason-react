type react = Ojs.t
type react_dom = Ojs.t

let react_to_js v = v
let react_dom_to_js v = v
let react : react = Js_of_ocaml.Js.Unsafe.js_expr {|require("react")|}

let react_dom : react_dom =
  Js_of_ocaml.Js.Unsafe.js_expr {|require("react-dom")|}
