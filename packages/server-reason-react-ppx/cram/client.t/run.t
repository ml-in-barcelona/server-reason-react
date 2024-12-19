
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
        import_module: __MODULE__,
        import_name: "",
        props: [
          ("prop", React.Json(`Int(prop))),
          ("lola", React.Json(`List(Stdlib.List.map(x => `Int(x), lola)))),
          (
            "mona",
            React.Json(
              `List(
                Stdlib.Array.to_list(Stdlib.Array.map(x => `Float(x), mona)),
              ),
            ),
          ),
          ("lolo", React.Json(`String(lolo))),
          ("lili", React.Json(`Bool(lili))),
          ("lulu", React.Json(`Float(lulu))),
          (
            "tuple2",
            React.Json(
              {
                let (x0, x1) = tuple2;
                `List([`Int(x0), `Int(x1)]);
              },
            ),
          ),
          (
            "tuple3",
            React.Json(
              {
                let (x0, x1, x2) = tuple3;
                `List([`Int(x0), `String(x1), `Float(x2)]);
              },
            ),
          ),
        ],
        client: React.null,
      });
  };
  module Prop_without_annotation = {
    let make = (~key as _: option(string)=?, ~prop_without_annotation, ()) =>
      React.Client_component({
        import_module: __MODULE__,
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
        import_module: __MODULE__,
        import_name: "",
        props: [
          (
            "underscore",
            React.Json(
              [%ocaml.error
                "server-reason-react: '_' annotations aren't supported in client components. Try using a type definition with a json encoder but there's no guarantee that it will work. Open an issue if you need it."
              ],
            ),
          ),
          (
            "alpha_types",
            React.Json(
              [%ocaml.error "server-reason-react: unsupported type: 'a"],
            ),
          ),
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
        import_module: __MODULE__,
        import_name: "",
        props: [
          (
            "polyvariants",
            React.Json(
              [%ocaml.error
                "server-reason-react: inline types such as polyvariants, need to be a type definition with a json encoder. If the type is named 't' the encoder should be named 't_to_json', if the type is named 'foo' the encoder should be named 'foo_to_json'."
              ],
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
        import_module: __MODULE__,
        import_name: "",
        props: [
          ("lident", React.Json(lola_to_json(lident))),
          ("ldotlident", React.Json(Module.lola_to_json(ldotlident))),
          (
            "ldotdotlident",
            React.Json(Module.Inner.lola_to_json(ldotdotlident)),
          ),
          ("lapply", React.Json(Label.t_to_json(lapply))),
        ],
        client: React.null,
      });
  };
