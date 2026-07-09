/* A page whose root is a <div> — no <html> wrapper. Demonstrates:
   - Head hoisting for non-document renders: the <title>, <meta> and <link>
     below render at the very top of the streamed shell, before the root
     element, matching react-dom's preamble (previously they were dropped).
   - Js.String operating on UTF-16 code units like JavaScript.
   - Js.Date parsing ISO datetimes without a timezone designator as local
     time and round-tripping its own toUTCString output. */

module Value = {
  [@react.component]
  let make = (~label, ~value) => {
    <div className="flex flex-row gap-2 items-baseline">
      <span className="text-sm text-gray-400 font-mono">
        {React.string(label)}
      </span>
      <span className="text-lg text-gray-100 font-mono font-bold">
        {React.string(value)}
      </span>
    </div>;
  };
};

module Section = {
  [@react.component]
  let make = (~title, ~children) => {
    <div className="flex flex-col gap-2">
      <h2 className="text-2xl font-bold text-gray-200">
        {React.string(title)}
      </h2>
      children
    </div>;
  };
};

module Page = {
  [@react.component]
  let make = () => {
    let unicode = "héllo 🚀";
    let iso_without_timezone = "2026-07-09T10:00:00";
    let parsed = Js.Date.fromString(iso_without_timezone);
    let roundtrip = Js.Date.fromString(Js.Date.toUTCString(parsed));

    <div
      className="m-0 p-8 min-w-[100vw] min-h-[100vh] flex flex-col gap-8 items-center justify-start bg-gray-900">
      <title> {React.string("FragmentRSC — hoisted title")} </title>
      <meta charSet="utf-8" />
      <meta name="description" content="Hoisted meta from a fragment root" />
      <link rel="stylesheet" href="/output.css" />
      <div className="flex flex-col gap-8 w-[720px]">
        <h1 className="text-4xl font-bold text-gray-100">
          {React.string("Fragment-root RSC")}
        </h1>
        <p className="text-gray-400">
          {React.string(
             "This page has no <html> wrapper: view-source and note the <title>, <meta> and <link> hoisted to the very top of the response, before this <div>.",
           )}
        </p>
        <Section title={js|Js.String is UTF-16, like JavaScript|js}>
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
        </Section>
        <Section title="Js.Date parses like JavaScript">
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
        </Section>
      </div>
    </div>;
  };
};

let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let handler = request =>
  DreamRSC.createFromRequest(~debug, <Page />, request);
