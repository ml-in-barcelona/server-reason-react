module Joe = {
  [@react.component]
  let make = (~name="joe") => {
    <div> {Printf.sprintf("`name` is %s", name) |> React.string} </div>;
  };
};

/* let test_bool_attributes () =
  let a =
    React.createElement "input"
      [ React.Attribute.String ("type", "checkbox")
      ; React.Attribute.String ("name", "cheese")
      ; React.Attribute.Bool ("checked", true)
      ; React.Attribute.Bool ("disabled", false)
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup a)
    "<input type=\"checkbox\" name=\"cheese\" checked />" */
