[@react.component]
let make = () => {
  <hr
    className={Cx.make([
      "block",
      "w-full",
      "h-[1px]",
      "border-0 border-b-2",
      Theme.border("gray-700"),
    ])}
  />;
};
