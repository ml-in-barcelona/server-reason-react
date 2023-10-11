module Hr = {
  [@react.component]
  let make = () => {
    <span
      className={Cx.make([
        "block",
        "w-full",
        "h-px",
        Theme.background("grey"),
      ])}
    />;
  };
};

module Layout = {
  [@react.component]
  let make = (~children) => {
    <div
      className={Cx.make(
        [],
        /* Css.maxWidth(`px(800)),
           Css.margin2(~v=`zero, ~h=`auto),
           Css.padding4(
             ~top=`rem(4.0),
             ~bottom=`zero,
             ~left=`rem(2.0),
             ~right=`rem(2.0),
           ),
           Theme.Media.onMobile([Css.overflow(`hidden)]), */
      )}>
      children
    </div>;
  };
};

module Header = {
  type item = {
    label: string,
    link: string,
  };

  module Menu = {
    [@react.component]
    let make = () => {
      let data = [|
        {
          label: "Documentation",
          link: "https://github.com/ml-in-barcelona/server-reason-react",
        },
        {
          label: "Issues",
          link: "https://github.com/ml-in-barcelona/server-reason-react/issues",
        },
        {label: "About", link: "https://twitter.com/davesnx"},
      |];

      <div
        className={Cx.make([
          "flex",
          "items-center",
          "justify-items-end",
          "gap-4",
        ])}>
        {React.array(
           Belt.Array.mapWithIndex(data, (key, item) =>
             <div className={Cx.make(["block"])} key={Int.to_string(key)}>
               <a
                 href={item.link}
                 target="_blank"
                 className={Cx.make([
                   "text-base",
                   Theme.text("[#9b9b9b]"),
                   Theme.hover([Theme.text(Theme.Color.white)]),
                 ])}>
                 {React.string(item.label)}
               </a>
             </div>
           ),
         )}
      </div>;
    };
  };

  [@react.component]
  let make = () => {
    <div className={Cx.make(["text-yellow-700", "text-xl"])}>
      <h1 className={Cx.make(["m-0"])}>
        {React.string("Server Reason React")}
      </h1>
      <Spacer top=2> <Menu /> </Spacer>
    </div>;
  };
};

[@react.component]
let make = () => {
  <Root background=Theme.Color.darkGrey>
    <Layout>
      <Stack gap=8 justify=`start>
        <> <Header /> <Hr /> <Counter /> </>
      </Stack>
    </Layout>
  </Root>;
};
