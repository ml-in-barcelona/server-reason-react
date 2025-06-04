  $ cat > ReactServerDOMEsbuild.re << EOF
  > [@mel.module "./ReactServerDOMEsbuild.js"]
  > external createServerReference:
  >   ( string ) => 'action = "createServerReference";
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
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx  server-reason-react.ppx -melange)))
  > 
  > (rule
  >  (deps (alias melange))
  >  (target boostrap.js)
  >   (action
  >    (progn
  >     (with-stdout-to %{target}
  >      (run server_reason_react.extract_client_components js)))))
  > EOF

  $ dune build

  $ dune describe pp input.re | sed '/\[@mel.internal.ffi/,/\]/d'
  [@ocaml.ppx.context
    {
      tool_name: "ppx_driver",
      include_dirs: [],
      load_path: [],
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
                Js.Internal.run(action);
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
                    Js.Internal.run(action);
                  },
                };
              };
    };
  };
