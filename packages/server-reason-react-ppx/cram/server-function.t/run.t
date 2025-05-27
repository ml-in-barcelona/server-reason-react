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
                "// extract-server-function 500511824 simpleResponse ",
              );
            };
            [@react.server.function]
            let simpleResponse = {
              Runtime.id: "500511824",
              call: (~name: string, age: int) => {
                let action =
                  ReactServerDOMEsbuild.createServerReference("500511824");
                (
                  [@ocaml.warning "-ignored-extra-argument"]
                  Js.Internal.opaqueFullApply(
                    (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                      ~name,
                      age,
                    ),
                  ): _
                );
              },
            };
          };
  
  module ServerFunctions = {
    include {
              {
                module J = {
                  [@ocaml.warning "-unboxable-type-in-prim-decl"]
                  external unsafe_expr: _ => _ = "#raw_stmt";
                };
                J.unsafe_expr(
                  "// extract-server-function 101662525 otherServerFunction ServerFunctions",
                );
              };
  
              [@react.server.function]
              let otherServerFunction = {
                Runtime.id: "101662525",
                call: (~name: string, ()) => {
                  let action =
                    ReactServerDOMEsbuild.createServerReference("101662525");
                  (
                    [@ocaml.warning "-ignored-extra-argument"]
                    Js.Internal.opaqueFullApply(
                      (Js.Internal.opaque((action: Js.Fn.arity2(_)).I2))(
                        ~name,
                        (),
                      ),
                    ): _
                  );
                },
              };
            };
  
    module Nested = {
      include {
                {
                  module J = {
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    external unsafe_expr: _ => _ = "#raw_stmt";
                  };
                  J.unsafe_expr(
                    "// extract-server-function 746479773 nestedServerFunction ServerFunctions.Nested",
                  );
                };
  
                [@react.server.function]
                let nestedServerFunction = {
                  Runtime.id: "746479773",
                  call: () => {
                    let action =
                      ReactServerDOMEsbuild.createServerReference("746479773");
                    Js.Internal.run(action);
                  },
                };
              };
    };
  };
