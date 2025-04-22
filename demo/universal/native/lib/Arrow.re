type direction =
  | Left
  | Right;

[@react.component]
let make = (~direction: direction=Right) => {
  <svg
    className={Cx.make([
      "w-3 h-3 ms-2",
      switch (direction) {
      | Left => "transform -rotate-180"
      | Right => ""
      },
    ])}
    ariaHidden=true
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 14 10">
    <path
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      d="M1 5h12m0 0L9 1m4 4L9 9"
    />
  </svg>;
};
