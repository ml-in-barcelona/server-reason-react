(* Conformance runner: renders every case from the shared registry with
   ReactServerDOM.render_model ~env:`Prod and byte-compares the normalized
   rows against the committed fixtures produced by the real
   react-server-dom-webpack (see ../generate.mjs).

   Cases annotated with [xfail] in Cases.re are asserted to MISMATCH: they
   are known divergences and must flip loudly (test failure) once fixed.

   This runner only READS committed fixtures: it works offline, without bun
   or node_modules. *)

let fixtures_dir = "../fixtures"

(* Normalization: keep in sync with ../generate.mjs and protocol.md. *)
let normalize_row row =
  let row = Str.global_replace (Str.regexp "\"stack\":\\(\\[[^]]*\\]\\|\"[^\"]*\"\\)") "\"stack\":\"<stack>\"" row in
  Str.global_replace (Str.regexp "\"digest\":\"[^\"]*\"") "\"digest\":\"<digest>\"" row

let to_rows payload =
  let rows = String.split_on_char '\n' payload in
  let rows = match List.rev rows with "" :: rest -> List.rev rest | _ -> rows in
  List.map normalize_row rows

let read_fixture name =
  let path = Filename.concat fixtures_dir (name ^ ".flight") in
  if not (Sys.file_exists path) then
    Alcotest.failf "fixture %s is missing; run `make spec-generate` and commit the result" path;
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () -> really_input_string ic (in_channel_length ic))

let render_case (case : Cases.case) =
  let buffer = Buffer.create 1024 in
  let subscribe chunk =
    Buffer.add_string buffer chunk;
    Lwt.return ()
  in
  let%lwt () = ReactServerDOM.render_model ~env:`Prod ~subscribe (case.render ()) in
  Lwt.return (to_rows (Buffer.contents buffer))

let print_diff ~fixture ~rendered =
  let max_len = max (List.length fixture) (List.length rendered) in
  for i = 0 to max_len - 1 do
    let fixture_row = List.nth_opt fixture i in
    let rendered_row = List.nth_opt rendered i in
    if fixture_row <> rendered_row then (
      Printf.printf "    row %d:\n" i;
      Printf.printf "      react: %s\n" (Option.value fixture_row ~default:"<missing>");
      Printf.printf "      srr:   %s\n" (Option.value rendered_row ~default:"<missing>"))
  done

let make_test (case : Cases.case) =
  let run _switch () =
    let fixture = to_rows (read_fixture case.name) in
    let%lwt rendered = render_case case in
    let matches = fixture = rendered in
    (match (case.xfail, matches) with
    | None, true -> ()
    | None, false ->
        print_diff ~fixture ~rendered;
        Alcotest.failf "case %s diverges from the React fixture" case.name
    | Some reason, false ->
        Printf.printf "  [xfail] %s: known divergence (%s)\n" case.name reason;
        print_diff ~fixture ~rendered
    | Some reason, true ->
        Alcotest.failf "case %s now MATCHES the React fixture: divergence fixed! Remove ~xfail (%s)" case.name reason);
    Lwt.return ()
  in
  (Printf.sprintf "flight_spec / %s" case.name, [ Alcotest_lwt.test_case "" `Quick run ])

let () =
  let xfails = List.filter (fun (case : Cases.case) -> Option.is_some case.xfail) Cases.all in
  Printf.printf "flight_spec: %d cases, %d known divergences (xfail)\n" (List.length Cases.all) (List.length xfails);
  Lwt_main.run (Alcotest_lwt.run "flight_spec_conformance" (List.map make_test Cases.all))
