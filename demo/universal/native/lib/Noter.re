module Hr = {
  [@react.component]
  let make = () => {
    <span
      className={Cx.make([
        "block",
        "w-full",
        "h-px",
        Theme.background("gray-800"),
      ])}
    />;
  };
};

[@react.component]
let make = () => {
  React.useEffect(() => {
    let _ = Js.log("Hello from the client");
    None;
  });

  <Layout background=Theme.Color.black>
    <Stack gap=8 justify=`start>
      <p
        className={Cx.make([
          "text-3xl",
          "font-bold",
          Theme.text(Theme.Color.white),
        ])}>
        {React.string("This is a small form")}
      </p>
      <Note_editor title="Hello" body="World" />
      <Hr />
      <Counter initial=23 />
    </Stack>
  </Layout>;
};
