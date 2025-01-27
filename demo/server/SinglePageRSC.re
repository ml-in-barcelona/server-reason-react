module Root = {
  [@react.component]
  let make = (~children) => {
    <DemoLayout background=Theme.Color.black> children </DemoLayout>;
  };
};

module Section = {
  [@react.component]
  let make = (~title, ~children, ~description=?) => {
    <Stack gap=2 justify=`start>
      <h2
        className={Cx.make([
          "text-3xl",
          "font-bold",
          Theme.text(Theme.Color.white),
        ])}>
        {React.string(title)}
      </h2>
      {switch (description) {
       | Some(description) =>
         <p className={Theme.text(Theme.Color.brokenWhite)}>
           {React.string(description)}
         </p>
       | None => React.null
       }}
      <Spacer bottom=4 />
      children
    </Stack>;
  };
};

module Page = {
  [@react.async.component]
  let make = () => {
    let promiseIn2 =
      Lwt.bind(Lwt_unix.sleep(2.0), _ =>
        Lwt.return("Solusionao in 2 seconds!")
      );

    let promiseIn4 =
      Lwt.bind(Lwt_unix.sleep(4.0), _ =>
        Lwt.return("Solusionao in 4 seconds!")
      );

    Lwt.return(
      <Stack gap=8 justify=`start>
        <Stack gap=2 justify=`start>
          <h1
            className={Cx.make([
              "text-5xl",
              "font-bold",
              Theme.text(Theme.Color.white),
            ])}>
            {React.string("RSC + SSR demo page")}
          </h1>
          <p className={Theme.text(Theme.Color.brokenWhite)}>
            {React.string(
               "Page to debug server-side RSC and client-side client components and their client props encodings",
             )}
          </p>
        </Stack>
        <Hr />
        <Section
          title="Counter" description="Passing int into a client component">
          <Counter initial=45 />
        </Section>
        <Hr />
        <Section
          title="Debug client props"
          description="Passing client props into a client component">
          <Debug_props
            string="Title"
            int=1
            float=1.1
            bool_true=true
            bool_false=false
            header={Some(<div> {React.string("H E A D E R")} </div>)}
            string_list=["Item 1", "Item 2"]
            promise=promiseIn2>
            <div>
              {React.string(
                 "This footer is a React.element as a server component into client prop, yay!",
               )}
            </div>
          </Debug_props>
        </Section>
        <Hr />
        <Section
          title="Pass another promise prop"
          description="Sending a promise from the server to the client">
          <Promise_renderer promise=promiseIn4 />
        </Section>
      </Stack>,
    );
  };
};

let handler = request =>
  DreamRSC.createFromRequest(
    <Root> <Page /> </Root>,
    "/static/demo/client/create-from-readable-stream.js",
    request,
  );