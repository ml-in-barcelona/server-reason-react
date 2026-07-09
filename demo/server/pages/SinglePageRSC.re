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
      <div className="mb-4" />
      children
    </Stack>;
  };
};

module Value = {
  [@react.component]
  let make = (~label, ~value) => {
    <div className="flex flex-row gap-2 items-baseline">
      <span
        className={Cx.make([
          "text-sm",
          "font-mono",
          Theme.text(Theme.Color.Gray10),
        ])}>
        {React.string(label)}
      </span>
      <span
        className={Cx.make([
          "text-lg",
          "font-mono",
          "font-bold",
          Theme.text(Theme.Color.Gray11),
        ])}>
        {React.string(value)}
      </span>
    </div>;
  };
};

module ExpandedContent = {
  [@react.component]
  let make = (~id, ~content: string, ~updatedAt: float, ~title: string) => {
    let lastUpdatedAt =
      if (Date.is_today(updatedAt)) {
        Date.format_time(updatedAt);
      } else {
        Date.format_date(updatedAt);
      };

    let summary =
      content |> Markdown.extract_text |> Markdown.summarize(~words=20);

    <Expander
      id
      title
      expandedChildren={
        <div className="mt-2">
          {switch (String.trim(summary)) {
           | "" => <i> {React.string("(No content)")} </i>
           | s => <Text size=Small color=Theme.Color.Gray11> s </Text>
           }}
          <Counter.Double initial=22 />
        </div>
      }>
      <header
        className={Cx.make(["max-w-[85%] flex flex-col gap-2"])}
        style={ReactDOM.Style.make(~zIndex="1", ())}>
        <Text size=Large weight=Bold> title </Text>
        <Text size=Small> lastUpdatedAt </Text>
      </header>
    </Expander>;
  };
};

