open Ppxlib
module Builder = Ast_builder.Default

module Mel_module = struct
  type bundler = Webpack | Esbuild

  let bundler = ref Webpack
  let is_melange_attr { attr_name = { txt = attr } } = "mel.module" = attr
  let has_attr attrs = List.exists is_melange_attr attrs

  let asset_payload attrs =
    let attr =
      (* we use `find` directly even if it can raise, assuming `has_attr` has been called before *)
      List.find is_melange_attr attrs
    in
    match attr.attr_payload with
    | PStr
        [
          {
            pstr_desc =
              Pstr_eval
                ({ pexp_desc = Pexp_constant (Pconst_string (str, _, _)) }, _);
          };
        ]
      when String.length (Filename.extension str) > 0 ->
        Some str
    | _ -> None

  module Esbuild = struct
    (* This code is adapted from Esbuild hashing algorithm:
       base32: https://github.com/evanw/esbuild/blob/efa3dd2d8e895f7f9a9bef0d588560bbae7d776e/internal/bundler/bundler.go#L1174
       sum function: https://github.com/evanw/esbuild/blob/efa3dd2d8e895f7f9a9bef0d588560bbae7d776e/internal/xxhash/xxhash.go#L104
       the internal xxhash that esbuild uses is adapted from https://github.com/cespare/xxhash
    *)
    let hash_for_filename bytes =
      String.sub (Base32.encode_string (Bytes.to_string bytes)) 0 8

    let sum hex_str =
      (* Convert hexadecimal string to Int64 *)
      let int64_value = Int64.of_string ("0x" ^ hex_str) in

      (* Create an 8-byte buffer *)
      let bytes = Bytes.create 8 in

      (* Fill the buffer with the bytes of the Int64 value *)
      for i = 0 to 7 do
        let byte =
          Int64.(to_int (shift_right_logical int64_value (8 * (7 - i))))
          land 0xFF
        in
        Bytes.set bytes i (char_of_int byte)
      done;

      bytes

    let hash content =
      let hash = XXH64.hash content in
      let b = sum (XXH64.to_hex hash) in
      hash_for_filename b

    let filename ~base content =
      Filename.(chop_extension base ^ "-" ^ hash content ^ extension base)
  end

  (*
     (* For now, rspack doesn't support real content hashes, see https://github.com/web-infra-dev/rspack/issues/6606 *)
      module Rspack = struct
         (* This code is adapted from Rspack hashing algorithm:
            https://github.com/web-infra-dev/rspack/blob/0a5cf0ddf38d41c2cad58c95ee9c1d3bd95e377f/crates/rspack_hash/src/lib.rs
         *)
         let hex_to_little_endian hex_str =
           (* Split the hex string into byte pairs *)
           let rec split_into_bytes acc i =
             if i >= String.length hex_str then List.rev acc
             else
               let byte = String.sub hex_str i 2 in
               split_into_bytes (byte :: acc) (i + 2)
           in
           (* Join byte pairs into a single string *)
           let join_bytes bytes = String.concat "" bytes in
           (* Perform the transformation *)
           let bytes = split_into_bytes [] 0 in
           let reversed_bytes = List.rev bytes in
           join_bytes reversed_bytes

         let hash content =
           let open XXHash in
           let hash = XXH3_64.hash content in
           hex_to_little_endian (XXH3_64.to_hex hash)
       end *)
  module Webpack = struct
    (* Needs following config in webpack.config.js, see https://webpack.js.org/configuration/output/#outputhashfunction
       ```
       module.exports = {
         //...
         output: {
           hashFunction: 'xxhash64',
         },
       };
       ```
       Also needs to set `realContentHash` for it to work in dev mode (see https://webpack.js.org/configuration/optimization/#optimizationrealcontenthash):
       ```
       module.exports = {
         //...
         optimization: {
           realContentHash: false,
         },
       };
       ```
    *)
    let hash content =
      let hash = XXH64.hash content in
      XXH64.to_hex hash

    let filename ~base content = hash content ^ Filename.extension base
  end
end

let is_send_pipe pval_attributes =
  List.exists
    (fun { attr_name = { txt = attr } } -> String.equal attr "mel.send.pipe")
    pval_attributes

let get_function_name pattern =
  let rec go pattern =
    match pattern with
    | Ppat_var { txt = name; _ } -> Some name
    | Ppat_constraint (pattern, _) -> go pattern.ppat_desc
    | _ -> None
  in
  go pattern

let get_label = function
  | Ptyp_constr ({ txt = Lident label; _ }, _) -> Some label
  | _ -> None

(* Extract the `t` from [@mel.send.pipe: t] *)
let get_send_pipe pval_attributes =
  if is_send_pipe pval_attributes then
    let first_attribute = List.hd pval_attributes in
    match first_attribute.attr_payload with
    | PTyp core_type -> Some core_type
    | _ -> None
  else None

let has_ptyp_attribute ptyp_attributes attribute =
  List.exists
    (fun { attr_name = { txt = attr } } -> attr = attribute)
    ptyp_attributes

let is_mel_as core_type =
  match core_type with
  | { ptyp_desc = Ptyp_any; ptyp_attributes; _ } ->
      has_ptyp_attribute ptyp_attributes "mel.as"
  | _ -> false

let extract_args_labels_types acc pval_type =
  let rec go acc = function
    (* In case of being mel.as, ignore those *)
    | { ptyp_desc = Ptyp_arrow (_label, t1, _t2); _ } when is_mel_as t1 -> acc
    | { ptyp_desc = Ptyp_arrow (_label, _t1, t2); _ } when is_mel_as t2 -> acc
    | { ptyp_desc = Ptyp_arrow (_label, t1, t2); _ }
      when is_mel_as t1 && is_mel_as t2 ->
        acc
    | { ptyp_desc = Ptyp_arrow (label, t1, t2); _ } ->
        let pattern =
          Builder.ppat_var ~loc:t1.ptyp_loc { loc = t1.ptyp_loc; txt = "_" }
        in
        go ((label, pattern, t1) :: acc) t2
    | _ -> acc
  in
  go acc pval_type

(* Insert send_pipe_core_type as a last argument of the function, but not the return type *)
let construct_pval_with_send_pipe send_pipe_core_type pval_type =
  let rec insert_core_type_in_arrow core_type =
    match core_type with
    (* Handle only ptyp and constr.
       Missing `| Ptyp_any | Ptyp_var | Ptyp_arrow | Ptyp_tuple | Ptyp_constr
                | Ptyp_object | Ptyp_class | Ptyp_alias | Ptyp_variant
                | Ptyp_poly | Ptyp_package | Ptyp_extension`
       The aren't used in most bindings.
    *)
    | { ptyp_desc = Ptyp_arrow (label, t1, t2); _ } -> (
        match (t1.ptyp_desc, t2.ptyp_desc) with
        (* `constr -> arrow (constr -> constr)` gets transformed into
           `constr -> constr -> t -> constr` *)
        | Ptyp_constr _, Ptyp_arrow (_inner_label, _p1, _p2) ->
            Builder.ptyp_arrow ~loc:t1.ptyp_loc label t1
              (insert_core_type_in_arrow t2)
        (* `constr -> constr` gets transformed into `constr -> t -> constr` *)
        (* `arrow (constr -> constr) -> constr` gets transformed into,
            `arrow (constr -> constr) -> t -> constr` *)
        | _, _ ->
            Builder.ptyp_arrow ~loc:t2.ptyp_loc label t1
              (Builder.ptyp_arrow ~loc:t2.ptyp_loc Nolabel send_pipe_core_type
                 t2))
    (* In case of being a single ptyp_* turn into ptyp_* -> t *)
    | { ptyp_desc = Ptyp_constr ({ txt = _; loc }, _); _ }
    | { ptyp_desc = Ptyp_var _; ptyp_loc = loc; _ } ->
        Builder.ptyp_arrow ~loc Nolabel core_type send_pipe_core_type
    (* Here we ignore the Ptyp_any *)
    | _ -> core_type
  in
  insert_core_type_in_arrow pval_type

let inject_send_pipe_as_last_argument pipe_type args_labels =
  match pipe_type with
  | None -> args_labels
  | Some pipe_core_type -> pipe_core_type :: args_labels

let is_mel_raw expr =
  match expr with
  | Pexp_extension ({ txt = "mel.raw"; _ }, _) -> true
  | _ -> false

let capture_payload expr =
  match expr with
  | PStr
      [
        {
          pstr_desc =
            Pstr_eval
              ( { pexp_desc = Pexp_constant (Pconst_string (payload, _, _)); _ },
                _ );
          _;
        };
      ] ->
      payload
  | _ -> "..."

let get_payload_from_mel_raw expr =
  let rec go expr =
    match expr with
    | Pexp_extension ({ txt = "mel.raw"; _ }, pstr) -> capture_payload pstr
    | Pexp_constraint (expr, _) -> go expr.pexp_desc
    | Pexp_fun (_, _, _, expr) -> go expr.pexp_desc
    | _ -> "..."
  in
  go expr

let expression_has_mel_raw expr =
  let rec go expr =
    match expr with
    | Pexp_extension ({ txt = "mel.raw"; _ }, _) as pexp_desc ->
        is_mel_raw pexp_desc
    | Pexp_constraint (expr, _) -> is_mel_raw expr.pexp_desc
    | Pexp_fun (_, _, _, expr) -> go expr.pexp_desc
    | _ -> false
  in
  go expr

let raise_failure ~loc name =
  [%expr
    let () =
      Printf.printf
        {|
There is a Melange's external (for example: [@mel.get]) call from native code.

Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
|}
    in
    raise
      (Runtime.fail_impossible_action_in_ssr
         [%e Builder.pexp_constant ~loc (Pconst_string (name, loc, None))])]

let mel_raw_found_in_native_message ~loc payload =
  let msg =
    Printf.sprintf
      "[server-reason-react.melange_ppx] There's a [%%mel.raw \"%s\"] \
       expression in native, which should only happen in JavaScript. You need \
       to conditionally run it via let%%browser_only or switch%%platform. More \
       info at \
       https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html"
      payload
  in
  Builder.pexp_constant ~loc (Pconst_string (msg, loc, None))

let mel_module_found_in_native_message ~loc =
  let msg =
    Printf.sprintf
      "[server-reason-react.melange_ppx] There's an external with \
       [%%mel.module \"...\"] in native, which should only happen in \
       JavaScript. You need to conditionally run it, either by not including \
       it on native or via let%%browser_only/switch%%platform. More info at \
       https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html"
  in
  Builder.pexp_constant ~loc (Pconst_string (msg, loc, None))

let external_found_in_native_message ~loc =
  let msg =
    Printf.sprintf
      "[server-reason-react.melange_ppx] There's an external in native, which \
       should only happen in JavaScript. You need to conditionally run it, \
       either by not including it on native or via \
       let%%browser_only/switch%%platform. More info at \
       https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html"
  in
  Builder.pexp_constant ~loc (Pconst_string (msg, loc, None))

let get_function_arity pattern =
  let rec go arity = function
    | Pexp_fun (_, _, _, expr) -> go (arity + 1) expr.pexp_desc
    | _ -> arity
  in
  go 0 pattern

let transform_external_arrow ~loc pval_name pval_attributes pval_type =
  let pipe_type =
    match get_send_pipe pval_attributes with
    | Some core_type ->
        let pattern =
          Builder.ppat_var ~loc:core_type.ptyp_loc
            { loc = core_type.ptyp_loc; txt = "_" }
        in
        Some (Nolabel, pattern, core_type)
    | None -> None
  in
  let args_labels_types = extract_args_labels_types [] pval_type in
  let function_core_type =
    Builder.ppat_var ~loc:pval_name.loc
      { loc = pval_name.loc; txt = pval_name.txt }
  in
  let pval_type_piped =
    match pipe_type with
    | None -> pval_type
    | Some (_, _, pipe_type) ->
        construct_pval_with_send_pipe pipe_type pval_type
  in
  let pat =
    Builder.ppat_constraint ~loc:pval_type.ptyp_loc function_core_type
      (Builder.ptyp_poly ~loc:pval_type.ptyp_loc [] pval_type_piped)
  in
  let arg_labels =
    inject_send_pipe_as_last_argument pipe_type args_labels_types
  in
  let function_expression =
    List.fold_left
      (fun acc (label, arg_pat, arg_type) ->
        Builder.pexp_fun ~loc:arg_type.ptyp_loc label None arg_pat acc)
      (raise_failure ~loc:pval_type.ptyp_loc pval_name.txt)
      arg_labels
  in
  let vb = Builder.value_binding ~loc ~pat ~expr:function_expression in
  Ast_helper.Str.value Nonrecursive [ vb ]

let ptyp_humanize = function
  | Ptyp_tuple _ -> "Tuples"
  | Ptyp_object _ -> "Objects"
  | Ptyp_class _ -> "Classes"
  | Ptyp_variant _ -> "Variants"
  | Ptyp_extension _ -> "Extensions"
  | Ptyp_alias _ -> "Alias"
  | Ptyp_poly _ -> "Polyvariants"
  | Ptyp_package _ -> "Packages"
  | Ptyp_any -> "Any"
  | Ptyp_var _ -> "Var"
  | Ptyp_arrow _ -> "Arrow"
  | Ptyp_constr _ -> "Constr"

let transform_external ~module_path pval_name pval_attributes pval_loc pval_type
    =
  let loc = pval_loc in
  match pval_type.ptyp_desc with
  | Ptyp_arrow _ ->
      transform_external_arrow ~loc pval_name pval_attributes pval_type
  | Ptyp_var _ | Ptyp_any | Ptyp_constr _ ->
      (* When mel.send.pipe is used, it's treated as a funcion *)
      if Option.is_some (get_send_pipe pval_attributes) then
        transform_external_arrow ~loc pval_name pval_attributes pval_type
      else if Mel_module.has_attr pval_attributes then
        match Mel_module.asset_payload pval_attributes with
        | None ->
            (* If it doesn't have asset payload, we error out as it must be some .js module or package being imported *)
            [%stri [%%ocaml.error [%e mel_module_found_in_native_message ~loc]]]
        | Some str ->
            (* If it has asset payload (file with extension), calculate hash and replace external *)
            let name = Builder.pvar ~loc:pval_name.loc pval_name.txt in
            let path =
              let asset_path = Filename.(concat (dirname module_path) str) in
              (* todo: maybe read line by line of buffered for large files *)
              let ic = open_in asset_path in
              let n = in_channel_length ic in
              let s = really_input_string ic n in
              close_in ic;
              let filename_fn =
                match !Mel_module.bundler with
                | Webpack -> Mel_module.Webpack.filename
                | Esbuild -> Mel_module.Esbuild.filename
              in
              let prefix = (* todo: read from config *) "/" in
              Builder.estring ~loc
                Filename.(
                  concat prefix (filename_fn ~base:(Filename.basename str) s))
            in
            [%stri let [%p name] = [%e path]]
      else [%stri [%%ocaml.error [%e external_found_in_native_message ~loc]]]
  | _ ->
      [%stri
        [%%ocaml.error
        "[server-reason-react.melange_ppx] %s are not supported in native \
         externals the same way as melange.ppx support them."
          (ptyp_humanize pval_type.ptyp_desc)]]

let tranform_record_to_object ~loc record =
  let fields =
    List.map
      (fun (label, expression) ->
        Builder.pcf_method ~loc
          ( Builder.Located.mk label ~loc,
            Public,
            Cfk_concrete (Fresh, expression) ))
      record
  in
  Builder.pexp_object ~loc
    (Builder.class_structure ~self:(Builder.ppat_any ~loc) ~fields)

let validate_record_labels ~loc record =
  List.fold_left
    (fun acc (longident, expression) ->
      match acc with
      | Error _ as error -> error
      | Ok acc -> (
          match longident.txt with
          | Lident label -> Ok ((label, expression) :: acc)
          | Ldot _ | Lapply _ ->
              Error
                (Location.error_extensionf ~loc
                   "[server-reason-react.melange_ppx] Js.t objects only \
                    support labels as keys")))
    (Ok []) record

class raise_exception_mapper (module_path : string) =
  object (_self)
    inherit Ast_traverse.map as super

    method! expression expr =
      match expr.pexp_desc with
      | Pexp_extension
          ( { txt = "mel.obj"; _ },
            PStr
              [
                {
                  pstr_desc =
                    Pstr_eval
                      ({ pexp_desc = Pexp_record (record, None); pexp_loc }, _);
                  _;
                };
              ] ) -> (
          match validate_record_labels ~loc:pexp_loc record with
          | Ok record -> tranform_record_to_object ~loc:pexp_loc record
          | Error extension -> Builder.pexp_extension ~loc:pexp_loc extension)
      | Pexp_extension ({ txt = "mel.obj"; loc }, _) ->
          Builder.pexp_extension ~loc
            (Location.error_extensionf ~loc:expr.pexp_loc
               "[server-reason-react.melange_ppx] Js.t objects requires a \
                record literal")
      | _ -> super#expression expr

    method! structure_item item =
      match item.pstr_desc with
      (* [%%mel.raw ...] *)
      | Pstr_extension (({ txt = "mel.raw"; _ }, pstr), _) ->
          let loc = item.pstr_loc in
          let payload = capture_payload pstr in
          [%stri
            [%%ocaml.error [%e mel_raw_found_in_native_message ~loc payload]]]
      (* let a _ = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr =
                  {
                    pexp_desc =
                      Pexp_fun
                        (_arg_label, _arg_expression, _fun_pattern, expression);
                  };
                pvb_pat = { ppat_desc = Ppat_var { txt = _function_name; _ } };
                pvb_attributes = _;
                pvb_loc;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let payload = get_payload_from_mel_raw expression.pexp_desc in
          [%stri
            [%error [%e mel_raw_found_in_native_message ~loc:pvb_loc payload]]]
      (* let a = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr = expression;
                pvb_pat = { ppat_desc = Ppat_var { txt = _function_name; _ } };
                pvb_attributes = _;
                pvb_loc;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let payload = get_payload_from_mel_raw expression.pexp_desc in
          [%stri
            [%error [%e mel_raw_found_in_native_message ~loc:pvb_loc payload]]]
      (* let a: t = [%mel.raw ...] *)
      | Pstr_value
          ( Nonrecursive,
            [
              {
                pvb_expr = expression;
                pvb_pat = { ppat_desc = _ };
                pvb_attributes = _;
                pvb_loc;
              };
            ] )
        when expression_has_mel_raw expression.pexp_desc ->
          let loc = item.pstr_loc in
          let payload = get_payload_from_mel_raw expression.pexp_desc in
          [%stri
            [%error [%e mel_raw_found_in_native_message ~loc:pvb_loc payload]]]
      (* %mel. *)
      (* external foo: t = "{{JavaScript}}" *)
      | Pstr_primitive { pval_name; pval_attributes; pval_loc; pval_type } ->
          transform_external ~module_path pval_name pval_attributes pval_loc
            pval_type
      | _ -> super#structure_item item
  end

let structure_mapper ctxt s =
  let module_path =
    Code_path.file_path (Expansion_context.Base.code_path ctxt)
  in
  (new raise_exception_mapper module_path)#structure s

module Debug = struct
  let rule =
    let extractor = Ast_pattern.(__') in
    let handler ~ctxt:_ { loc } = [%expr ()] in
    Context_free.Rule.extension
      (Extension.V3.declare "debug" Extension.Context.expression extractor
         handler)
end

let () =
  Driver.add_arg "-bundler"
    (String
       (fun str ->
         match str with
         | "webpack" -> Mel_module.bundler := Webpack
         | "esbuild" -> Mel_module.bundler := Esbuild
         | _ ->
             failwith
               (Printf.sprintf
                  {|Unknown value %S passed as -bundler flag in melange.ppx, valid values: "webpack", "esbuild"|}
                  str)))
    ~doc:
      "generate paths to assets in mel.module using the file name scheme of \
       the bundler of choice";
  Driver.V2.register_transformation ~impl:structure_mapper
    ~rules:[ Pipe_first.rule; Regex.rule; Double_hash.rule; Debug.rule ]
    "melange-native-ppx"
