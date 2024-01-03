module ExternalLinkIcon = {
  [@react.component]
  let make = () => {
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      width="14px"
      height="14px"
      className="fill-slate-400 hover:fill-slate-200">
      <path
        d="M 5 3 C 3.9069372 3 3 3.9069372 3 5 L 3 19 C 3 20.093063 3.9069372 21 5 21 L 19 21 C 20.093063 21 21 20.093063 21 19 L 21 12 L 19 12 L 19 19 L 5 19 L 5 5 L 12 5 L 12 3 L 5 3 z M 14 3 L 14 5 L 17.585938 5 L 8.2929688 14.292969 L 9.7070312 15.707031 L 19 6.4140625 L 19 10 L 21 10 L 21 3 L 14 3 z"
      />
    </svg>;
  };
};

module Panel = {
  [@react.component]
  let make = (~children) => {
    <div
      className={Cx.make([
        "w-[100vw]",
        "pt-2 pb-2 pl-4 pr-4",
        Theme.background(Theme.Color.box),
      ])}>
      children
    </div>;
  };
};

module ShrinkerText = {
  [@react.component]
  let make = (~children, ~color) => {
    let first = children.[0] |> String.make(1);
    let rest = String.sub(children, 1, String.length(children) - 1);

    <>
      <span className={Cx.make([Theme.text(color)])}>
        {React.string(first)}
      </span>
      <span
        className={Cx.make([
          "cursor-pointer hidden",
          Theme.text(Theme.Color.white),
          Theme.Media.onDesktop(["inline"]),
        ])}>
        {React.string(rest)}
      </span>
    </>;
  };
};

module Logo = {
  [@react.component]
  let make = () => {
    <p className={Cx.make(["text-3xl", "font-bold", "margin-0"])}>
      <ShrinkerText color=Theme.Color.ahrefs> "ahrefs" </ShrinkerText>
    </p>;
  };
};

module Dropdown = {
  module Trigger = {
    [@react.component]
    let make = (~isOpen, ~onClick) => {
      <div
        onClick
        className={Cx.make([
          Theme.text(isOpen ? Theme.Color.white : Theme.Color.lightGrey),
          "cursor-pointer",
          "user-select-none",
          "text-base",
          "whitespace-nowrap",
          Theme.hover([Theme.text(Theme.Color.white)]),
        ])}>
        {React.string("More tools")}
      </div>;
    };
  };

  [@react.component]
  let make = (~items, ~onClick) => {
    let (isOpen, setIsOpen) = RR.useStateValue(false);

    <div className={Cx.make(["relative"])}>
      <Trigger isOpen onClick={_e => setIsOpen(!isOpen)} />
      {isOpen
         ? {
           <div
             className={Cx.make([
               "absolute",
               "top-4",
               "left-[-50%]",
               "p-4",
               "radius-3",
               Theme.background(Theme.Color.box),
             ])}>
             {React.array(
                Belt.Array.mapWithIndex(items, (key, item) =>
                  <div
                    key={Int.to_string(key)} className={Cx.make(["block"])}>
                    <span
                      onClick={_e => onClick(item)}
                      className={Cx.make([
                        Theme.text(Theme.Color.lightGrey),
                        "cursor-pointer",
                        "text-base",
                        "whitespace-nowrap",
                        Theme.hover([Theme.text(Theme.Color.white)]),
                      ])}>
                      {React.string(item)}
                    </span>
                  </div>
                ),
              )}
           </div>;
         }
         : React.null}
    </div>;
  };
};

module Menu = {
  module Dom = Webapi.Dom;
  let%browser_only getWindowHeight = () => Dom.window->Dom.Window.innerHeight;

  let%browser_only useOnResize = () => {
    let (windowHeight, setWindowHeight) =
      React.useState(_ => getWindowHeight());

    React.useEffect0(() => {
      open Webapi.Dom;
      let windowAsTarget = Window.asEventTarget(window);
      let handleResize = _ => setWindowHeight(_ => getWindowHeight());
      EventTarget.addEventListener("resize", handleResize, windowAsTarget);
      Some(
        () =>
          EventTarget.removeEventListener(
            "resize",
            handleResize,
            windowAsTarget,
          ),
      );
    });

    windowHeight;
  };

  [@react.component]
  let make = (~currentNavigate: string, ~navigate: string => unit) => {
    let (tools, _setTools) =
      RR.useStateValue([|
        "Dashboard",
        "Site Explorer",
        "Keywords Explorer",
        "Site Audit",
        "Rank Tracker",
        "Content Explorer",
      |]);

    let (moreTools, _setMoreTools) =
      RR.useStateValue([|
        "Alerts",
        "Ahrefs Rank",
        "Batch Analysis",
        "Link intersect",
        "SEO Toolbar",
        "WordPress Plugin",
        "Ahrefs API",
        "Apps",
      |]);

    let externalLinks = [|"Community", "Academy"|];

    <div
      className={Cx.make([
        "flex items-center justify-items-end gap-4 mt-px p-2",
      ])}>
      {React.array(
         Belt.Array.mapWithIndex(tools, (key, item) =>
           <div key={Int.to_string(key)} className={Cx.make(["block"])}>
             <span
               onClick={_e => navigate(item)}
               className={Cx.make([
                 currentNavigate == item
                   ? Theme.text(Theme.Color.white)
                   : Theme.text(Theme.Color.lightGrey),
                 "cursor-pointer",
                 "text-base",
                 "whitespace-nowrap",
                 Theme.hover([Theme.text(Theme.Color.white)]),
               ])}>
               {React.string(item)}
             </span>
           </div>
         ),
       )}
      <Dropdown items=moreTools onClick=navigate />
      <span
        className={Cx.make([
          Theme.text(Theme.Color.white),
          "text-base",
          "user-select-none",
        ])}>
        {React.string("|")}
      </span>
      {React.array(
         Belt.Array.mapWithIndex(externalLinks, (key, item) =>
           <div key={Int.to_string(key)} className={Cx.make(["block"])}>
             <span
               onClick={_e => navigate(item)}
               className={Cx.make([
                 currentNavigate == item
                   ? Theme.text(Theme.Color.white)
                   : Theme.text(Theme.Color.lightGrey),
                 "cursor-pointer",
                 "text-base",
                 "whitespace-nowrap",
                 Theme.hover([Theme.text(Theme.Color.white)]),
               ])}>
               <Row align=`center gap=1>
                 <span> {React.string(item)} </span>
                 <ExternalLinkIcon />
               </Row>
             </span>
           </div>
         ),
       )}
    </div>;
  };
};

module Layout = {
  [@react.component]
  let make = (~children) => {
    <div spellCheck=false className={Cx.make(["h-52"])}> children </div>;
  };
};

[@react.component]
let make = () => {
  let (currentNavigate, setNavigate) = RR.useStateValue("Dashboard");

  <Root background=Theme.Color.brokenWhite>
    <Layout>
      <Panel>
        <Spacer bottom=3>
          <Row justify=`start align=`center>
            <Spacer bottom=1> <Logo /> </Spacer>
            <Menu
              currentNavigate
              navigate={to_ => setNavigate(to_) |> ignore}
            />
          </Row>
        </Spacer>
        <SubHeader />
      </Panel>
      <Align> <h2> {React.string(currentNavigate)} </h2> </Align>
    </Layout>
  </Root>;
};
