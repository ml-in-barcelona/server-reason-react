type size =
  | XSmall
  | Small
  | Medium
  | Large
  | XLarge
  | XXLarge
  | XXXLarge;

type weight =
  | Thin
  | Light
  | Regular
  | Medium
  | Semibold
  | Bold
  | Extrabold
  | Black;

type align =
  | Left
  | Center
  | Right
  | Justify;

[@react.component]
let make =
    (
      ~color,
      ~size: size=Small,
      ~weight: weight=Regular,
      ~align=Left,
      ~children,
    ) => {
  let className =
    Cx.make([
      Theme.text(color),
      switch (size) {
      | XSmall => "text-xs"
      | Small => "text-sm"
      | Medium => "text-base"
      | Large => "text-lg"
      | XLarge => "text-xl"
      | XXLarge => "text-2xl"
      | XXXLarge => "text-3xl"
      },
      switch (weight) {
      | Thin => "font-thin"
      | Light => "font-light"
      | Regular => "font-normal"
      | Medium => "font-medium"
      | Semibold => "font-semibold"
      | Bold => "font-bold"
      | Extrabold => "font-extrabold"
      | Black => "font-black"
      },
      switch (align) {
      | Left => "text-left"
      | Right => "text-right"
      | Justify => "text-justify"
      | Center => "text-center"
      },
    ]);

  <span className> {React.string(children)} </span>;
};
