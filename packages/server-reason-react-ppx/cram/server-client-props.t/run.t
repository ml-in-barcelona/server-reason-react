
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
          ~tuple3: (int, string, float),
          (),
        ) =>
      React.Client_component({
        import_module: __FILE__,
        import_name: "",
        props: [
          ("prop", React.RSC_value_Json([%to_json: int](prop))),
          ("lola", React.RSC_value_Json([%to_json: list(int)](lola))),
          ("mona", React.RSC_value_Json([%to_json: array(float)](mona))),
          ("lolo", React.RSC_value_Json([%to_json: string](lolo))),
          ("lili", React.RSC_value_Json([%to_json: bool](lili))),
          ("lulu", React.RSC_value_Json([%to_json: float](lulu))),
          ("tuple2", React.RSC_value_Json([%to_json: (int, int)](tuple2))),
          (
            "tuple3",
            React.RSC_value_Json([%to_json: (int, string, float)](tuple3)),
          ),
        ],
        client: React.null,
      });
  };
  module Prop_without_annotation = {
    let make = (~key as _: option(string)=?, ~prop_without_annotation, ()) =>
      React.Client_component({
        import_module: __FILE__,
        import_name: "",
        props: [
          [%ocaml.error
            "server-reason-react: client components need type annotations. Missing annotation for 'prop_without_annotation'"
          ],
        ],
        client: React.null,
      });
  };
  module Prop_with_unsupported_annotation = {
    let make =
        (~key as _: option(string)=?, ~underscore: _, ~alpha_types: 'a, ()) =>
      React.Client_component({
        import_module: __FILE__,
        import_name: "",
        props: [
          ("underscore", React.RSC_value_Json([%to_json: _](underscore))),
          ("alpha_types", React.RSC_value_Json([%to_json: 'a](alpha_types))),
        ],
        client: React.null,
      });
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
        import_module: __FILE__,
        import_name: "",
        props: [
          (
            "polyvariants",
            React.RSC_value_Json(
              [%to_json:
                [
                  | `A
                  | `B
                ]
              ](polyvariants),
            ),
          ),
        ],
        client: React.null,
      });
  };
  module Prop_with_unknown_annotation = {
    let make =
        (
          ~key as _: option(string)=?,
          ~lident: lola,
          ~ldotlident: Module.lola,
          ~ldotdotlident: Module.Inner.lola,
          ~lapply: Label.t(int, string),
          (),
        ) =>
      React.Client_component({
        import_module: __FILE__,
        import_name: "",
        props: [
          ("lident", React.RSC_value_Json([%to_json: lola](lident))),
          (
            "ldotlident",
            React.RSC_value_Json([%to_json: Module.lola](ldotlident)),
          ),
          (
            "ldotdotlident",
            React.RSC_value_Json([%to_json: Module.Inner.lola](ldotdotlident)),
          ),
          (
            "lapply",
            React.RSC_value_Json([%to_json: Label.t(int, string)](lapply)),
          ),
        ],
        client: React.null,
      });
  };
