type mode =
  | FullScreen
  | Fit800px;

[@react.component]
let make = (~children, ~background=Theme.Color.black, ~mode=Fit800px) => {
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
          Theme.text(Theme.Color.white),
          Theme.hover([Theme.text(Theme.Color.brokenWhite)]),
        ])}
        href=Router.home>
        <Arrow direction=Left />
        {React.string("Home")}
      </a>
    </nav>
    <div spellCheck=false className={Cx.make(["w-full", "pt-12"])}>
      children
    </div>
  </div>;
};
