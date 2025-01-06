  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx server-reason-react.melange_ppx melange-json-native.ppx)))
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
  open Ppx_deriving_json_runtime.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  /**@inline*/
  [@merlin.hide]
  include {
            let _ = (_: lola) => ();
            [@ocaml.warning "-39-11-27"];
            let rec lola_of_json: Yojson.Basic.t => lola =
              x =>
                switch (x) {
                | `Assoc(fs) =>
                  let x_name = ref(Stdlib.Option.None);
                  let rec iter = (
                    fun
                    | [] => ()
                    | [(n', v), ...fs] => {
                        switch (n') {
                        | "name" =>
                          x_name := Stdlib.Option.Some(string_of_json(v))
                        | name =>
                          Ppx_deriving_json_runtime.of_json_error(
                            ~json=x,
                            Stdlib.Printf.sprintf(
                              {|did not expect field "%s"|},
                              name,
                            ),
                          )
                        };
                        iter(fs);
                      }
                  );
                  iter(fs);
                  {
                    name:
                      switch (Stdlib.(^)(x_name)) {
                      | Stdlib.Option.Some(v) => v
                      | Stdlib.Option.None =>
                        Ppx_deriving_json_runtime.of_json_error(
                          ~json=x,
                          "expected field \"name\"",
                        )
                      },
                  };
                | _ =>
                  Ppx_deriving_json_runtime.of_json_error(
                    ~json=x,
                    "expected a JSON object",
                  )
                };
            let _ = lola_of_json;
            [@ocaml.warning "-39-11-27"];
            let rec lola_to_json: lola => Yojson.Basic.t =
              x =>
                switch (x) {
                | {name: x_name} =>
                  `Assoc(
                    {
                      let bnds__001_ = [];
                      let bnds__001_ = [
                        ("name", string_to_json(x_name)),
                        ...bnds__001_,
                      ];
                      bnds__001_;
                    },
                  )
                };
            let _ = lola_to_json;
          };
  
  module Prop_with_many_annotation = {
    let make = (~key as _: option(string)=?, ~initial: int, ~lola: lola, ()) =>
      React.Client_component({
        import_module: __FILE__,
        import_name: "",
        props: [
          ("initial", React.Json(int_to_json(initial))),
          ("lola", React.Json(lola_to_json(lola))),
        ],
        client:
          React.createElement(
            "div",
            [],
            [React.string(lola.name), React.int(initial)],
          ),
      });
  };
  
  let _ = Prop_with_many_annotation.make(~initial=1, ~lola={name: "lola"}, ());
