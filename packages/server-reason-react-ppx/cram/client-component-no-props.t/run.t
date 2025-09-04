
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react)
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx server-reason-react.ppx -shared-folder-prefix=doesnt-matter -melange)))
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
      load_path: [@ppxlib.migration.load_path ([], [])] [],
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
              J.unsafe_expr("// extract-client input.re");
            };
            [@ocaml.warning "-unboxable-type-in-prim-decl"]
            external makeProps: (~key: string=?, unit) => Js.t({.}) = "" "";
            let make = () =>
              ReactDOM.jsxs(
                "section",
                ([@merlin.hide] ReactDOM.domProps)(
                  ~children=
                    React.array([|
                      ReactDOM.jsx(
                        "h1",
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=React.string("lola"),
                          (),
                        ),
                      ),
                      ReactDOM.jsx(
                        "p",
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=React.int(1),
                          (),
                        ),
                      ),
                      ReactDOM.jsx(
                        "div",
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=React.string("children"),
                          (),
                        ),
                      ),
                    |]),
                  (),
                ),
              );
            let make = {
              let Input = (Props: Js.t({.})) => make();
              Input;
            };
            let make_client = props => make(Js.Obj.empty());
          };
