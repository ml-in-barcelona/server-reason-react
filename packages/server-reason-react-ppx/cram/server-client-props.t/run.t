
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="prop",
                    ~js_name="prop",
                    ~present=true,
                    prop,
                  );
                let (__js_obj_cell_1, __js_obj_entry_1) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lola",
                    ~js_name="lola",
                    ~present=true,
                    lola,
                  );
                let (__js_obj_cell_2, __js_obj_entry_2) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="mona",
                    ~js_name="mona",
                    ~present=true,
                    mona,
                  );
                let (__js_obj_cell_3, __js_obj_entry_3) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lolo",
                    ~js_name="lolo",
                    ~present=true,
                    lolo,
                  );
                let (__js_obj_cell_4, __js_obj_entry_4) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lili",
                    ~js_name="lili",
                    ~present=true,
                    lili,
                  );
                let (__js_obj_cell_5, __js_obj_entry_5) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lulu",
                    ~js_name="lulu",
                    ~present=true,
                    lulu,
                  );
                let (__js_obj_cell_6, __js_obj_entry_6) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="tuple2",
                    ~js_name="tuple2",
                    ~present=true,
                    tuple2,
                  );
                let (__js_obj_cell_7, __js_obj_entry_7) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="tuple3",
                    ~js_name="tuple3",
                    ~present=true,
                    tuple3,
                  );
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
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [
                      __js_obj_entry_0,
                      __js_obj_entry_1,
                      __js_obj_entry_2,
                      __js_obj_entry_3,
                      __js_obj_entry_4,
                      __js_obj_entry_5,
                      __js_obj_entry_6,
                      __js_obj_entry_7,
                    ],
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
                        ("prop", React.Model.Json([%to_json: int](prop))),
                        (
                          "lola",
                          React.Model.Json([%to_json: list(int)](lola)),
                        ),
                        (
                          "mona",
                          React.Model.Json([%to_json: array(float)](mona)),
                        ),
                        ("lolo", React.Model.Json([%to_json: string](lolo))),
                        ("lili", React.Model.Json([%to_json: bool](lili))),
                        ("lulu", React.Model.Json([%to_json: float](lulu))),
                        (
                          "tuple2",
                          React.Model.Json([%to_json: (int, int)](tuple2)),
                        ),
                        (
                          "tuple3",
                          React.Model.Json(
                            [%to_json: (int, string, float)](tuple3),
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="prop_without_annotation",
                    ~js_name="prop_without_annotation",
                    ~present=true,
                    prop_without_annotation,
                  );
                let __js_obj = {
                  as _;
                  pub prop_without_annotation = __js_obj_cell_0^
                };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [__js_obj_entry_0],
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="underscore",
                    ~js_name="underscore",
                    ~present=true,
                    underscore,
                  );
                let (__js_obj_cell_1, __js_obj_entry_1) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="alpha_types",
                    ~js_name="alpha_types",
                    ~present=true,
                    alpha_types,
                  );
                let __js_obj = {
                  as _;
                  pub underscore = __js_obj_cell_0^;
                  pub alpha_types = __js_obj_cell_1^
                };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [__js_obj_entry_0, __js_obj_entry_1],
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
                          React.Model.Json([%to_json: _](underscore)),
                        ),
                        (
                          "alpha_types",
                          React.Model.Json([%to_json: 'a](alpha_types)),
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="polyvariants",
                    ~js_name="polyvariants",
                    ~present=true,
                    polyvariants,
                  );
                let __js_obj = { as _; pub polyvariants = __js_obj_cell_0^ };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [__js_obj_entry_0],
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
                      React.Model.Json(
                        [%to_json:
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lident",
                    ~js_name="lident",
                    ~present=true,
                    lident,
                  );
                let (__js_obj_cell_1, __js_obj_entry_1) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="ldotlident",
                    ~js_name="ldotlident",
                    ~present=true,
                    ldotlident,
                  );
                let (__js_obj_cell_2, __js_obj_entry_2) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="ldotdotlident",
                    ~js_name="ldotdotlident",
                    ~present=true,
                    ldotdotlident,
                  );
                let (__js_obj_cell_3, __js_obj_entry_3) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="lapply",
                    ~js_name="lapply",
                    ~present=true,
                    lapply,
                  );
                let __js_obj = {
                  as _;
                  pub lident = __js_obj_cell_0^;
                  pub ldotlident = __js_obj_cell_1^;
                  pub ldotdotlident = __js_obj_cell_2^;
                  pub lapply = __js_obj_cell_3^
                };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [
                      __js_obj_entry_0,
                      __js_obj_entry_1,
                      __js_obj_entry_2,
                      __js_obj_entry_3,
                    ],
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
                        (
                          "lident",
                          React.Model.Json([%to_json: lola](lident)),
                        ),
                        (
                          "ldotlident",
                          React.Model.Json(
                            [%to_json: Module.lola](ldotlident),
                          ),
                        ),
                        (
                          "ldotdotlident",
                          React.Model.Json(
                            [%to_json: Module.Inner.lola](ldotdotlident),
                          ),
                        ),
                        (
                          "lapply",
                          React.Model.Json(
                            [%to_json: Label.t(int, string)](lapply),
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
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="name",
                    ~js_name="name",
                    ~present=true,
                    name,
                  );
                let (__js_obj_cell_1, __js_obj_entry_1) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="count",
                    ~js_name="count",
                    ~present=true,
                    count,
                  );
                let __js_obj = {
                  as _;
                  pub name = __js_obj_cell_0^;
                  pub count = __js_obj_cell_1^
                };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [__js_obj_entry_0, __js_obj_entry_1],
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
                          switch (name) {
                          | Some(value) =>
                            React.Model.Json([%to_json: string](value))
                          | None => React.Model.Json(`Null)
                          },
                        ),
                        (
                          "count",
                          switch (count) {
                          | Some(value) =>
                            React.Model.Json([%to_json: int](value))
                          | None => React.Model.Json(`Null)
                          },
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
