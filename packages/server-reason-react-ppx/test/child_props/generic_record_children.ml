type child = { label : string }

module Label = struct
  let[@react.component] make ~children = React.string children.label
end

let () =
  let value = { label = "record child" } in
  let element = (Label.createElement ~children:[ value ] () [@JSX]) in
  assert (ReactDOM.renderToStaticMarkup element = "record child")
