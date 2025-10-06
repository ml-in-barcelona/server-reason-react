
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
        import_module:
          Printf.sprintf("%s#%s", "output.ml", "Prop_with_many_annotation"),
        import_name: "",
        props: [
          ("prop", React.Json([%to_json: int](prop))),
          ("lola", React.Json([%to_json: list(int)](lola))),
          ("mona", React.Json([%to_json: array(float)](mona))),
          ("lolo", React.Json([%to_json: string](lolo))),
          ("lili", React.Json([%to_json: bool](lili))),
          ("lulu", React.Json([%to_json: float](lulu))),
          ("tuple2", React.Json([%to_json: (int, int)](tuple2))),
          ("tuple3", React.Json([%to_json: (int, string, float)](tuple3))),
        ],
        client: () => React.null,
      });
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
        client: () => React.null,
      });
  };
  module Prop_with_unsupported_annotation = {
    let make =
        (~key as _: option(string)=?, ~underscore: _, ~alpha_types: 'a, ()) =>
      React.Client_component({
        import_module:
          Printf.sprintf(
            "%s#%s",
            "output.ml",
            "Prop_with_unsupported_annotation",
          ),
        import_name: "",
        props: [
          ("underscore", React.Json([%to_json: _](underscore))),
          ("alpha_types", React.Json([%to_json: 'a](alpha_types))),
        ],
        client: () => React.null,
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
            React.Json(
              [%to_json:
                [
                  | `A
                  | `B
                ]
              ](polyvariants),
            ),
          ),
        ],
        client: () => React.null,
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
        import_module:
          Printf.sprintf("%s#%s", "output.ml", "Prop_with_unknown_annotation"),
        import_name: "",
        props: [
          ("lident", React.Json([%to_json: lola](lident))),
          ("ldotlident", React.Json([%to_json: Module.lola](ldotlident))),
          (
            "ldotdotlident",
            React.Json([%to_json: Module.Inner.lola](ldotdotlident)),
          ),
          ("lapply", React.Json([%to_json: Label.t(int, string)](lapply))),
        ],
        client: () => React.null,
      });
  };
  module Prop_with_suspense = {
    module Async_component = {
      let make = (~key as _: option(string)=?, ()) =>
        [@implicit_arity]
        React.Async_component(
          Stdlib.__FUNCTION__,
          () => Lwt.return(React.string("Async Component")),
        );
    };
    module Client_component = {
      let make = (~key as _: option(string)=?, ~children: React.element, ()) =>
        React.Client_component({
          import_module:
            Printf.sprintf(
              "%s#%s",
              "output.ml",
              "Async_component.Client_component",
            ),
          import_name: "",
          props: [("children", React.Element(children: React.element))],
          client: () => children,
        });
    };
    let make = (~key as _: option(string)=?, ()) =>
      [@implicit_arity]
      React.Upper_case_component(
        Stdlib.__FUNCTION__,
        () => Client_component.make(~children=Async_component.make(), ()),
      );
  };
