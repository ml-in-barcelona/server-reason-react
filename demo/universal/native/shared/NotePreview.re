[@react.component]
let make = (~body: string) => {
  <span
    className={Cx.make([
      "markdown",
      "block w-full p-8 rounded-md",
      Theme.background(Theme.Color.Gray4),
      Theme.text(Theme.Color.Gray12),
    ])}
    dangerouslySetInnerHTML={ "__html": body }
  />;
};
