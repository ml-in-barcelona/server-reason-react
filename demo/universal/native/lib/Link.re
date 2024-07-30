module Base = {
  [@react.component]
  let make = (~href, ~children) => {
    <a
      href
      onClick={_e => print_endline("clicked")}
      className={Cx.make([
        "font-medium",
        "flex",
        "items-center",
        Theme.text(Theme.Color.white),
        Theme.hover(["underline", Theme.text(Theme.Color.brokenWhite)]),
      ])}>
      children
    </a>;
  };
};

module Text = {
  [@react.component]
  let make = (~href, ~children) => {
    <Base href> {React.string(children)} </Base>;
  };
};

module WithArrow = {
  [@react.component]
  let make = (~href, ~children) => {
    <Base href> {React.string(children)} <Arrow /> </Base>;
  };
};
