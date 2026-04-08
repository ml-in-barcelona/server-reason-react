
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react server-reason-react.rsc)
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
              J.unsafe_expr("// extract-client input.re");
            };
            [@ocaml.warning "-unboxable-type-in-prim-decl"]
            external makeProps: (~key: string=?, unit) => Js.t({.}) = "" "";
            let make =
              [@warning "-16"]
              (
                () =>
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
                  )
              );
            let make = {
              let Input = (Props: Js.t({.})) => make();
              Input;
            };
            let make_client = props =>
              React.createElement(make, Js.Obj.empty());
          };
