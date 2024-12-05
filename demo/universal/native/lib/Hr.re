[@react.component]
let make = () => {
  <hr
    className={Cx.make([
      "block",
      "w-full",
      "h-px",
      Theme.border("gray-700"),
    ])}
  />;
};
