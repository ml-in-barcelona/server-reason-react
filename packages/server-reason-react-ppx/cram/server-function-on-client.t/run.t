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
                "// extract-server-function input#withLabelledArg withLabelledArg ",
              );
            };
            let withLabelledArg = {
              Runtime.id: "input#withLabelledArg",
              call: (~name: string, ~age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withLabelledArg",
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
                "// extract-server-function input#withLabelledArgAndUnlabeledArg withLabelledArgAndUnlabeledArg ",
              );
            };
  
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "input#withLabelledArgAndUnlabeledArg",
              call: (~name: string="Lola", age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withLabelledArgAndUnlabeledArg",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      (
                        Melange_json.Primitives.option_to_json(
                          Melange_json.Primitives.string_to_json,
                        )
                      )(
                        Some(name),
                      ),
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
                "// extract-server-function input#withOptionalArg withOptionalArg ",
              );
            };
  
            let withOptionalArg = {
              Runtime.id: "input#withOptionalArg",
              call: (~name: string="Lola", ()) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withOptionalArg",
                  );
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      (
                        Melange_json.Primitives.option_to_json(
                          Melange_json.Primitives.string_to_json,
                        )
                      )(
                        Some(name),
                      ),
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
                "// extract-server-function input#withNoArgs withNoArgs ",
              );
            };
  
            let withNoArgs = {
              Runtime.id: "input#withNoArgs",
              call: () => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withNoArgs",
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
                    "// extract-server-function input.SomeModule.Nested#nestedServerFunction nestedServerFunction SomeModule.Nested",
                  );
                };
  
                let nestedServerFunction = {
                  Runtime.id: "input.SomeModule.Nested#nestedServerFunction",
                  call: () => {
                    let action =
                      ReactServerDOMEsbuild.createServerReference(
                        "input.SomeModule.Nested#nestedServerFunction",
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
                "// extract-server-function input#withFormData withFormData ",
              );
            };
  
            let withFormData = {
              Runtime.id: "input#withFormData",
              call: (formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withFormData",
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
                "// extract-server-function input#withFormDataAndLabelledArgs withFormDataAndLabelledArgs ",
              );
            };
  
            let withFormDataAndLabelledArgs = {
              Runtime.id: "input#withFormDataAndLabelledArgs",
              call: (country: string, ~formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withFormDataAndLabelledArgs",
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
                "// extract-server-function input#withFormDataAndArgsDifferentOrder withFormDataAndArgsDifferentOrder ",
              );
            };
  
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "input#withFormDataAndArgsDifferentOrder",
              call: (~formData: Js.FormData.t, country: string) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withFormDataAndArgsDifferentOrder",
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
                "// extract-server-function input#withBoolArg withBoolArg ",
              );
            };
  
            let withBoolArg = {
              Runtime.id: "input#withBoolArg",
              call: (~flag: bool) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withBoolArg",
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
                "// extract-server-function input#withListArg withListArg ",
              );
            };
  
            let withListArg = {
              Runtime.id: "input#withListArg",
              call: (~names: list(string)) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withListArg",
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
                "// extract-server-function input#withResultArg withResultArg ",
              );
            };
  
            let withResultArg = {
              Runtime.id: "input#withResultArg",
              call: (~res: result(string, string)) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference(
                    "input#withResultArg",
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
  window.__server_functions_manifest_map["input#withLabelledArg"] = require(...).withLabelledArg
  window.__server_functions_manifest_map["input#withLabelledArgAndUnlabeledArg"] = require(...).withLabelledArgAndUnlabeledArg
  window.__server_functions_manifest_map["input#withOptionalArg"] = require(...).withOptionalArg
  window.__server_functions_manifest_map["input#withNoArgs"] = require(...).withNoArgs
  window.__server_functions_manifest_map["input.SomeModule.Nested#nestedServerFunction"] = require(...).SomeModule.Nested.nestedServerFunction
  window.__server_functions_manifest_map["input#withFormData"] = require(...).withFormData
  window.__server_functions_manifest_map["input#withFormDataAndLabelledArgs"] = require(...).withFormDataAndLabelledArgs
  window.__server_functions_manifest_map["input#withFormDataAndArgsDifferentOrder"] = require(...).withFormDataAndArgsDifferentOrder
  window.__server_functions_manifest_map["input#withBoolArg"] = require(...).withBoolArg
  window.__server_functions_manifest_map["input#withListArg"] = require(...).withListArg
  window.__server_functions_manifest_map["input#withResultArg"] = require(...).withResultArg
