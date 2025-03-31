
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
  File "input.re", line 1, characters 5-41:
  1 | open Melange_json.Primitives;
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Unbound module Ppx_deriving_json_runtime
  [1]

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
  open Melange_json.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  /**@inline*/
  [@merlin.hide]
  include {
            let _ = (_: lola) => ();
            [@ocaml.warning "-39-11-27"];
            let rec lola_of_json: Js.Json.t => lola =
              x => {
                if (Stdlib.(!)(
                      Stdlib.(&&)(
                        Stdlib.(==)(Js.typeof(x), "object"),
                        Stdlib.(&&)(
                          Stdlib.(!)(Js.Array.isArray(x)),
                          Stdlib.(!)(
                            Stdlib.(===)(Obj.magic(x): Js.null('a), Js.null),
                          ),
                        ),
                      ),
                    )) {
                  Melange_json.of_json_error(~json=x, "expected a JSON object");
                };
                let fs: {. "name": Js.undefined(Js.Json.t)} = Obj.magic(x);
                {
                  name:
                    switch (
                      Js.Undefined.toOption(Js.OO.unsafe_downgrade(fs)#name)
                    ) {
                    | Stdlib.Option.Some(v) => string_of_json(v)
                    | Stdlib.Option.None =>
                      Melange_json.of_json_error(
                        ~json=x,
                        "expected field \"name\" to be present",
                      )
                    },
                };
              };
            let _ = lola_of_json;
            [@ocaml.warning "-39-11-27"];
            let rec lola_to_json: lola => Js.Json.t =
              x =>
                switch (x) {
                | {name: x_name} => (
                    Obj.magic(
                      {
                        module J = {
                          [@ocaml.warning "-unboxable-type-in-prim-decl"]
                          [@mel.internal.ffi
                            "����\000\000\000\011\000\000\000\005\000\000\000\r\000\000\000\012���A�$name@"
                          ]
                          external unsafe_expr: (~name: 'a0) => {. "name": 'a0} =
                            "" "";
                        };
                        J.unsafe_expr(~name=string_to_json(x_name));
                      },
                    ): Js.Json.t
                  )
                };
            let _ = lola_to_json;
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr("// extract-client input.re");
            };
  
            [@ocaml.warning "-unboxable-type-in-prim-decl"]
            [@mel.internal.ffi
              "����\000\000\000J\000\000\000\027\000\000\000L\000\000\000G���A�'initial��A�$lola��A�'default@��A�(children��A�'promise��A�#key@��@@@"
            ]
            external makeProps:
              (
                ~initial: int,
                ~lola: lola,
                ~default: int=?,
                ~children: React.element,
                ~promise: Js.Promise.t(string),
                ~key: string=?,
                unit
              ) =>
              {
                .
                "initial": int,
                "lola": lola,
                "default": option(int),
                "children": React.element,
                "promise": Js.Promise.t(string),
              } =
              "" "";
            let make =
              [@warning "-16"]
              (
                (~initial: int) =>
                  [@warning "-16"]
                  (
                    (~lola: lola) =>
                      [@warning "-16"]
                      (
                        (~default: int=23) =>
                          [@warning "-16"]
                          (
                            (~children: React.element) =>
                              [@warning "-16"]
                              (
                                (~promise: Js.Promise.t(string)) => {
                                  let value = React.Experimental.use(promise);
                                  ReactDOM.jsxs(
                                    "div",
                                    ([@merlin.hide] ReactDOM.domProps)(
                                      ~children=
                                        React.array([|
                                          React.string(lola.name),
                                          React.int(initial),
                                          React.int(default),
                                          children,
                                          React.string(value),
                                        |]),
                                      (),
                                    ),
                                  );
                                }
                              )
                          )
                      )
                  )
              );
            let make = {
              let Input =
                  (
                    Props: {
                      .
                      "initial": int,
                      "lola": lola,
                      "default": option(int),
                      "children": React.element,
                      "promise": Js.Promise.t(string),
                    },
                  ) =>
                make(
                  ~promise=Js.OO.unsafe_downgrade(Props)#promise,
                  ~children=Js.OO.unsafe_downgrade(Props)#children,
                  ~default=?Js.OO.unsafe_downgrade(Props)#default,
                  ~lola=Js.OO.unsafe_downgrade(Props)#lola,
                  ~initial=Js.OO.unsafe_downgrade(Props)#initial,
                );
              Input;
            };
            let make_client = props =>
              make(
                {
                  module J = {
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    [@mel.internal.ffi
                      "����\000\000\000<\000\000\000\021\000\000\000:\000\000\0005���A�'promise��A�(children��A�'default��A�$lola��A�'initial@"
                    ]
                    external unsafe_expr:
                      (
                        ~promise: 'a0,
                        ~children: 'a1,
                        ~default: 'a2,
                        ~lola: 'a3,
                        ~initial: 'a4
                      ) =>
                      {
                        .
                        "promise": 'a0,
                        "children": 'a1,
                        "default": 'a2,
                        "lola": 'a3,
                        "initial": 'a4,
                      } =
                      "" "";
                  };
                  J.unsafe_expr(
                    ~promise=Js.OO.unsafe_downgrade(props)#promise:
                                                                     Js.Promise.t(
                                                                      string,
                                                                     ),
                    ~children=Js.OO.unsafe_downgrade(props)#children: React.element,
                    ~default=
                      (option_of_json(int_of_json))(
                        Js.OO.unsafe_downgrade(props)#default,
                      ),
                    ~lola=lola_of_json(Js.OO.unsafe_downgrade(props)#lola),
                    ~initial=
                      int_of_json(Js.OO.unsafe_downgrade(props)#initial),
                  );
                },
              );
          };
  
  let _ = make;

  $ cat _build/default/js/input.js
  cat: _build/default/js/input.js: No such file or directory
  [1]

  $ cat _build/default/boostrap.js
  cat: _build/default/boostrap.js: No such file or directory
  [1]
