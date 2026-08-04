open Ppxlib

let () =
  let lexbuf = Lexing.from_channel stdin in
  Location.init lexbuf "Router.re";
  let structure = Parse.implementation lexbuf in
  match Router_declaration.find structure with
  | None -> Location.raise_errorf "router: no top-level Router.make declaration found"
  | Some declaration -> Router_expansion.signature declaration |> Pprintast.signature Format.std_formatter
