module Labels = struct
  let[@react.component] make ~children = React.string (String.concat "," (Array.to_list children))
end

type child = { label : string }

module Label = struct
  let[@react.component] make ~children = React.string children.label
end

module Text = struct
  let[@react.component] make ~children = React.string children
end

let () =
  let array = [| "first"; "second" |] in
  assert (ReactDOM.renderToStaticMarkup (Labels.createElement ~children:[ array ] () [@JSX]) = "first,second");
  let record = { label = "record child" } in
  assert (ReactDOM.renderToStaticMarkup (Label.createElement ~children:[ record ] () [@JSX]) = "record child");
  let string = String.concat " " [ "string"; "child" ] in
  assert (ReactDOM.renderToStaticMarkup (Text.createElement ~children:[ string ] () [@JSX]) = "string child")
