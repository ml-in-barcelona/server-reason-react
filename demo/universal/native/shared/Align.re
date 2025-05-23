type verticalAlign = [
  | `top
  | `center
  | `bottom
];
type horizontalAlign = [
  | `left
  | `center
  | `right
];

[@react.component]
let make = (~h: horizontalAlign=`center, ~v: verticalAlign=`center, ~children) => {
  let className =
    Cx.make([
      "flex flex-col h-full w-full",
      switch (h) {
      | `left => "items-start"
      | `center => "items-center"
      | `right => "items-end"
      },
      switch (v) {
      | `top => "justify-start"
      | `center => "justify-center"
      | `bottom => "justify-end"
      },
    ]);

  <div className> children </div>;
};
