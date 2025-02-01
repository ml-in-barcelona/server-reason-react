type align = [
  | `start
  | `center
  | `end_
];
type justify = [
  | `around
  | `between
  | `evenly
  | `start
  | `center
  | `end_
];

module Media = {
  let onDesktop = rules => {
    String.concat(" md:", rules);
  };
};

module Color = {
  type t =
    | None
    | Transparent
    | Gray0
    | Gray1
    | Gray2
    | Gray3
    | Gray4
    | Gray5
    | Gray6
    | Gray7
    | Gray8
    | Gray9
    | Gray10
    | Gray11
    | Gray12
    | Gray13
    | Gray14
    | Primary;

  let oneScaleUp = color => {
    switch (color) {
    | Gray0 => Gray1
    | Gray1 => Gray2
    | Gray2 => Gray3
    | Gray3 => Gray4
    | Gray4 => Gray5
    | Gray5 => Gray6
    | Gray6 => Gray7
    | Gray7 => Gray8
    | Gray8 => Gray9
    | Gray9 => Gray10
    | Gray10 => Gray11
    | Gray11 => Gray12
    | Gray12 => Gray13
    | Gray13 => Gray14
    | Gray14 => Gray14
    | _ => color
    };
  };

  let primary = "#FFC53D";
  let gray0 = "#080808";
  let gray1 = "#0F0F0F";
  let gray2 = "#151515";
  let gray3 = "#191919";
  let gray4 = "#1E1E1E";
  let gray5 = "#252525";
  let gray6 = "#2A2A2A";
  let gray7 = "#313131";
  let gray8 = "#3A3A3A";
  let gray9 = "#484848";
  let gray10 = "#6E6E6E";
  let gray11 = "#B4B4B4";
  let gray12 = "#EEEEEE";
  let gray13 = "#F5F5F5";
  let gray14 = "#FFFFFF";

  let brokenWhite = gray10;
  let white = gray12;
  let black = gray1;
  let fadedBlack = gray3;
};

let none = "none";

type kind =
  | Text
  | Background
  | Border;

let to_string = kind =>
  switch (kind) {
  | Text => "text"
  | Background => "bg"
  | Border => "border"
  };

let color = (~kind, value) =>
  switch ((value: Color.t)) {
  | None => to_string(kind) ++ "-none"
  | Transparent => to_string(kind) ++ "-transparent"
  | Gray0 => to_string(kind) ++ "-[" ++ Color.gray0 ++ "]"
  | Gray1 => to_string(kind) ++ "-[" ++ Color.gray1 ++ "]"
  | Gray2 => to_string(kind) ++ "-[" ++ Color.gray2 ++ "]"
  | Gray3 => to_string(kind) ++ "-[" ++ Color.gray3 ++ "]"
  | Gray4 => to_string(kind) ++ "-[" ++ Color.gray4 ++ "]"
  | Gray5 => to_string(kind) ++ "-[" ++ Color.gray5 ++ "]"
  | Gray6 => to_string(kind) ++ "-[" ++ Color.gray6 ++ "]"
  | Gray7 => to_string(kind) ++ "-[" ++ Color.gray7 ++ "]"
  | Gray8 => to_string(kind) ++ "-[" ++ Color.gray8 ++ "]"
  | Gray9 => to_string(kind) ++ "-[" ++ Color.gray9 ++ "]"
  | Gray10 => to_string(kind) ++ "-[" ++ Color.gray10 ++ "]"
  | Gray11 => to_string(kind) ++ "-[" ++ Color.gray11 ++ "]"
  | Gray12 => to_string(kind) ++ "-[" ++ Color.gray12 ++ "]"
  | Gray13 => to_string(kind) ++ "-[" ++ Color.gray13 ++ "]"
  | Gray14 => to_string(kind) ++ "-[" ++ Color.gray14 ++ "]"
  | Primary => to_string(kind) ++ "-[" ++ Color.primary ++ "]"
  };

let text = value => color(~kind=Text, value);
let background = value => color(~kind=Background, value);
let border = value => color(~kind=Border, value);

let hover = value =>
  switch (value) {
  | [] => ""
  | [value] => " hover:" ++ value
  | values => " hover:" ++ String.concat(" hover:", values)
  };

let button =
  Cx.make([
    "px-4 py-1 border-2 rounded-md",
    "transition-[background-color] duration-250 ease-out",
    border(Color.Gray5),
    text(Color.Gray12),
    hover([background(Color.Gray6), border(Color.Gray7)]),
  ]);
