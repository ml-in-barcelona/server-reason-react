module Hr = {
  [@react.component]
  let make = () => {
    <hr
      className={Cx.make([
        "block",
        "w-full",
        "h-px",
        Theme.background("gray-800"),
      ])}
    />;
  };
};

module Promise_example = {
  [@react.component]
  let make = (~valueIn3seconds) => {
    <div
      className={Cx.make([
        Theme.text(Theme.Color.white),
        "flex",
        "flex-col",
        "gap-4",
      ])}>
      <Spacer bottom=2>
        <p className={Cx.make(["m-0", "text-3xl", "font-bold"])}>
          {React.string("Promise from the server")}
        </p>
      </Spacer>
      <React.Suspense
        fallback={React.string("Waiting for promise to resolve...")}>
        <Promise_renderer value=valueIn3seconds />
      </React.Suspense>
      <p className="text-lg">
        {React.string("The promise is created on the server (as a Lwt.t)")}
      </p>
    </div>;
  };
};

[@react.component]
let make = (~valueIn3seconds) => {
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
      <Counter initial=22 />
      <Hr />
      <Promise_example valueIn3seconds />
    </Stack>
  </Layout>;
};
