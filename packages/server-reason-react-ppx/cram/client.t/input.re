module Prop_with_many_annotation = {
  [@client]
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
  [@client]
  let make = (~prop_without_annotation) => React.null;
};

module Prop_with_unsupported_annotation = {
  [@client]
  let make = (~underscore: _, ~alpha_types: 'a) => React.null;
};

module Prop_with_annotation_that_need_to_be_type_alias = {
  [@client]
  let make =
      (
        ~polyvariants: [
           | `A
           | `B
         ],
      ) => React.null;
};

module Prop_with_unknown_annotation = {
  [@client]
  let make =
      (
        ~lident: lola,
        ~ldotlident: Module.lola,
        ~ldotdotlident: Module.Inner.lola,
        ~lapply: Label.t(int, string),
      ) => React.null;
};
