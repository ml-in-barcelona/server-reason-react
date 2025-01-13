  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (preprocess (pps server-reason-react.ppx -js)))
  > EOF

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
  open Ppx_deriving_json_runtime.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  
  module Prop_with_many_annotation = {
    include {
              [@react.component]
              let make = (~initial: int, ~lola: lola, ~children: React.element) =>
                <section>
                  <h1> {React.string(lola.name)} </h1>
                  <p> {React.int(initial)} </p>
                  <div> children </div>
                </section>;
              let make_client = props =>
                make({
                  "children": (props##children: React.element),
                  "lola": [%of_json: lola](props##lola),
                  "initial": [%of_json: int](props##initial),
                });
            };
  };
