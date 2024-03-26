let unsafeWhenNotZero = (prop, value) =>
  if (value == 0) {
    [];
  } else {
    [prop ++ "-" ++ Int.to_string(value)];
  };

[@react.component]
let make = (~children=?, ~top=0, ~left=0, ~right=0, ~bottom=0, ~all=0) => {
  let className =
    Cx.make(
      List.flatten([
        unsafeWhenNotZero("mt", top),
        unsafeWhenNotZero("mb", bottom),
        unsafeWhenNotZero("ml", left),
        unsafeWhenNotZero("mr", right),
        unsafeWhenNotZero("m", all),
      ]),
    );

  <div className>
    {switch (children) {
     | None => React.null
     | Some(c) => c
     }}
  </div>;
};
