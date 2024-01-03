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
    <div spellCheck=false className={Cx.make(["max-w-2xl", "pt-16"])}>
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
                   "text-primary hover:text-slate-300 focus:text-slate-300 underline transition duration-100 ease-in-out hover:decoration-inherit",
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
      <Spacer bottom=4>
        <h1 className={Cx.make(["m-0", "text-5xl", "font-bold"])}>
          {React.string("Server Reason React")}
        </h1>
      </Spacer>
      <Menu />
    </div>;
  };
};

[@react.component]
let make = () => {
  React.useEffect(() => {
    let _ = Js.log("Hello from the client");
    None;
  });

  <Root background=Theme.Color.darkGrey>
    <Layout>
      <Stack gap=8 justify=`start>
        <> <Header /> <Hr /> <Counter /> </>
      </Stack>
    </Layout>
  </Root>;
};
