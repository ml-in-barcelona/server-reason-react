open Ppxlib
module Builder = Ast_builder.Default

let parse_re str =
  try
    let _ = Str.search_forward (Str.regexp "/\\(.*\\)/\\(.*\\)") str 0 in
    let first = Str.matched_group 1 str in
    let second = Str.matched_group 2 str in
    if String.length second = 0 then Some (first, None)
    else Some (first, Some second)
  with Not_found -> None

let rule =
  let context = Extension.Context.expression in
  let extractor = Ast_pattern.(__') in
  let handler ~ctxt:_ ({ txt = payload; loc } : Ppxlib.Parsetree.payload loc) =
    match payload with
    | PStr [ { pstr_desc = Pstr_eval (expression, _); _ } ] -> (
        match expression.pexp_desc with
        | Pexp_constant (Pconst_string (str, location, _delimiter)) -> (
            let regex', flags' =
              match parse_re str with
              | Some (regex, flags) -> (regex, flags)
              | None ->
                  Location.raise_errorf ~loc:location
                    "invalid regex: %s, expected /regex/flags" str
            in
            let regex = Builder.estring ~loc:location regex' in
            match flags' with
            | None -> [%expr Js.Re.fromString [%e regex]]
            | Some flags' ->
                let flags = Builder.estring ~loc:location flags' in
                [%expr Js.Re.fromStringWithFlags ~flags:[%e flags] [%e regex]])
        | _ ->
            Builder.pexp_extension ~loc
            @@ Location.error_extensionf ~loc
                 "payload should be a string literal")
    | _ ->
        Builder.pexp_extension ~loc
        @@ Location.error_extensionf ~loc
             "[%%re] should be used with an expression"
  in
  let extension = Extension.V3.declare "re" context extractor handler in
  Context_free.Rule.extension extension

let () = Driver.V2.register_transformation "regex" ~rules:[ rule ]
