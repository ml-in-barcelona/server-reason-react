module Prop_with_many_annotation = {
  [@client]
  let make = (~prop: a_type_alias) => <div> {React.string(prop.name)} </div>;
  /* let _client = props => make(~prop=props##a_type_alias_of_json(prop), ()); */
};
