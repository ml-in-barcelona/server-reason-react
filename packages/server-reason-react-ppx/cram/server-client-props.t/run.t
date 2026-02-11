
  $ ../ppx.sh --output re input.re
  module Prop_with_many_annotation = {
    let make =
        (
          ~key as _: option(string)=?,
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
            import_module:
              Printf.sprintf("%s#%s", "output.ml", "Prop_with_many_annotation"),
            import_name: "",
            props: [
              ("prop", React.Model.Json([%to_json: int](prop))),
              ("lola", React.Model.Json([%to_json: list(int)](lola))),
              ("mona", React.Model.Json([%to_json: array(float)](mona))),
              ("lolo", React.Model.Json([%to_json: string](lolo))),
              ("lili", React.Model.Json([%to_json: bool](lili))),
              ("lulu", React.Model.Json([%to_json: float](lulu))),
              ("tuple2", React.Model.Json([%to_json: (int, int)](tuple2))),
              (
                "tuple3",
                React.Model.Json([%to_json: (int, string, float)](tuple3)),
              ),
            ],
            client:
              [@implicit_arity]
              React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
          })
      );
  };
  module Prop_without_annotation = {
    let make = (~key as _: option(string)=?, ~prop_without_annotation, ()) =>
      React.Client_component({
        import_module:
          Printf.sprintf("%s#%s", "output.ml", "Prop_without_annotation"),
        import_name: "",
        props: [
          [%ocaml.error
            "server-reason-react: client components need type annotations. Missing annotation for 'prop_without_annotation'"
          ],
        ],
        client:
          [@implicit_arity]
          React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
      });
  };
  module Prop_with_unsupported_annotation = {
    let make = (~key as _: option(string)=?, ~underscore: _) =>
      [@warning "-16"]
      (
        (~alpha_types: 'a, ()) =>
          React.Client_component({
            import_module:
              Printf.sprintf(
                "%s#%s",
                "output.ml",
                "Prop_with_unsupported_annotation",
              ),
            import_name: "",
            props: [
              ("underscore", React.Model.Json([%to_json: _](underscore))),
              ("alpha_types", React.Model.Json([%to_json: 'a](alpha_types))),
            ],
            client:
              [@implicit_arity]
              React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
          })
      );
  };
  module Prop_with_annotation_that_need_to_be_type_alias = {
    let make =
        (
          ~key as _: option(string)=?,
          ~polyvariants: [
             | `A
             | `B
           ],
          (),
        ) =>
      React.Client_component({
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
          React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
      });
  };
  module Prop_with_unknown_annotation = {
    let make =
        (
          ~key as _: option(string)=?,
          ~lident: lola,
          ~ldotlident: Module.lola,
          ~ldotdotlident: Module.Inner.lola,
        ) =>
      [@warning "-16"]
      (
        (~lapply: Label.t(int, string), ()) =>
          React.Client_component({
            import_module:
              Printf.sprintf(
                "%s#%s",
                "output.ml",
                "Prop_with_unknown_annotation",
              ),
            import_name: "",
            props: [
              ("lident", React.Model.Json([%to_json: lola](lident))),
              (
                "ldotlident",
                React.Model.Json([%to_json: Module.lola](ldotlident)),
              ),
              (
                "ldotdotlident",
                React.Model.Json([%to_json: Module.Inner.lola](ldotdotlident)),
              ),
              (
                "lapply",
                React.Model.Json([%to_json: Label.t(int, string)](lapply)),
              ),
            ],
            client:
              [@implicit_arity]
              React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
          })
      );
  };
  module Prop_with_option_annotation = {
    let make = (~key as _: option(string)=?, ~name: option(string)) =>
      [@warning "-16"]
      (
        (~count: option(int), ()) =>
          React.Client_component({
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
                | Some(value) => React.Model.Json([%to_json: string](value))
                | None => React.Model.Json(`Null)
                },
              ),
              (
                "count",
                switch (count) {
                | Some(value) => React.Model.Json([%to_json: int](value))
                | None => React.Model.Json(`Null)
                },
              ),
            ],
            client:
              [@implicit_arity]
              React.Upper_case_component(Stdlib.__FUNCTION__, () => React.null),
          })
      );
  };
