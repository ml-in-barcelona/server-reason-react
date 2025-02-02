
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react)
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx server-reason-react.ppx -melange)))
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

  $ dune describe pp input.re
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
              [@ocaml.warning "-ignored-extra-argument"]
              J.unsafe_expr("// extract-client input.re");
            };
            [@ocaml.warning "-unboxable-type-in-prim-decl"]
            external makeProps: (~key: string=?, unit) => Js.t({.}) =
              ""
              "\132\149\166\190\000\000\000\015\000\000\000\007\000\000\000\019\000\000\000\019\145\160\160A\161#key@\160\160@@@";
            let make = () =>
              [@ocaml.warning "-ignored-extra-argument"]
              [@ocaml.warning "-ignored-extra-argument"]
              ReactDOM.jsxs(
                "section",
                [@ocaml.warning "-ignored-extra-argument"]
                [@ocaml.warning "-ignored-extra-argument"]
                ([@merlin.hide] ReactDOM.domProps)(
                  ~children=
                    [@ocaml.warning "-ignored-extra-argument"]
                    [@ocaml.warning "-ignored-extra-argument"]
                    React.array([|
                      [@ocaml.warning "-ignored-extra-argument"]
                      [@ocaml.warning "-ignored-extra-argument"]
                      ReactDOM.jsx(
                        "h1",
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=
                            [@ocaml.warning "-ignored-extra-argument"]
                            [@ocaml.warning "-ignored-extra-argument"]
                            React.string("lola"),
                          (),
                        ),
                      ),
                      [@ocaml.warning "-ignored-extra-argument"]
                      [@ocaml.warning "-ignored-extra-argument"]
                      ReactDOM.jsx(
                        "p",
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=
                            [@ocaml.warning "-ignored-extra-argument"]
                            [@ocaml.warning "-ignored-extra-argument"]
                            React.int(1),
                          (),
                        ),
                      ),
                      [@ocaml.warning "-ignored-extra-argument"]
                      [@ocaml.warning "-ignored-extra-argument"]
                      ReactDOM.jsx(
                        "div",
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        ([@merlin.hide] ReactDOM.domProps)(
                          ~children=
                            [@ocaml.warning "-ignored-extra-argument"]
                            [@ocaml.warning "-ignored-extra-argument"]
                            React.string("children"),
                          (),
                        ),
                      ),
                    |]),
                  (),
                ),
              );
            let make = {
              let Input = (Props: Js.t({.})) =>
                [@ocaml.warning "-ignored-extra-argument"]
                [@ocaml.warning "-ignored-extra-argument"]
                make();
              Input;
            };
            let make_client = props =>
              [@ocaml.warning "-ignored-extra-argument"]
              [@ocaml.warning "-ignored-extra-argument"]
              make(
                [@ocaml.warning "-ignored-extra-argument"]
                [@ocaml.warning "-ignored-extra-argument"]
                Js.Obj.empty(),
              );
          };
  
  let _ = make;
