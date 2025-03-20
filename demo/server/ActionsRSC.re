let stream_server_action = (request, fn) => {
  Dream.stream(
    ~headers=[
      ("Content-Type", "application/react.action"),
      ("X-Location", Dream.target(request)),
    ],
    stream => {
      let%lwt () = fn(stream);
      Lwt.return();
    },
  );
};

let createFromRequest = (request, values) => {
  stream_server_action(
    request,
    stream => {
      let%lwt _stream =
        ReactServerDOM.act(
          values,
          ~subscribe=chunk => {
            Dream.log("Action response");
            Dream.log("%s", chunk);
            let%lwt () = Dream.write(stream, chunk);
            Dream.flush(stream);
          },
        );

      Dream.flush(stream);
    },
  );
};
