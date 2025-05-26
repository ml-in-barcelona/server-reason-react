[@react.component]
let make = (~value, ~onChange, ~id="", ~placeholder="") =>
  <input
    className={Cx.make([
      "m-0 py-2 px-4",
      "rounded-md",
      Theme.background(Theme.Color.Gray1),
      Theme.text(Theme.Color.Gray12),
    ])}
    id
    placeholder
    type_="text"
    value
    onChange
  />;
