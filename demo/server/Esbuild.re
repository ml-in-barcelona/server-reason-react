let build = (~entry_point, ~outfile, ()) => {
  let build_folder = "_build/default/demo/client/app";
  let output = Filename.concat(build_folder, outfile);
  let entry = Filename.concat(build_folder, entry_point);
  let command =
    String.concat(
      " ",
      [
        "NODE_PATH=./demo/node_modules/",
        "esbuild",
        entry,
        "--bundle",
        "--outfile=" ++ output,
        "--platform=browser",
        "--log-level=error",
      ],
    );
  let thread =
    switch%lwt (Lwt_unix.system(command)) {
    | Lwt_unix.WEXITED(status) when status == 0 =>
      Lwt.return_ok(
        Printf.sprintf("esbuild successfully build into %s", output),
      )
    | Lwt_unix.WEXITED(status) =>
      Lwt.return_ok(
        Printf.sprintf("Command exited with status %d\n", status),
      )
    | Lwt_unix.WSIGNALED(signal) =>
      Lwt.return_error(
        Printf.sprintf("Command was killed by signal %d\n", signal),
      )
    | Lwt_unix.WSTOPPED(signal) =>
      Lwt.return_error(
        Printf.sprintf("Command was stopped by signal %d\n", signal),
      )
    };

  switch (Lwt_main.run(thread)) {
  | Ok(ok) => print_endline(ok)
  | Error(result) => print_endline(result)
  };
};
