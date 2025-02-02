let handler = request => {
  let isRSCheader =
    Dream.header(request, "Accept") == Some("text/x-component");

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
      let%lwt stream =
        ReactServerDOM.render_model(
          ~subscribe=data => Dream.write(response_stream, data),
          app,
        );
      let%lwt () =
        Lwt_stream.iter_s(
          data => Dream.write(response_stream, data),
          stream,
        );
      Lwt.return();
    });
  } else {
    Dream.html(
      ReactDOM.renderToString(
        <Document script="/static/demo/client/create-from-fetch.js">
          React.null
        </Document>,
      ),
    );
  };
};
