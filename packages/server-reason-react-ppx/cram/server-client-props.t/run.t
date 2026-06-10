
  $ ../ppx.sh --output re input.re
  module Prop_with_many_annotation = {
    include {
              let makeProps =
                  (
                    ~prop: int,
                    ~lola: list(int),
                    ~mona: array(float),
                    ~lolo: string,
                    ~lili: bool,
                    ~lulu: float,
                    ~tuple2: (int, int),
                    ~tuple3: (int, string, float),
                    (),
                  ) => {
                let __js_obj_cell_0 = Stdlib.ref(prop);
                let __js_obj_cell_1 = Stdlib.ref(lola);
                let __js_obj_cell_2 = Stdlib.ref(mona);
                let __js_obj_cell_3 = Stdlib.ref(lolo);
                let __js_obj_cell_4 = Stdlib.ref(lili);
                let __js_obj_cell_5 = Stdlib.ref(lulu);
                let __js_obj_cell_6 = Stdlib.ref(tuple2);
                let __js_obj_cell_7 = Stdlib.ref(tuple3);
                let __js_obj = {
                  as _;
                  pub prop = __js_obj_cell_0^;
                  pub lola = __js_obj_cell_1^;
                  pub mona = __js_obj_cell_2^;
                  pub lolo = __js_obj_cell_3^;
                  pub lili = __js_obj_cell_4^;
                  pub lulu = __js_obj_cell_5^;
                  pub tuple2 = __js_obj_cell_6^;
                  pub tuple3 = __js_obj_cell_7^
                };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="prop",
                        ~js_name="prop",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lola",
                        ~js_name="lola",
                        ~present=true,
                        __js_obj_cell_1,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="mona",
                        ~js_name="mona",
                        ~present=true,
                        __js_obj_cell_2,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lolo",
                        ~js_name="lolo",
                        ~present=true,
                        __js_obj_cell_3,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lili",
                        ~js_name="lili",
                        ~present=true,
                        __js_obj_cell_4,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lulu",
                        ~js_name="lulu",
                        ~present=true,
                        __js_obj_cell_5,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="tuple2",
                        ~js_name="tuple2",
                        ~present=true,
                        __js_obj_cell_6,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="tuple3",
                        ~js_name="tuple3",
                        ~present=true,
                        __js_obj_cell_7,
                      ),
                    ]
                  ): {
                    .
                    "prop": int,
                    "lola": list(int),
                    "mona": array(float),
                    "lolo": string,
                    "lili": bool,
                    "lulu": float,
                    "tuple2": (int, int),
                    "tuple3": (int, string, float),
                  }
                );
              };
              let make =
                  (
                    ~key: option(string)=?,
                    ~prop: int,
                    ~lola: list(int),
                    ~mona: array(float),
                    ~lolo: string,
                    ~lili: bool,
                    ~lulu: float,
                    ~tuple2: (int, int),
                  ) =>
                [@warning "-16"]
                (
                  (~tuple3: (int, string, float), ()) =>
                    React.Client_component({
                      key,
                      import_module:
                        Printf.sprintf(
                          "%s#%s",
                          "output.ml",
                          "Prop_with_many_annotation",
                        ),
                      import_name: "",
                      props: [
                        ("prop", RSC.to_model([%to_rsc: int](prop))),
                        ("lola", RSC.to_model([%to_rsc: list(int)](lola))),
                        (
                          "mona",
                          RSC.to_model([%to_rsc: array(float)](mona)),
                        ),
                        ("lolo", RSC.to_model([%to_rsc: string](lolo))),
                        ("lili", RSC.to_model([%to_rsc: bool](lili))),
                        ("lulu", RSC.to_model([%to_rsc: float](lulu))),
                        (
                          "tuple2",
                          RSC.to_model([%to_rsc: (int, int)](tuple2)),
                        ),
                        (
                          "tuple3",
                          RSC.to_model(
                            [%to_rsc: (int, string, float)](tuple3),
                          ),
                        ),
                      ],
                      client:
                        [@implicit_arity]
                        React.Upper_case_component(
                          Stdlib.__FUNCTION__,
                          () => React.null,
                        ),
                    })
                );
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "prop": int,
                      "lola": list(int),
                      "mona": array(float),
                      "lolo": string,
                      "lili": bool,
                      "lulu": float,
                      "tuple2": (int, int),
                      "tuple3": (int, string, float),
                    },
                  ) =>
                make(
                  ~key?,
                  ~prop=Props#prop,
                  ~lola=Props#lola,
                  ~mona=Props#mona,
                  ~lolo=Props#lolo,
                  ~lili=Props#lili,
                  ~lulu=Props#lulu,
                  ~tuple2=Props#tuple2,
                  ~tuple3=Props#tuple3,
                  (),
                );
            };
  };
  module Prop_without_annotation = {
    include {
              let makeProps =
                  (~prop_without_annotation: 'prop_without_annotation, ()) => {
                let __js_obj_cell_0 = Stdlib.ref(prop_without_annotation);
                let __js_obj = {
                  as _;
                  pub prop_without_annotation = __js_obj_cell_0^
                };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="prop_without_annotation",
                        ~js_name="prop_without_annotation",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                    ]
                  ): {
                    .
                    "prop_without_annotation": 'prop_without_annotation,
                  }
                );
              };
              let make = (~key: option(string)=?, ~prop_without_annotation, ()) =>
                React.Client_component({
                  key,
                  import_module:
                    Printf.sprintf(
                      "%s#%s",
                      "output.ml",
                      "Prop_without_annotation",
                    ),
                  import_name: "",
                  props: [
                    [%ocaml.error
                      "server-reason-react: client components need type annotations. Missing annotation for 'prop_without_annotation'"
                    ],
                  ],
                  client:
                    [@implicit_arity]
                    React.Upper_case_component(
                      Stdlib.__FUNCTION__,
                      () => React.null,
                    ),
                });
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "prop_without_annotation": 'prop_without_annotation,
                    },
                  ) =>
                make(
                  ~key?,
                  ~prop_without_annotation=Props#prop_without_annotation,
                  (),
                );
            };
  };
  module Prop_with_unsupported_annotation = {
    include {
              let makeProps = (~underscore: _, ~alpha_types: 'a, ()) => {
                let __js_obj_cell_0 = Stdlib.ref(underscore);
                let __js_obj_cell_1 = Stdlib.ref(alpha_types);
                let __js_obj = {
                  as _;
                  pub underscore = __js_obj_cell_0^;
                  pub alpha_types = __js_obj_cell_1^
                };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="underscore",
                        ~js_name="underscore",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="alpha_types",
                        ~js_name="alpha_types",
                        ~present=true,
                        __js_obj_cell_1,
                      ),
                    ]
                  ): {
                    .
                    "underscore": _,
                    "alpha_types": 'a,
                  }
                );
              };
              let make = (~key: option(string)=?, ~underscore: _) =>
                [@warning "-16"]
                (
                  (~alpha_types: 'a, ()) =>
                    React.Client_component({
                      key,
                      import_module:
                        Printf.sprintf(
                          "%s#%s",
                          "output.ml",
                          "Prop_with_unsupported_annotation",
                        ),
                      import_name: "",
                      props: [
                        (
                          "underscore",
                          RSC.to_model([%to_rsc: _](underscore)),
                        ),
                        (
                          "alpha_types",
                          RSC.to_model([%to_rsc: 'a](alpha_types)),
                        ),
                      ],
                      client:
                        [@implicit_arity]
                        React.Upper_case_component(
                          Stdlib.__FUNCTION__,
                          () => React.null,
                        ),
                    })
                );
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "underscore": _,
                      "alpha_types": 'a,
                    },
                  ) =>
                make(
                  ~key?,
                  ~underscore=Props#underscore,
                  ~alpha_types=Props#alpha_types,
                  (),
                );
            };
  };
  module Prop_with_annotation_that_need_to_be_type_alias = {
    include {
              let makeProps =
                  (
                    ~polyvariants: [
                       | `A
                       | `B
                     ],
                    (),
                  ) => {
                let __js_obj_cell_0 = Stdlib.ref(polyvariants);
                let __js_obj = { as _; pub polyvariants = __js_obj_cell_0^ };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="polyvariants",
                        ~js_name="polyvariants",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                    ]
                  ): {
                    .
                    "polyvariants": [
                      | `A
                      | `B
                    ],
                  }
                );
              };
              let make =
                  (
                    ~key: option(string)=?,
                    ~polyvariants: [
                       | `A
                       | `B
                     ],
                    (),
                  ) =>
                React.Client_component({
                  key,
                  import_module:
                    Printf.sprintf(
                      "%s#%s",
                      "output.ml",
                      "Prop_with_annotation_that_need_to_be_type_alias",
                    ),
                  import_name: "",
                  props: [
                    (
                      "polyvariants",
                      RSC.to_model(
                        [%to_rsc:
                          [
                            | `A
                            | `B
                          ]
                        ](polyvariants),
                      ),
                    ),
                  ],
                  client:
                    [@implicit_arity]
                    React.Upper_case_component(
                      Stdlib.__FUNCTION__,
                      () => React.null,
                    ),
                });
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "polyvariants": [
                        | `A
                        | `B
                      ],
                    },
                  ) =>
                make(~key?, ~polyvariants=Props#polyvariants, ());
            };
  };
  module Prop_with_unknown_annotation = {
    include {
              let makeProps =
                  (
                    ~lident: lola,
                    ~ldotlident: Module.lola,
                    ~ldotdotlident: Module.Inner.lola,
                    ~lapply: Label.t(int, string),
                    (),
                  ) => {
                let __js_obj_cell_0 = Stdlib.ref(lident);
                let __js_obj_cell_1 = Stdlib.ref(ldotlident);
                let __js_obj_cell_2 = Stdlib.ref(ldotdotlident);
                let __js_obj_cell_3 = Stdlib.ref(lapply);
                let __js_obj = {
                  as _;
                  pub lident = __js_obj_cell_0^;
                  pub ldotlident = __js_obj_cell_1^;
                  pub ldotdotlident = __js_obj_cell_2^;
                  pub lapply = __js_obj_cell_3^
                };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lident",
                        ~js_name="lident",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="ldotlident",
                        ~js_name="ldotlident",
                        ~present=true,
                        __js_obj_cell_1,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="ldotdotlident",
                        ~js_name="ldotdotlident",
                        ~present=true,
                        __js_obj_cell_2,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="lapply",
                        ~js_name="lapply",
                        ~present=true,
                        __js_obj_cell_3,
                      ),
                    ]
                  ): {
                    .
                    "lident": lola,
                    "ldotlident": Module.lola,
                    "ldotdotlident": Module.Inner.lola,
                    "lapply": Label.t(int, string),
                  }
                );
              };
              let make =
                  (
                    ~key: option(string)=?,
                    ~lident: lola,
                    ~ldotlident: Module.lola,
                    ~ldotdotlident: Module.Inner.lola,
                  ) =>
                [@warning "-16"]
                (
                  (~lapply: Label.t(int, string), ()) =>
                    React.Client_component({
                      key,
                      import_module:
                        Printf.sprintf(
                          "%s#%s",
                          "output.ml",
                          "Prop_with_unknown_annotation",
                        ),
                      import_name: "",
                      props: [
                        ("lident", RSC.to_model([%to_rsc: lola](lident))),
                        (
                          "ldotlident",
                          RSC.to_model([%to_rsc: Module.lola](ldotlident)),
                        ),
                        (
                          "ldotdotlident",
                          RSC.to_model(
                            [%to_rsc: Module.Inner.lola](ldotdotlident),
                          ),
                        ),
                        (
                          "lapply",
                          RSC.to_model(
                            [%to_rsc: Label.t(int, string)](lapply),
                          ),
                        ),
                      ],
                      client:
                        [@implicit_arity]
                        React.Upper_case_component(
                          Stdlib.__FUNCTION__,
                          () => React.null,
                        ),
                    })
                );
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "lident": lola,
                      "ldotlident": Module.lola,
                      "ldotdotlident": Module.Inner.lola,
                      "lapply": Label.t(int, string),
                    },
                  ) =>
                make(
                  ~key?,
                  ~lident=Props#lident,
                  ~ldotlident=Props#ldotlident,
                  ~ldotdotlident=Props#ldotdotlident,
                  ~lapply=Props#lapply,
                  (),
                );
            };
  };
  module Prop_with_option_annotation = {
    include {
              let makeProps = (~name: option(string), ~count: option(int), ()) => {
                let __js_obj_cell_0 = Stdlib.ref(name);
                let __js_obj_cell_1 = Stdlib.ref(count);
                let __js_obj = {
                  as _;
                  pub name = __js_obj_cell_0^;
                  pub count = __js_obj_cell_1^
                };
                (
                  Js.Obj.Internal.register_deferred_abstract(__js_obj, () =>
                    [
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="name",
                        ~js_name="name",
                        ~present=true,
                        __js_obj_cell_0,
                      ),
                      Js.Obj.Internal.deferred_entry(
                        ~method_name="count",
                        ~js_name="count",
                        ~present=true,
                        __js_obj_cell_1,
                      ),
                    ]
                  ): {
                    .
                    "name": option(string),
                    "count": option(int),
                  }
                );
              };
              let make = (~key: option(string)=?, ~name: option(string)) =>
                [@warning "-16"]
                (
                  (~count: option(int), ()) =>
                    React.Client_component({
                      key,
                      import_module:
                        Printf.sprintf(
                          "%s#%s",
                          "output.ml",
                          "Prop_with_option_annotation",
                        ),
                      import_name: "",
                      props: [
                        (
                          "name",
                          RSC.to_model([%to_rsc: option(string)](name)),
                        ),
                        (
                          "count",
                          RSC.to_model([%to_rsc: option(int)](count)),
                        ),
                      ],
                      client:
                        [@implicit_arity]
                        React.Upper_case_component(
                          Stdlib.__FUNCTION__,
                          () => React.null,
                        ),
                    })
                );
              let make =
                  (
                    ~key: option(string)=?,
                    Props: {
                      .
                      "name": option(string),
                      "count": option(int),
                    },
                  ) =>
                make(~key?, ~name=Props#name, ~count=Props#count, ());
            };
  };
