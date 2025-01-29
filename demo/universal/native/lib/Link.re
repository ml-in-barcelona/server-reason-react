let defaultSize = Text.Medium;

module Base = {
  [@react.component]
  let make = (~size=defaultSize, ~href, ~children) => {
    <a
      href
      onClick={_e => print_endline("clicked")}
      className={Cx.make([
        Text.size_to_string(size),
        "inline-flex",
        "items-center",
        Theme.text(Theme.Color.Gray11),
        Theme.hover(["underline", Theme.text(Theme.Color.Gray10)]),
      ])}>
      children
    </a>;
  };
};

module Text = {
  [@react.component]
  let make = (~size=defaultSize, ~href, ~children) => {
    <Base size href> {React.string(children)} </Base>;
  };
};

module WithArrow = {
  [@react.component]
  let make = (~size=defaultSize, ~href, ~children) => {
    <Base size href> {React.string(children)} <Arrow /> </Base>;
  };
};
