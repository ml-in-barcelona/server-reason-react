  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > EOF

  $ dune describe pp input.re
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
      no_alias_deps: false,
      unboxed_types: false,
      unsafe_string: false,
      cookies: [],
    }
  ];
  open Melange_json.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  
  include {
            [%%raw "// extract-client input.re"];
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
  
  module InnerAfterNested = {
    module Very_nested = {
      [@deriving json]
      type lola = {name: string};
  
      include {
                [%%raw "// extract-client input.re InnerAfterNested.Very_nested"];
                [@react.component]
                let make =
                    (~initial: int, ~lola: lola, ~children: React.element) =>
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
  
    [@deriving json]
    type lola = {name: string};
  
    include {
              [%%raw "// extract-client input.re InnerAfterNested"];
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
  
  module InnerBeforeNested = {
    [@deriving json]
    type lola = {name: string};
  
    include {
              [%%raw "// extract-client input.re InnerBeforeNested"];
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
    module Very_nested = {
      [@deriving json]
      type lola = {name: string};
  
      include {
                [%%raw
                  "// extract-client input.re InnerBeforeNested.Very_nested"
                ];
                [@react.component]
                let make =
                    (~initial: int, ~lola: lola, ~children: React.element) =>
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
  };
