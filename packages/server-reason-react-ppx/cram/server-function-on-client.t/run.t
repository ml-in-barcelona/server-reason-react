  $ cat > ReactServerDOMEsbuild.re << EOF
  > [@mel.module "./ReactServerDOMEsbuild.js"]
  > external createServerReference: (string) => 'action = "createServerReference";
  > EOF

  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries server-reason-react.runtime reason-react server-reason-react.rsc melange-json)
  >  (preprocess (pps reason-react-ppx melange.ppx server-reason-react.rsc.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > 
  > (rule
  >  (deps (alias melange))
  >  (target boostrap.js)
  >   (action
  >    (progn
  >     (with-stdout-to %{target}
  >      (run server-reason-react.extract_client_components js)))))
  > EOF

  $ dune build

  $ ../dune-describe-pp.sh input.re | sed '/\[@mel.internal.ffi/,/\]/d'
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function d795178b8ec4e7eb withLabelledArg ",
              );
            };
            let withLabelledArg = {
              Runtime.id: "d795178b8ec4e7eb",
              call: (~name: string, ~age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "d795178b8ec4e7eb",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      Melange_json.Primitives.string_to_json(name),
                      Melange_json.Primitives.int_to_json(age),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function cc16d8dfbb02c5f1 withLabelledArgAndUnlabeledArg ",
              );
            };
  
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "cc16d8dfbb02c5f1",
              call: (~name: string="Lola", age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "cc16d8dfbb02c5f1",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      Melange_json.Primitives.string_to_json(name),
                      Melange_json.Primitives.int_to_json(age),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 759127163477eddf withOptionalArg ",
              );
            };
  
            let withOptionalArg = {
              Runtime.id: "759127163477eddf",
              call: (~name: string="Lola", ()) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "759127163477eddf",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      Melange_json.Primitives.string_to_json(name),
                      Js.Json.null,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 35bf61b207c3c325 withNoArgs ",
              );
            };
  
            let withNoArgs = {
              Runtime.id: "35bf61b207c3c325",
              call: () => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "35bf61b207c3c325",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      Js.Json.null,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  module SomeModule = {
    module Nested = {
      include {
                {
                  module J = {
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    external unsafe_expr: _ => _ = "#raw_stmt";
                  };
                  J.unsafe_expr(
                    "// extract-server-function e631018cb0716aad nestedServerFunction SomeModule.Nested",
                  );
                };
  
                let nestedServerFunction = {
                  Runtime.id: "e631018cb0716aad",
                  call: () => {
                    let action =
                      ReactServerDOMEsbuild.createServerReference(
                        "e631018cb0716aad",
                      );
                    (
                      [@ocaml.warning "-ignored-extra-argument"]
                      Js.Internal.opaqueFullApply(
                        (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                          Js.Json.null,
                        ),
                      ): _
                    )
                    |> Js.Promise.then_(response =>
                         Js.Promise.resolve(
                           RSC.Primitives.string_of_rsc(response),
                         )
                       );
                  },
                };
              };
    };
  };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 7aaca06c4b5d839b withFormData ",
              );
            };
  
            let withFormData = {
              Runtime.id: "7aaca06c4b5d839b",
              call: (formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "7aaca06c4b5d839b",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      formData,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 11767e09183229aa withFormDataAndLabelledArgs ",
              );
            };
  
            let withFormDataAndLabelledArgs = {
              Runtime.id: "11767e09183229aa",
              call: (country: string, ~formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "11767e09183229aa",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      Melange_json.Primitives.string_to_json(country),
                      formData,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 79fae9670eeb9c1b withFormDataAndArgsDifferentOrder ",
              );
            };
  
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "79fae9670eeb9c1b",
              call: (~formData: Js.FormData.t, country: string) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "79fae9670eeb9c1b",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      formData,
                      Melange_json.Primitives.string_to_json(country),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function defad4fc0b6197d9 withBoolArg ",
              );
            };
  
            let withBoolArg = {
              Runtime.id: "defad4fc0b6197d9",
              call: (~flag: bool) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "defad4fc0b6197d9",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      Melange_json.Primitives.bool_to_json(flag),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function af9277acf0958e63 withListArg ",
              );
            };
  
            let withListArg = {
              Runtime.id: "af9277acf0958e63",
              call: (~names: list(string)) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "af9277acf0958e63",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      (
                        Melange_json.Primitives.list_to_json(
                          Melange_json.Primitives.string_to_json,
                        )
                      )(
                        names,
                      ),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function d2e977839904ede6 withResultArg ",
              );
            };
  
            let withResultArg = {
              Runtime.id: "d2e977839904ede6",
              call: (~res: result(string, string)) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "d2e977839904ede6",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      (
                        Melange_json.Primitives.result_to_json(
                          Melange_json.Primitives.string_to_json,
                          Melange_json.Primitives.string_to_json,
                        )
                      )(
                        res,
                      ),
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };

Every server function, FormData ones too, registers its { id, call } record
  $ grep server_functions_manifest_map _build/default/boostrap.js | sed 's|require("[^"]*")|require(...)|'
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__server_functions_manifest_map["d795178b8ec4e7eb"] = require(...).withLabelledArg
  window.__server_functions_manifest_map["cc16d8dfbb02c5f1"] = require(...).withLabelledArgAndUnlabeledArg
  window.__server_functions_manifest_map["759127163477eddf"] = require(...).withOptionalArg
  window.__server_functions_manifest_map["35bf61b207c3c325"] = require(...).withNoArgs
  window.__server_functions_manifest_map["e631018cb0716aad"] = require(...).SomeModule.Nested.nestedServerFunction
  window.__server_functions_manifest_map["7aaca06c4b5d839b"] = require(...).withFormData
  window.__server_functions_manifest_map["11767e09183229aa"] = require(...).withFormDataAndLabelledArgs
  window.__server_functions_manifest_map["79fae9670eeb9c1b"] = require(...).withFormDataAndArgsDifferentOrder
  window.__server_functions_manifest_map["defad4fc0b6197d9"] = require(...).withBoolArg
  window.__server_functions_manifest_map["af9277acf0958e63"] = require(...).withListArg
  window.__server_functions_manifest_map["d2e977839904ede6"] = require(...).withResultArg
