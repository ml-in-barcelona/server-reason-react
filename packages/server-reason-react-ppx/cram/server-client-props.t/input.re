module Prop_with_many_annotation = {
  [@react.client.component]
  let make =
      (
        ~prop: int,
        ~lola: list(int),
        ~mona: array(float),
        ~lolo: string,
        ~lili: bool,
        ~lulu: float,
        ~tuple2: (int, int),
        ~tuple3: (int, string, float),
      ) => React.null;
};

module Prop_without_annotation = {
  [@react.client.component]
  let make = (~prop_without_annotation) => React.null;
};

module Prop_with_unsupported_annotation = {
  [@react.client.component]
  let make = (~underscore: _, ~alpha_types: 'a) => React.null;
};

module Prop_with_annotation_that_need_to_be_type_alias = {
  [@react.client.component]
  let make =
      (
        ~polyvariants: [
           | `A
           | `B
         ],
      ) => React.null;
};

module Prop_with_unknown_annotation = {
  [@react.client.component]
  let make =
      (
        ~lident: lola,
        ~ldotlident: Module.lola,
        ~ldotdotlident: Module.Inner.lola,
        ~lapply: Label.t(int, string),
      ) => React.null;
};

module Prop_with_suspense = {
  module Async_component = {
    [@react.async.component]
    let make = () => Lwt.return(React.string("Async Component"));
  };
  module Client_component = {
    [@react.client.component]
    let make = (~children: React.element) => children;
  };
  [@react.component]
  let make = () => <Client_component> <Async_component /> </Client_component>;
};
