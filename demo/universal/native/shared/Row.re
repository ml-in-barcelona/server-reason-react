[@react.component]
let make =
    (
      ~gap=0,
      ~align: Theme.align=`start,
      ~justify: Theme.justify=`around,
      ~fullHeight=false,
      ~fullWidth=false,
      ~children,
    ) => {
  let className =
    Cx.make([
      "flex row",
      fullHeight ? "h-full" : "h-auto",
      fullWidth ? "w-full" : "w-auto",
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
