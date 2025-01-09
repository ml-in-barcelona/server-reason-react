  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react melange-json)
  >  (preprocess (pps melange.ppx melange-json.ppx server-reason-react.ppx -js)))
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
  
  module Prop_with_many_annotation = {
    [@warning "-27"];
    include {
              [@react.component]
              let make =
                  (
                    ~prop: int,
                    ~lola: list(int),
                    ~lolo: string,
                    ~lili: bool,
                    ~lulu: float,
                    ~tuple2: (int, int),
                    ~tuple3: (int, string, float),
                  ) => React.null;
              let make_client = props =>
                [@ocaml.warning "-ignored-extra-argument"]
                [@ocaml.warning "-ignored-extra-argument"]
                make(
                  {
                    module J = {
                      [@ocaml.warning "-unboxable-type-in-prim-decl"]
                      [@ocaml.warning "-unboxable-type-in-prim-decl"]
                      external unsafe_expr:
                        (
                          ~tuple3: 'a0,
                          ~tuple2: 'a1,
                          ~lulu: 'a2,
                          ~lili: 'a3,
                          ~lolo: 'a4,
                          ~lola: 'a5,
                          ~prop: 'a6
                        ) =>
                        {
                          .
                          "tuple3": 'a0,
                          "tuple2": 'a1,
                          "lulu": 'a2,
                          "lili": 'a3,
                          "lolo": 'a4,
                          "lola": 'a5,
                          "prop": 'a6,
                        } =
                        ""
                        "\132\149\166\190\000\000\000E\000\000\000\029\000\000\000O\000\000\000H\145\160\160A\144&tuple3\160\160A\144&tuple2\160\160A\144$lulu\160\160A\144$lili\160\160A\144$lolo\160\160A\144$lola\160\160A\144$prop@";
                    };
                    [@ocaml.warning "-ignored-extra-argument"]
                    [@ocaml.warning "-ignored-extra-argument"]
                    J.unsafe_expr(
                      ~tuple3=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        (
                          x =>
                            if ([@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                Stdlib.(&&)(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.isArray(x),
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Stdlib.(==)(
                                    [@ocaml.warning "-ignored-extra-argument"]
                                    [@ocaml.warning "-ignored-extra-argument"]
                                    Js.Array.length(
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      Obj.magic(x): array(Js.Json.t),
                                    ),
                                    3,
                                  ),
                                )) {
                              let es: array(Js.Json.t) =
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                Obj.magic(x);
                              (
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                int_of_json(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.unsafe_get(es, 0),
                                ),
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                string_of_json(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.unsafe_get(es, 1),
                                ),
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                float_of_json(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.unsafe_get(es, 2),
                                ),
                              );
                            } else {
                              [@ocaml.warning "-ignored-extra-argument"]
                              [@ocaml.warning "-ignored-extra-argument"]
                              Ppx_deriving_json_runtime.of_json_error(
                                "expected a JSON array of length 3",
                              );
                            }
                        )(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            tuple3,
                        ),
                      ~tuple2=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        (
                          x =>
                            if ([@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                Stdlib.(&&)(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.isArray(x),
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Stdlib.(==)(
                                    [@ocaml.warning "-ignored-extra-argument"]
                                    [@ocaml.warning "-ignored-extra-argument"]
                                    Js.Array.length(
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      Obj.magic(x): array(Js.Json.t),
                                    ),
                                    2,
                                  ),
                                )) {
                              let es: array(Js.Json.t) =
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                Obj.magic(x);
                              (
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                int_of_json(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.unsafe_get(es, 0),
                                ),
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                int_of_json(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Array.unsafe_get(es, 1),
                                ),
                              );
                            } else {
                              [@ocaml.warning "-ignored-extra-argument"]
                              [@ocaml.warning "-ignored-extra-argument"]
                              Ppx_deriving_json_runtime.of_json_error(
                                "expected a JSON array of length 2",
                              );
                            }
                        )(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            tuple2,
                        ),
                      ~lulu=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        float_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            lulu,
                        ),
                      ~lili=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        bool_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            lili,
                        ),
                      ~lolo=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        string_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            lolo,
                        ),
                      ~lola=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        (
                          [@ocaml.warning "-ignored-extra-argument"]
                          [@ocaml.warning "-ignored-extra-argument"]
                          list_of_json(int_of_json)
                        )(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            lola,
                        ),
                      ~prop=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        int_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            prop,
                        ),
                    );
                  },
                );
            };
  };
  
  let _ = Prop_with_many_annotation.make;
