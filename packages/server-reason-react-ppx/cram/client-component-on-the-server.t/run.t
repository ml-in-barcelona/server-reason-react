  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune build

  $ dune describe pp input.re
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
  [@warning "-32"];
  
  open Melange_json.Primitives;
  
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
                          Melange_json.of_json_error(
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
                        Melange_json.of_json_error(
                          ~json=x,
                          "expected field \"name\"",
                        )
                      },
                  };
                | _ =>
                  Melange_json.of_json_error(~json=x, "expected a JSON object")
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
  
  let make =
      (
        ~key as _: option(string)=?,
        ~initial: int,
        ~lola: lola,
        ~children: React.element,
        ~maybe_children: option(React.element),
        (),
      ) =>
    React.Client_component({
      import_module: "input.re",
      import_name: "",
      props: [
        ("initial", React.Model.Json(int_to_json(initial))),
        ("lola", React.Model.Json(lola_to_json(lola))),
        ("children", React.Model.Element(children: React.element)),
        (
          "maybe_children",
          switch (maybe_children) {
          | Some(prop) => React.Model.Element(prop: React.element)
          | None => React.Model.Json(`Null)
          },
        ),
      ],
      client:
        React.createElement(
          "section",
          [],
          [
            React.createElement("h1", [], [React.string(lola.name)]),
            React.createElement("p", [], [React.int(initial)]),
            React.createElement("div", [], [children]),
            switch (maybe_children) {
            | Some(children) => children
            | None => React.null
            },
          ],
        ),
    });
