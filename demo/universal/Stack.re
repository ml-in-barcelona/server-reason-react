[@react.component]
let make =
    (~gap=0, ~align=`start, ~justify=`around, ~fullHeight=false, ~children) => {
  let className =
    Cx.make([
      "flex flex-col",
      fullHeight ? "h-full" : "h-auto",
      "gap-" ++ Int.to_string(gap),
      switch (align) {
      | `start => "items-start"
      | `center => "items-center"
      | `end_ => "items-end"
      },
      switch (justify) {
      | `around => "justify-around"
      | `between => "justify-between"
      | `evenly => "justify-evenly"
      | `start => "justify-start"
      | `center => "justify-center"
      | `end_ => "justify-end"
      },
    ]);

  <div className> children </div>;
};
