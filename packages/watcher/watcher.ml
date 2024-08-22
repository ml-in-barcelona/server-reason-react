open Lwt.Infix

(* Function to get the last modification time of a file *)
let get_modification_time filename = (Unix.stat filename).Unix.st_mtime

(* Function to watch a file and execute a command when it changes *)
let watch_file filename cmd interval mutable_pid_ref =
  let mutable_last_time = ref (get_modification_time filename) in

  let loop () =
    Lwt_unix.sleep interval >>= fun () ->
    let current_time = get_modification_time filename in

    if current_time <> !mutable_last_time then (
      (* Kill the previous command if it's still running *)
      (match !mutable_pid_ref with
      | Some process ->
          Lwt.cancel process;
          Printf.printf "Killing previous command\n%!";
          Lwt.return ()
      | None -> Lwt.return ())
      >>= fun () ->
      Printf.printf "File %s modified. Running command: %s\n%!" filename cmd;

      let process = Lwt_process.exec (Lwt_process.shell cmd) in
      mutable_pid_ref := Some process;
      mutable_last_time := current_time;
      Lwt.return ())
    else Lwt.return ()
  in

  Lwt_main.run
    (let rec watch_loop () = loop () >>= fun () -> watch_loop () in
     watch_loop ())

let () =
  (* Check for required arguments *)
  if Array.length Sys.argv < 4 then (
    Printf.eprintf "Usage: %s -w <file_to_watch> <command_to_run>\n"
      Sys.argv.(0);
    exit 1);

  (* Parse arguments *)
  let file_to_watch = ref "" in
  let command_to_run = ref "" in
  let interval = ref 2.0 in

  (* Default interval to 2 seconds *)
  let rec parse_args i =
    if i < Array.length Sys.argv then
      match Sys.argv.(i) with
      | "-w" ->
          file_to_watch := Sys.argv.(i + 1);
          parse_args (i + 2)
      | "-i" ->
          interval := float_of_string Sys.argv.(i + 1);
          parse_args (i + 2)
      | cmd when !command_to_run = "" ->
          command_to_run := cmd;
          parse_args (i + 1)
      | _ -> parse_args (i + 1)
  in

  parse_args 1;

  if !file_to_watch = "" || !command_to_run = "" then (
    Printf.eprintf "Usage: %s -w <file_to_watch> <command_to_run>\n"
      Sys.argv.(0);
    exit 1);

  (* Start watching the file *)
  let mutable_pid_ref = ref None in
  watch_file !file_to_watch !command_to_run !interval mutable_pid_ref
