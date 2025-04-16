module Root = {
  [@react.component]
  let make = (~children) => {
    <DemoLayout background=Theme.Color.Gray2> children </DemoLayout>;
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
          Theme.text(Theme.Color.Gray11),
        ])}>
        {React.string(title)}
      </h2>
      {switch (description) {
       | Some(description) =>
         <Text color=Theme.Color.Gray10> description </Text>
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
              Theme.text(Theme.Color.Gray11),
            ])}>
            {React.string(
               "Server side rendering server components and client components",
             )}
          </h1>
          <Text color=Theme.Color.Gray10>
            "RSC and CC and their client props encodings"
          </Text>
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
          title="Debug client props"
          description="Passing client props into a client component">
          <Debug_props
            string="Title"
            int=99
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
        <Hr />
        <h1
          className={Cx.make([
            "text-5xl",
            "font-bold",
            Theme.text(Theme.Color.Gray11),
          ])}>
          {React.string("Server actions")}
        </h1>
        <Hr />
        <Section
          title="Client component importing actions"
          description="Client component importing actions">
          <ServerActionFormData />
        </Section>
        <Hr />
        <Section
          title="Server action from props on a Client Component"
          description="Server action via props on a Client Component, in this case the action is never created on the client">
          <ServerActionFromPropsClient
            actionOnClick=Actions.Samples.simpleResponse
          />
        </Section>
        <Hr />
        <Section
          title="Server action from props on a Server Component"
          description="Server action via props on a Server Component, in this case the action is never created on the client">
          <ServerActionFromProps />
        </Section>
        <Hr />
        <Section
          title="Server action with simple response"
          description="Server action with simple response">
          <ServerActionWithSimpleResponse />
        </Section>
      </Stack>,
    );
  };
};

let handler = request =>
  DreamRSC.createFromRequest(
    ~bootstrapModules=["/static/demo/CreateFromReadableStream.re.js"],
    ~bootstrapScripts=["https://cdn.tailwindcss.com"],
    <Root> <Page /> </Root>,
    request,
  );
