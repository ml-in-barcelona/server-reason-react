module React_component_without_props = {
  [@warning "-27"]
  let make = (~lola, ~key, ()) =>
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [React.string(lola)],
    );
};

let make = () => React_component_without_props.make(~lola="flores", ~key=Some("key"), ());
