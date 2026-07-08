(* Conformance runner: renders every case from the shared registry with
   ReactServerDOM.render_model ~env:`Prod and byte-compares the normalized
   rows against the committed fixtures produced by the real
   react-server-dom-webpack (see ../generate.mjs).


   This runner only READS committed fixtures: it works offline, without bun
   or node_modules. *)

let fixtures_dir = "../fixtures"

(* Normalization: keep in sync with ../generate.mjs and protocol.md. *)
let normalize_row row =
  let row = Str.global_replace (Str.regexp "\"stack\":\\(\\[[^]]*\\]\\|\"[^\"]*\"\\)") "\"stack\":\"<stack>\"" row in
  Str.global_replace (Str.regexp "\"digest\":\"[^\"]*\"") "\"digest\":\"<digest>\"" row

let to_rows payload = List.map normalize_row (Spec_fixture.split_rows payload)
let read_fixture = Spec_fixture.read ~dir:fixtures_dir ~suffix:".flight" ~regen_command:"make spec-generate"

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
    Spec_fixture.check ~name:case.name ~xfail:case.xfail ~matches ~print_divergence:(fun () ->
        print_diff ~fixture ~rendered);
    Lwt.return ()
  in
  (Printf.sprintf "flight_spec / %s" case.name, [ Alcotest_lwt.test_case "" `Quick run ])

let () =
  let xfails = List.filter (fun (case : Cases.case) -> Option.is_some case.xfail) Cases.all in
  Printf.printf "flight_spec: %d cases, %d known divergences (xfail)\n" (List.length Cases.all) (List.length xfails);
  Lwt_main.run (Alcotest_lwt.run "flight_spec_conformance" (List.map make_test Cases.all))
