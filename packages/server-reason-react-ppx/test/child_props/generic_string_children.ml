module Text = struct
  let[@react.component] make ~children = React.string children
end

let () =
  let value = String.concat " " [ "string"; "child" ] in
  let element = (Text.createElement ~children:[ value ] () [@JSX]) in
  assert (ReactDOM.renderToStaticMarkup element = "string child")
