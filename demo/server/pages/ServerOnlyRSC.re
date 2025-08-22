let handler = request => {
  let app =
    <DemoLayout background=Theme.Color.Gray2>
      <div className="flex flex-col items-center justify-center h-full gap-4">
        <span className="text-gray-400 text-center">
          {React.string(
             "The client will fetch the server component from the server and run createFromFetch",
           )}
          <br />
          {React.string("asking for the current time (in seconds) since")}
          <br />
          {React.string("00:00:00 GMT, Jan. 1, 1970")}
        </span>
        <h1
          className={Cx.make([
            "font-bold text-4xl",
            Theme.text(Theme.Color.Gray11),
          ])}>
          {React.string(string_of_float(Unix.gettimeofday()))}
        </h1>
      </div>
    </DemoLayout>;

  DreamRSC.createFromRequest(
    ~bootstrapModules=["/static/demo/ServerOnlyRSC.re.js"],
    <Document> app </Document>,
    request,
  );
};
