
  $ ../ppx.sh --output re input.re -js
  module Prop_with_many_annotation = {
    include {
              [@react.component]
              let make = (~initial: int, ~lola: lola) =>
                <div> {React.string(lola.name)} {React.int(initial)} </div>;
              let make_client = props =>
                make({
                  "lola": [%of_json: lola](props##lola),
                  "initial": [%of_json: int](props##initial),
                });
            };
  };
