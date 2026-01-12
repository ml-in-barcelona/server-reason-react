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
  >  (libraries server-reason-react.runtime reason-react)
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
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

  $ dune describe pp input.re | sed '/\[@mel.internal.ffi/,/\]/d'
  [@ocaml.ppx.context
    {
      tool_name: "ppx_driver",
      include_dirs: [],
      hidden_include_dirs: [],
      load_path: ([], []),
      open_modules: [],
      for_package: None,
      debug: false,
      use_threads: false,
      use_vmthreads: false,
      recursive_types: false,
      principal: false,
      transparent_modules: false,
      unboxed_types: false,
      unsafe_string: false,
      cookies: [],
    }
  ];
  open Melange_json.Primitives;
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr(
                "// extract-server-function 646124344 withLabelledArg ",
              );
            };
  
            let withLabelledArg = {
              Runtime.id: "646124344",
              call: (~name: string, ~age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("646124344");
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
                     Js.Promise.resolve(string_of_json(response))
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
                "// extract-server-function 43607654 withLabelledArgAndUnlabeledArg ",
              );
            };
  
            let withLabelledArgAndUnlabeledArg = {
              Runtime.id: "43607654",
              call: (~name: string="Lola", age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("43607654");
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
                     Js.Promise.resolve(string_of_json(response))
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
                "// extract-server-function 275062916 withOptionalArg ",
              );
            };
  
            let withOptionalArg = {
              Runtime.id: "275062916",
              call: (~name: string="Lola", ()) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("275062916");
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
                     Js.Promise.resolve(string_of_json(response))
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
              J.unsafe_expr("// extract-server-function 573178554 withNoArgs ");
            };
  
            let withNoArgs = {
              Runtime.id: "573178554",
              call: () => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("573178554");
                Js.Internal.run(action)
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(string_of_json(response))
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
                    "// extract-server-function 278174395 nestedServerFunction SomeModule.Nested",
                  );
                };
  
                let nestedServerFunction = {
                  Runtime.id: "278174395",
                  call: () => {
                    let action =
                      ReactServerDOMEsbuild.createServerReference("278174395");
                    Js.Internal.run(action)
                    |> Js.Promise.then_(response =>
                         Js.Promise.resolve(string_of_json(response))
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
                "// extract-server-function 247821597 withFormData.call ",
              );
            };
  
            let withFormData = {
              Runtime.id: "247821597",
              call: (formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("247821597");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity1(_)).I1))(
                      formData,
                    ),
                  ): _
                )
                |> Js.Promise.then_(response =>
                     Js.Promise.resolve(string_of_json(response))
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
                "// extract-server-function 774822153 withFormDataAndLabelledArgs.call ",
              );
            };
  
            let withFormDataAndLabelledArgs = {
              Runtime.id: "774822153",
              call: (country: string, ~formData: Js.FormData.t) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("774822153");
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
                     Js.Promise.resolve(string_of_json(response))
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
                "// extract-server-function 658628366 withFormDataAndArgsDifferentOrder.call ",
              );
            };
  
            let withFormDataAndArgsDifferentOrder = {
              Runtime.id: "658628366",
              call: (~formData: Js.FormData.t, country: string) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("658628366");
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
                     Js.Promise.resolve(string_of_json(response))
                   );
              },
            };
          };
