[@react.component]
let make = (~rows=10, ~value, ~onChange, ~id="", ~placeholder="") =>
  <textarea
    className={Cx.make([
      "m-0 py-2 px-4",
      "rounded-md",
      Theme.background(Theme.Color.Gray1),
      Theme.text(Theme.Color.Gray12),
    ])}
    id
    placeholder
    rows
    value
    onChange
  />;
