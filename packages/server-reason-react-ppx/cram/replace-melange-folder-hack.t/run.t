  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (include_subdirs unqualified)
  > (melange.emit
  >  (target js)
  >  (libraries reason-react melange-json)
  >  (preprocess (pps melange.ppx melange-json.ppx server-reason-react.ppx -shared-folder-prefix=doesnt-matter -melange)))
  > EOF

  $ dune describe pp js/input.re
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
  open Melange_json.Primitives;
  
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
            let make_client = props => make(Js.Obj.empty());
          };
