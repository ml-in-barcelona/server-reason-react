type mode =
  | FullScreen
  | Fit800px;

[@react.component]
let make = (~children, ~background=Theme.Color.Gray2, ~mode=Fit800px) => {
  <div
    className={Cx.make([
      "m-0",
      "p-8",
      "min-w-[100vw]",
      "min-h-[100vh]",
      switch (mode) {
      | FullScreen => "h-100vh w-100vw"
      | Fit800px => "h-full w-[800px]"
      },
      "flex",
      "flex-col",
      "items-center",
      "justify-start",
      Theme.background(background),
    ])}>
    <nav className="w-full mt-10">
      <a
        className={Cx.make([
          "text-s font-bold inline-flex items-center justify-between gap-2",
          Theme.text(Theme.Color.Gray12),
          Theme.hover([Theme.text(Theme.Color.Gray10)]),
        ])}
        href=Router.home>
        <Arrow direction=Left />
        {React.string("Home")}
      </a>
    </nav>
    <div spellCheck=false className="w-full pt-6 max-w-[1200px]">
      children
    </div>
  </div>;
};
