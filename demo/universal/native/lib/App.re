module Hr = {
  [@react.component]
  let make = () => {
    <span
      className={Cx.make([
        "block",
        "w-full",
        "h-px",
        Theme.background("slate-400"),
      ])}
    />;
  };
};

module Title = {
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
        {
          label: "About",
          link: "https://twitter.com/davesnx",
        },
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
                   "underline transition duration-100 ease-in-out hover:decoration-inherit",
                   Theme.text(Theme.Color.white),
                   Theme.hover([
                     "underline",
                     Theme.text(Theme.Color.brokenWhite),
                   ]),
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
    <div className={Cx.make([Theme.text(Theme.Color.white), "text-xl"])}>
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
    Js.log("Client mounted");
    None;
  });

  <Layout background=Theme.Color.black>
    <Stack gap=8 justify=`start>
      <Title />
      <Hr />
      <Counter initial=22 />
    </Stack>
  </Layout>;
};
