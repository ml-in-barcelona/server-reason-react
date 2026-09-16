module Forward = {
  [@react.component]
  let make = (~children) => <div> {React.list([children])} </div>;
};

module TypedForward = {
  [@react.component]
  let make = (~children: React.element) =>
    <div> {React.list([children])} </div>;
};

module Text = {
  [@react.component]
  let make = (~children) => <span> {React.string(children)} </span>;
};

let child = <span> {React.string("Hello")} </span>;

let cases = [
  ("unannotated variable", <Forward> child </Forward>),
  ("typed variable", <TypedForward> child </TypedForward>),
  (
    "direct JSX",
    <Forward> <span> {React.string("Hello")} </span> </Forward>,
  ),
  ("string prop", <Text> "Hello" </Text>),
  (
    "typed dynamic list",
    <TypedForward> {React.list([child])} </TypedForward>,
  ),
];

let () = {
  let env =
    switch (Sys.argv[1]) {
    | "default" => None
    | "Prod" => Some(`Prod)
    | "Dev" => Some(`Dev)
    | _ => invalid_arg("expected default, Prod, or Dev")
    };
  List.iter(
    ((label, element)) => {
      print_endline(label ++ ":");
      Lwt_main.run(
        ReactServerDOM.render_model(
          ~env?,
          ~subscribe=
            row => {
              print_string(row);
              Lwt.return_unit;
            },
          element,
        ),
      );
      print_endline("HTML: " ++ ReactDOM.renderToStaticMarkup(element));
    },
    cases,
  );
};