module CacheDemo = {
  let calls = ref(0);
  let get =
    React.cache(label => {
      calls.contents = calls.contents + 1;
      label ++ " #" ++ Int.to_string(calls.contents);
    });
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
    let cachedValueFirst = CacheDemo.get("Cached value");
    let cachedValueSecond = CacheDemo.get("Cached value");
    let unicode = "héllo 🚀";
    let iso_without_timezone = "2026-07-09T10:00:00";
    let parsed = Js.Date.fromString(iso_without_timezone);
    let roundtrip = Js.Date.fromString(Js.Date.toUTCString(parsed));
    Lwt.return(
      <Stack gap=8 justify=`start>
        <Stack gap=2 justify=`start>
          <h1
            className={Cx.make([
              "text-3xl",
              "font-bold",
              Theme.text(Theme.Color.Gray11),
            ])}>
            {React.string(
               "Server side rendering server components and client components",
             )}
          </h1>
          <p
            className={Cx.make(["text-sm", Theme.text(Theme.Color.Gray10)])}>
            {React.string(
               "React server components. Lazy loading of client components. Client props encodings, such as promises, React elements, and primitive types.",
             )}
          </p>
        </Stack>
        <Hr />
        <Section
          title="React.cache"
          description="Memoizes results for identical arguments per request">
          <Stack gap=1 justify=`start>
            <Text> {"First call: " ++ cachedValueFirst} </Text>
            <Text> {"Second call: " ++ cachedValueSecond} </Text>
          </Stack>
        </Section>
        <Hr />
        <Section
          title={js|Js.String is UTF-16, like JavaScript|js}
          description="Js.String operates on UTF-16 code units on the server, rendering JavaScript-identical values">
          <Stack gap=1 justify=`start>
            <Value
              label={"length \"" ++ unicode ++ "\""}
              value={string_of_int(Js.String.length(unicode))}
            />
            <Value
              label={js|charCodeAt ~index:1 "héllo"|js}
              value={Js.Float.toString(
                Js.String.charCodeAt(~index=1, unicode),
              )}
            />
            <Value
              label={js|toUpperCase "straße"|js}
              value={Js.String.toUpperCase({js|straße|js})}
            />
            <Value
              label={js|replaceByRe /l/g -> "L" on "héllo wörld"|js}
              value={Js.String.replaceByRe(
                ~regexp=[%re "/l/g"],
                ~replacement="L",
                {js|héllo wörld|js},
              )}
            />
          </Stack>
        </Section>
        <Hr />
        <Section
          title="Js.Date parses like JavaScript"
          description="Js.Date parses ISO datetimes without a timezone designator as local time and round-trips its own toUTCString output">
          <Stack gap=1 justify=`start>
            <Value
              label={
                "fromString \""
                ++ iso_without_timezone
                ++ "\" (no timezone -> local)"
              }
              value={Js.Date.toString(parsed)}
            />
            <Value
              label="getHours (10 in the server's local time)"
              value={Js.Float.toString(Js.Date.getHours(parsed))}
            />
            <Value
              label="fromString (toUTCString d) round-trips"
              value={Js.Date.toString(roundtrip)}
            />
          </Stack>
        </Section>
        <Hr />
        <Section
          title="Counter"
          description="Passing int into a client component, the counter starts at 45 and counts by one">
          <Counter initial=45 />
        </Section>
        <Hr />
        <Section
          title="Client component that errors on the server"
          description="The Suspense boundary is flushed in errored form (<!--$!--> / $RX) instead of a silent blank, and the browser retries rendering it client-side">
          <ThrowingClient />
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
        <Section
          title="Pass a client component prop"
          description="Sending a client component from the server to the client (that contains another client component)">
          <ExpandedContent
            id=1
            title="Titulaso"
            updatedAt=1653561600.0
            content="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
          />
        </Section>
        <Hr />
        <h1
          className={Cx.make([
            "text-5xl",
            "font-bold",
            Theme.text(Theme.Color.Gray11),
          ])}>
          {React.string("Server functions")}
        </h1>
        <Hr />
        <Section
          title="Server function from props on a Client Component"
          description="In this case, react will use the server function from the window.__server_functions_manifest_map">
          <ServerActionFromPropsClient
            actionOnClick=ServerFunctions.simpleResponse
            optionalAction=ServerFunctions.optionalAction
          />
        </Section>
        <Hr />
        <Section
          title="Server function with simple response"
          description="Server function imported and called directly on a client component">
          <ServerActionWithSimpleResponse />
        </Section>
        <Hr />
        <Section
          title="Server function with error"
          description="Server function with error">
          <ServerActionWithError />
        </Section>
        <Hr />
        <Section
          title="Server function with FormData"
          description="Server function with FormData">
          <ServerActionWithFormData />
        </Section>
        <Hr />
        <Section
          title="Server function with FormData on action attribute on Server Component"
          description="In this case, react will use the server function from the window.__server_functions_manifest_map">
          <ServerActionWithFormDataServer />
        </Section>
        <Hr />
        <Section
          title="Server function with FormData on formAction attribute on Server Component"
          description="In this case, react will use the server function from the window.__server_functions_manifest_map">
          <ServerActionWithFormDataFormAction />
        </Section>
        <Hr />
        <Section
          title="Server function with FormData with extra arg"
          description="It shows that it's possible to pass extra arguments to the server function on forms">
          <ServerActionWithFormDataWithArg />
        </Section>
        <Hr />
        <Section
          title="Server function with optional arg"
          description="Server function with optional arguments — exercises $undefined decoding when the optional arg is omitted">
          <ServerActionWithOptionalArg />
        </Section>
        <Hr />
        <Section
          title="Request context in server functions"
          description="Server functions can read cookies and headers from the ambient request context via ServerContext">
          <RequestContextDemo />
        </Section>
        <Hr />
      </Stack>,
    );
  };
};

module App = {
  [@react.component]
  let make = () => {
    <DemoLayout background=Theme.Color.Gray2> <Page /> </DemoLayout>;
  };
};

let handler = request =>
  DreamRSC.createFromRequest(
    ~debug=Sys.getenv_opt("DEMO_ENV") == Some("development"),
    ~bootstrapModules=["/static/demo/SinglePageRSC.re.js"],
    ~layout=
      children =>
        <html suppressHydrationWarning=true>
          <head>
            <meta charSet="utf-8" />
            <link rel="stylesheet" href="/output.css" />
          </head>
          <body suppressHydrationWarning=true>
            <div id="root"> children </div>
          </body>
        </html>,
    <App />,
    request,
  );
