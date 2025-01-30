let defaultSize = Text.Medium;

module Base = {
  [@react.component]
  let make = (~size, ~color, ~href, ~children, ~underline, ~target=?) => {
    <a
      href
      ?target
      className={Cx.make([
        Text.size_to_string(size),
        "inline-flex items-center",
        underline ? "underline" : "",
        "transition-colors duration-250 ease-out",
        Theme.text(color),
        Theme.hover([
          Theme.text(Theme.Color.oneScaleUp(color)),
          underline ? "underline" : "",
        ]),
      ])}>
      children
    </a>;
  };
};

module Text = {
  [@react.component]
  let make =
      (
        ~color=Theme.Color.Gray13,
        ~size=defaultSize,
        ~href,
        ~children,
        ~target=?,
      ) => {
    <Base size href color ?target underline=true>
      {React.string(children)}
    </Base>;
  };
};

module WithArrow = {
  [@react.component]
  let make =
      (
        ~color=Theme.Color.Gray13,
        ~size=defaultSize,
        ~href,
        ~children,
        ~target=?,
      ) => {
    <Base size href color ?target underline=false>
      {React.string(children)}
      <Arrow />
    </Base>;
  };
};
