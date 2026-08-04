open Ppxlib

type mode = Handles | Registry

let mode = ref None

let set_mode value =
  mode :=
    Some
      (match value with
      | "handles" -> Handles
      | "registry" -> Registry
      | _ -> invalid_arg "--mode must be handles or registry")

let () =
  Arg.parse
    [ ("--mode", Arg.String set_mode, "generated source kind") ]
    ignore "router-source-gen --mode <handles|registry>";
  let mode = match !mode with Some mode -> mode | None -> invalid_arg "--mode is required" in
  let lexbuf = Lexing.from_channel stdin in
  Location.init lexbuf "RouterDefinition.re";
  let structure = Parse.implementation lexbuf in
  match Router_declaration.find structure with
  | None -> Location.raise_errorf "router: no top-level Router.make declaration found"
  | Some declaration ->
      let generated =
        match mode with
        | Handles -> Router_expansion.handles declaration
        | Registry -> Router_expansion.registry declaration
      in
      Pprintast.structure Format.std_formatter generated
