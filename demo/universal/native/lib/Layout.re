[@react.component]
let make = (~children, ~background) => {
  <div
    className={Cx.make([
      "m-0",
      "p-8",
      "w-[100vw]",
      "h-[100vh]",
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
    <div spellCheck=false className={Cx.make(["pt-12"])}> children </div>
  </div>;
};
