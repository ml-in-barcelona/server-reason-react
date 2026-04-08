  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (include_subdirs unqualified)
  > (melange.emit
  >  (target js)
  >  (libraries reason-react melange-json server-reason-react.rsc)
  >  (preprocess (pps melange.ppx server-reason-react.rsc.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > EOF

  $ ../dune-describe-pp.sh js/input.re
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr("// extract-client js/input.re");
            };
            [@react.component]
            let make = () => React.null;
            let make_client = props =>
              React.createElement(make, Js.Obj.empty());
          };
