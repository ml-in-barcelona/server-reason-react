open Ppxlib

type mode = Handles | Interface | Registry

let mode = ref None
let source = ref None

let set_mode value =
  mode :=
    Some
      (match value with
      | "handles" -> Handles
      | "interface" -> Interface
      | "registry" -> Registry
      | _ -> invalid_arg "--mode must be handles, interface, or registry")

let () =
  Arg.parse
    [
      ("--mode", Arg.String set_mode, "generated artifact kind");
      ("--source", Arg.String (fun value -> source := Some value), "route manifest path for diagnostics");
    ]
    ignore "router-gen --mode <handles|interface|registry> --source <manifest>";
  let mode = match !mode with Some mode -> mode | None -> invalid_arg "--mode is required" in
  let source = match !source with Some source -> source | None -> invalid_arg "--source is required" in
  let lexbuf = Lexing.from_channel stdin in
  Location.init lexbuf source;
  let structure = Parse.implementation lexbuf in
  match Router_declaration.find structure with
  | None -> Location.raise_errorf "router: no top-level Router.make declaration found"
  | Some declaration -> (
      match mode with
      | Handles -> Router_expansion.handles declaration |> Pprintast.structure Format.std_formatter
      | Interface -> Router_expansion.signature declaration |> Pprintast.signature Format.std_formatter
      | Registry -> Router_expansion.registry declaration |> Pprintast.structure Format.std_formatter)
