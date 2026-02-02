let () =
  let subscribe chunk = Lwt_io.print chunk in
  Lwt_main.run (ReactServerDOM.render_model ~subscribe Entry_native.app)
