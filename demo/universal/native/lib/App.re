module Hr = {
  [@react.component]
  let make = () => {
    <span
      className={Cx.make([
        "block",
        "w-full",
        "h-px",
        Theme.background(Theme.Color.Gray4),
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
               <Link.Text href={item.link} target="_blank">
                 {item.label}
               </Link.Text>
             </div>
           ),
         )}
      </div>;
    };
  };

  [@react.component]
  let make = () => {
    <section>
      <Spacer bottom=4>
        <h1
          className={Cx.make([
            "m-0",
            "text-5xl",
            "font-bold",
            Theme.text(Theme.Color.Gray13),
          ])}>
          {React.string("Server Reason React")}
        </h1>
      </Spacer>
      <Menu />
    </section>;
  };
};

[@warning "-26-27-32"];

[@react.component]
let make = () => {
  React.useEffect(() => {
    Js.log("Client mounted");
    None;
  });

  let (title, setTitle) = RR.useStateValue("Server Reason React");

  let%browser_only onChangeTitle = e => {
    let value = React.Event.Form.target(e)##value;
    setTitle(value);
  };

  <DemoLayout background=Theme.Color.Gray2>
    <Stack gap=8 justify=`start> <Title /> </Stack>
    <InputText value=title onChange=onChangeTitle />
  </DemoLayout>;
};
