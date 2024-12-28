
  $ ../ppx.sh --output re input.re -js
  module Prop_with_many_annotation = {
    include {
              [@react.component]
              let make = (~type_alias: a_type_alias, ~second: string) =>
                <div> {React.string(prop.name)} </div>;
              let _client = props =>
                make({
                  "second": props##second,
                  "type_alias": a_type_alias_of_json(props##type_alias),
                });
            };
  };
