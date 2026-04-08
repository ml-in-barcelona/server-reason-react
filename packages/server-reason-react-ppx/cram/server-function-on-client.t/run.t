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
  >  (libraries server-reason-react.runtime reason-react server-reason-react.rsc)
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
                "// extract-server-function 1073617701 withLabelledArg ",
              );
            };
            let withLabelledArg = {
              Runtime.id: "1073617701",
              call: (~name: string, ~age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("1073617701");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      name,
                      age,
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
                "// extract-server-function 416745144 withLabelledArgAndUnlabeledArg ",
              );
            };
  
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "416745144",
              call: (~name: string="Lola", age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("416745144");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      name,
                      age,
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
                "// extract-server-function 874321837 withOptionalArg ",
              );
            };
  
            let withOptionalArg = {
              Runtime.id: "874321837",
              call: (~name: string="Lola", ()) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("874321837");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      name,
                      (),
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
              J.unsafe_expr("// extract-server-function 898874717 withNoArgs ");
            };
  
            let withNoArgs = {
              Runtime.id: "898874717",
              call: () => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("898874717");
                Js.Internal.run(action)
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
                    "// extract-server-function 157629082 nestedServerFunction SomeModule.Nested",
                  );
                };
  
                let nestedServerFunction = {
                  Runtime.id: "157629082",
                  call: () => {
                    let action =
                      ReactServerDOMEsbuild.createServerReference("157629082");
                    Js.Internal.run(action)
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
                "// extract-server-function 890905285 withFormData.call ",
              );
            };
  
            let withFormData = {
              Runtime.id: "890905285",
              call: (formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("890905285");
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
                "// extract-server-function 465790865 withFormDataAndLabelledArgs.call ",
              );
            };
  
            let withFormDataAndLabelledArgs = {
              Runtime.id: "465790865",
              call: (country: string, ~formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("465790865");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      country,
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
                "// extract-server-function 512972037 withFormDataAndArgsDifferentOrder.call ",
              );
            };
  
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "512972037",
              call: (~formData: Js.FormData.t, country: string) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("512972037");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      formData,
                      country,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(RSC.Primitives.string_of_rsc(response))
                   );
              },
            };
          };
