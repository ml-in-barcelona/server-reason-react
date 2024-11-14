open Ppxlib
module Builder = Ast_builder.Default

let parse_re str =
  try
    let _ = Str.search_forward (Str.regexp "/\\(.*\\)/\\(.*\\)") str 0 in
    let first = Str.matched_group 1 str in
    let second = Str.matched_group 2 str in
    match String.length second with 0 -> Ok (first, None) | _ -> Ok (first, Some second)
  with Not_found -> Error "invalid regex"

let extractor = Ast_pattern.(__')

let handler ~ctxt:_ ({ txt = payload; loc } : Ppxlib.Parsetree.payload loc) =
  match payload with
  | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
      match expression.pexp_desc with
      | Pexp_constant (Pconst_string (str, location, _delimiter)) -> (
          match parse_re str with
          | Ok (regex, flags) -> (
              let regex = Builder.estring ~loc:location regex in
              match flags with
              | None -> [%expr Js.Re.fromString [%e regex]]
              | Some flags' ->
                  let flags = Builder.estring ~loc:location flags' in
                  [%expr Js.Re.fromStringWithFlags ~flags:[%e flags] [%e regex]])
          | Error err ->
              Builder.pexp_extension ~loc
                (Location.error_extensionf ~loc:location "[server-reason-react.melange_ppx] invalid regex: %s,\n%s" err
                   str))
      | _ ->
          Builder.pexp_extension ~loc
            (Location.error_extensionf ~loc "[server-reason-react.melange_ppx] payload should be a string literal"))
  | _ ->
      Builder.pexp_extension ~loc
        (Location.error_extensionf ~loc
           "[server-reason-react.melange_ppx] [%%re] extension should have an expression as payload")

let rule =
  let extension = Extension.V3.declare "mel.re" Extension.Context.expression extractor handler in
  Context_free.Rule.extension extension
