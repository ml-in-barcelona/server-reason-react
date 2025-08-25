type mode =
  | FullScreen
  | Fit;

[@react.component]
let make = (~children, ~background=Theme.Color.Gray2, ~mode=Fit) => {
  <div
    className={Cx.make([
      "m-0",
      "p-8",
      "min-w-[100vw]",
      "min-h-[100vh]",
      switch (mode) {
      | FullScreen => "h-100vh w-100vw"
      | Fit => "h-full w-[1200px]"
      },
      "flex",
      "flex-col",
      "items-center",
      "justify-start",
      Theme.background(background),
    ])}>
    <nav
      className={Cx.make([
        "w-full mt-10",
        switch (mode) {
        | FullScreen => "w-full"
        | Fit => "max-w-[1200px]"
        },
      ])}>
      <a
        className={Cx.make([
          "text-s font-bold inline-flex items-center justify-between gap-2",
          Theme.text(Theme.Color.Gray12),
          Theme.hover([Theme.text(Theme.Color.Gray10)]),
        ])}
        href=Routes.home>
        <Arrow direction=Left />
        {React.string("Home")}
      </a>
    </nav>
    <div
      spellCheck=false
      className={Cx.make([
        "w-full pt-6",
        switch (mode) {
        | FullScreen => "max-w-full"
        | Fit => "max-w-[1200px]"
        },
      ])}>
      children
    </div>
  </div>;
};
