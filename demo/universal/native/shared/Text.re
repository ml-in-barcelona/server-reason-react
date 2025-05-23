type size =
  | XSmall
  | Small
  | Medium
  | Large
  | XLarge
  | XXLarge
  | XXXLarge;

let size_to_string = size =>
  switch (size) {
  | XSmall => "text-xs"
  | Small => "text-sm"
  | Medium => "text-base"
  | Large => "text-lg"
  | XLarge => "text-xl"
  | XXLarge => "text-2xl"
  | XXXLarge => "text-3xl"
  };

type weight =
  | Thin
  | Light
  | Regular
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
      ~color=Theme.Color.Gray12,
      ~size: size=Small,
      ~weight: weight=Regular,
      ~align=Left,
      ~children,
      ~role=?,
    ) => {
  let className =
    Cx.make([
      Theme.text(color),
      size_to_string(size),
      switch (weight) {
      | Thin => "font-thin"
      | Light => "font-light"
      | Regular => "font-normal"
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

  <span className ?role> {React.string(children)} </span>;
};
