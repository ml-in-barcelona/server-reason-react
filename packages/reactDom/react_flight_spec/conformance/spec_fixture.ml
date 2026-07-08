(* Machinery shared by the two conformance runners (flight_spec_conformance
   and reply_spec_conformance): committed-fixture reading, row splitting, and
   the xfail state machine. *)

let read ~dir ~suffix ~regen_command name =
  let path = Filename.concat dir (name ^ suffix) in
  if not (Sys.file_exists path) then
    Alcotest.failf "fixture %s is missing; run `%s` and commit the result" path regen_command;
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () -> really_input_string ic (in_channel_length ic))

let split_rows payload =
  let rows = String.split_on_char '\n' payload in
  match List.rev rows with "" :: rest -> List.rev rest | _ -> rows

(* Cases annotated with [xfail] are asserted to MISMATCH: they are known
   divergences and must flip loudly (test failure) once fixed. *)
let check ~name ~xfail ~matches ~print_divergence =
  match (xfail, matches) with
  | None, true -> ()
  | None, false ->
      print_divergence ();
      Alcotest.failf "case %s diverges from the React fixture" name
  | Some reason, false ->
      Printf.printf "  [xfail] %s: known divergence (%s)\n" name reason;
      print_divergence ()
  | Some reason, true ->
      Alcotest.failf "case %s now MATCHES the React fixture: divergence fixed! Remove ~xfail (%s)" name reason
