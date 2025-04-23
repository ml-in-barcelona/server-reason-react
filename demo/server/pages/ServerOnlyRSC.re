let handler = request => {
  let isRSCheader =
    Dream.header(request, "Accept") == Some("application/react.component");

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

  if (isRSCheader) {
    Dream.stream(response_stream => {
      let%lwt _stream =
        ReactServerDOM.render_model(
          ~debug=true,
          ~subscribe=data => Dream.write(response_stream, data),
          app,
        );
      Lwt.return();
    });
  } else {
    Dream.html(
      ReactDOM.renderToString(
        <Document script="/static/demo/CreateFromFetch.re.js">
          React.null
        </Document>,
      ),
    );
  };
};
