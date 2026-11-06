module Forward = {
  [@react.component]
  let make = (~children) => <div> children </div>;
};

module ForwardList = {
  [@react.component]
  let make = (~children) => <div> {React.list([children])} </div>;
};

module TypedForwardList = {
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
  ("host slot", <Forward> child </Forward>),
  (
    "two literal children",
    <Forward> child <span> {React.string("World")} </span> </Forward>,
  ),
  ("unannotated variable in a list", <ForwardList> child </ForwardList>),
  ("typed variable in a list", <TypedForwardList> child </TypedForwardList>),
  (
    "direct JSX in a list",
    <ForwardList> <span> {React.string("Hello")} </span> </ForwardList>,
  ),
  ("string prop", <Text> "Hello" </Text>),
  ("dynamic list", <Forward> {React.list([child])} </Forward>),
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
