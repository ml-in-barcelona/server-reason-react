module Labels = struct
  let[@react.component] make ~children = React.string (String.concat "," (Array.to_list children))
end

let () =
  let value = [| "first"; "second" |] in
  let element = (Labels.createElement ~children:[ value ] () [@JSX]) in
  assert (ReactDOM.renderToStaticMarkup element = "first,second")
