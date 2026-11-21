open Benchmark_scenarios

type scenario = { name : string; run : unit -> string }

let text_list_500 = React.list (List.init 500 (fun _ -> React.string "x"))
let text_array_500 = React.array (Array.init 500 (fun _ -> React.string "x"))

let drain_render_to_stream element =
  Lwt_main.run
    (let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Prod element in
     let%lwt chunks = Lwt_stream.to_list stream in
     Lwt.return (String.concat "" chunks))

let drain_render_html element =
  Lwt_main.run
    (let streamed = Buffer.create 128 in
     let%lwt shell, subscribe = ReactServerDOM.render_html ~env:`Prod element in
     let%lwt () =
       subscribe (fun chunk ->
           Buffer.add_string streamed chunk;
           Lwt.return ())
     in
     Lwt.return (shell ^ Buffer.contents streamed))

let scenarios : scenario list =
  [
    {
      name = "deep10";
      run = (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth10.make (DeepTree.Depth10.makeProps ())));
    };
    {
      name = "deep50";
      run = (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth50.make (DeepTree.Depth50.makeProps ())));
    };
    {
      name = "wide10";
      run = (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide10.make (WideTree.Wide10.makeProps ())));
    };
    {
      name = "wide100";
      run = (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide100.make (WideTree.Wide100.makeProps ())));
    };
    {
      name = "wide500";
      run = (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide500.make (WideTree.Wide500.makeProps ())));
    };
    {
      name = "table10";
      run = (fun () -> ReactDOM.renderToStaticMarkup (Table.Table10.make (Table.Table10.makeProps ())));
    };
    {
      name = "table100";
      run = (fun () -> ReactDOM.renderToStaticMarkup (Table.Table100.make (Table.Table100.makeProps ())));
    };
    {
      name = "table500";
      run = (fun () -> ReactDOM.renderToStaticMarkup (Table.Table500.make (Table.Table500.makeProps ())));
    };
    {
      name = "propssmall";
      run = (fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Small.make (PropsHeavy.Small.makeProps ())));
    };
    {
      name = "propsmedium";
      run = (fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Medium.make (PropsHeavy.Medium.makeProps ())));
    };
    { name = "form"; run = (fun () -> ReactDOM.renderToStaticMarkup (Form.make (Form.makeProps ()))) };
    { name = "dashboard"; run = (fun () -> ReactDOM.renderToStaticMarkup (Dashboard.make (Dashboard.makeProps ()))) };
    { name = "blog50"; run = (fun () -> ReactDOM.renderToStaticMarkup (Blog.Blog50.make (Blog.Blog50.makeProps ()))) };
    {
      name = "ecommerce24";
      run = (fun () -> ReactDOM.renderToStaticMarkup (Ecommerce.Products24.make (Ecommerce.Products24.makeProps ())));
    };
    {
      name = "ecommerce48";
      run = (fun () -> ReactDOM.renderToStaticMarkup (Ecommerce.Products48.make (Ecommerce.Products48.makeProps ())));
    };
    { name = "list500"; run = (fun () -> ReactDOM.renderToStaticMarkup text_list_500) };
    { name = "array500"; run = (fun () -> ReactDOM.renderToStaticMarkup text_array_500) };
    { name = "stream-list500"; run = (fun () -> drain_render_to_stream text_list_500) };
    { name = "stream-array500"; run = (fun () -> drain_render_to_stream text_array_500) };
    { name = "rsc-list500"; run = (fun () -> drain_render_html text_list_500) };
    { name = "rsc-array500"; run = (fun () -> drain_render_html text_array_500) };
  ]

let sink : string ref = ref ""

let run_loop ~warmup ~iters ~scenario =
  Gc.full_major ();
  Gc.compact ();
  for _ = 1 to warmup do
    sink := scenario.run ()
  done;
  let t0 = Unix.gettimeofday () in
  for _ = 1 to iters do
    sink := scenario.run ()
  done;
  let t1 = Unix.gettimeofday () in
  t1 -. t0

let print_summary ~scenario ~iters ~elapsed ~output_len =
  Printf.printf "### %s\n" scenario.name;
  Printf.printf "  iterations: %d  elapsed: %.3fs  per-iter: %.2fµs\n" iters elapsed
    (elapsed *. 1e6 /. float_of_int iters);
  Printf.printf "  output length: %d bytes\n" output_len

let default_warmup = 50
let default_iters = 500

let usage () =
  print_endline "Usage: perf_profile.exe [--scenario NAME] [--warmup N] [--iters N] [--list]";
  print_endline "";
  print_endline "Scenarios:";
  List.iter (fun s -> Printf.printf "  - %s\n" s.name) scenarios;
  print_endline "";
  print_endline "This binary is the deterministic render loop consumed by external CPU";
  print_endline "profilers (callgrind, perf). Run perf_profile.sh for full driver usage."

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let selected = ref None in
  let warmup = ref default_warmup in
  let iters = ref default_iters in
  let rec parse = function
    | [] -> ()
    | "--scenario" :: v :: rest ->
        selected := Some v;
        parse rest
    | "--warmup" :: v :: rest ->
        warmup := int_of_string v;
        parse rest
    | "--iters" :: v :: rest ->
        iters := int_of_string v;
        parse rest
    | "--list" :: _ ->
        List.iter (fun s -> print_endline s.name) scenarios;
        exit 0
    | ("--help" | "-h") :: _ ->
        usage ();
        exit 0
    | other :: _ ->
        Printf.eprintf "Unknown argument: %s\n" other;
        usage ();
        exit 2
  in
  parse args;
  let to_run =
    match !selected with
    | None -> scenarios
    | Some name -> (
        match List.find_opt (fun s -> s.name = name) scenarios with
        | Some s -> [ s ]
        | None ->
            Printf.eprintf "Unknown scenario: %s\n" name;
            usage ();
            exit 2)
  in
  Printf.printf "=== perf_profile ===\n";
  Printf.printf "warmup=%d  iters=%d  scenarios=%d\n" !warmup !iters (List.length to_run);
  List.iter
    (fun scenario ->
      let elapsed = run_loop ~warmup:!warmup ~iters:!iters ~scenario in
      print_summary ~scenario ~iters:!iters ~elapsed ~output_len:(String.length !sink))
    to_run
