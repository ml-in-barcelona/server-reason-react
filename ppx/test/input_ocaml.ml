(* ppx should not transform this *)
let rec pp_user = 2

(* ppx should not error on unrelated primitives with [] as pval_prim *)
type t = string [@@foo val f : int]

(* let%component *)

let%component make ?(name = "") = div [||] [ React.string ("Hello " ^ name) ]
let%component make ~children:(first, second) = div [||] [ first; second ]
let%component make ~children:kids = div [||] kids
let%component make ~children:(first, second) () = div [||] [ first; second ]
let%component make ?(name = "") = div [||] [ name ]
let%component make () = div [||] []
let%component make (type a) ~(foo : a) : _ = div [||] []
let%component make : type a. foo:a -> _ = fun ~foo:_ -> div [||] []

let%component make ~(bar : int option) =
  div [||] [ React.string (string_of_int (Option.value ~default:0 bar)) ] ()

external%component make :
  name:Js.js_string Js.t -> React.element
  = "require(\"my-react-library\").MyReactComponent"

external%component make :
  ?name:Js.js_string Js.t -> React.element
  = "require(\"my-react-library\").MyReactComponent"

external%component make :
  names:string array -> React.element
  = "require(\"my-react-library\").MyReactComponent"
