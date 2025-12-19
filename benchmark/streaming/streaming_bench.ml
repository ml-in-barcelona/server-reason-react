(** Streaming Benchmark for server-reason-react

    Measures:
    - Time to first byte (TTFB)
    - Time to full render
    - Chunk sizes
    - Memory during streaming *)

let measure_time_us f =
  let start = Unix.gettimeofday () in
  let result = f () in
  let stop = Unix.gettimeofday () in
  let time_us = (stop -. start) *. 1_000_000.0 in
  (result, time_us)

let format_time_us us =
  if us < 1000.0 then Printf.sprintf "%.2fµs" us
  else if us < 1_000_000.0 then Printf.sprintf "%.2fms" (us /. 1000.0)
  else Printf.sprintf "%.2fs" (us /. 1_000_000.0)

type scenario_result = {
  name : string;
  avg_static_time_us : float;
  avg_string_time_us : float;
  output_bytes : int;
  throughput_mb_s : float;
}

let measure_render_methods ~name ~iterations render_element =
  Printf.printf "Measuring %s...\n%!" name;

  let static_times = ref 0.0 in
  let string_times = ref 0.0 in
  let output_bytes = ref 0 in

  for _ = 1 to iterations do
    let element = render_element () in

    let html_static, static_time = measure_time_us (fun () -> ReactDOM.renderToStaticMarkup element) in
    static_times := !static_times +. static_time;

    let _html_string, string_time = measure_time_us (fun () -> ReactDOM.renderToString element) in
    string_times := !string_times +. string_time;

    output_bytes := String.length html_static
  done;

  let avg_static = !static_times /. float_of_int iterations in
  let avg_string = !string_times /. float_of_int iterations in
  let bytes = !output_bytes in
  let throughput = float_of_int bytes /. 1_000_000.0 /. (avg_static /. 1_000_000.0) in

  {
    name;
    avg_static_time_us = avg_static;
    avg_string_time_us = avg_string;
    output_bytes = bytes;
    throughput_mb_s = throughput;
  }

let print_result r =
  Printf.printf "\n%s\n" (String.make 60 '-');
  Printf.printf "Scenario: %s\n" r.name;
  Printf.printf "%s\n" (String.make 60 '-');
  Printf.printf "renderToStaticMarkup: %s\n" (format_time_us r.avg_static_time_us);
  Printf.printf "renderToString:       %s\n" (format_time_us r.avg_string_time_us);
  Printf.printf "Output size:          %d bytes (%.2f KB)\n" r.output_bytes (float_of_int r.output_bytes /. 1024.0);
  Printf.printf "Throughput:           %.2f MB/s\n" r.throughput_mb_s;
  Printf.printf "String overhead:      %.1f%%\n"
    ((r.avg_string_time_us -. r.avg_static_time_us) /. r.avg_static_time_us *. 100.0)

let print_comparison_table results =
  Printf.printf "\n%s\n" (String.make 90 '=');
  Printf.printf "COMPARISON TABLE\n";
  Printf.printf "%s\n" (String.make 90 '=');
  Printf.printf "%-20s %12s %12s %10s %12s\n" "Scenario" "Static" "String" "Size" "Throughput";
  Printf.printf "%s\n" (String.make 90 '-');

  List.iter
    (fun r ->
      Printf.printf "%-20s %12s %12s %9dB %10.1fMB/s\n" r.name (format_time_us r.avg_static_time_us)
        (format_time_us r.avg_string_time_us) r.output_bytes r.throughput_mb_s)
    results;

  Printf.printf "%s\n" (String.make 90 '=')

let main () =
  let iterations = 100 in

  Printf.printf "Streaming/Render Benchmark for server-reason-react\n";
  Printf.printf "Iterations per scenario: %d\n\n" iterations;

  let scenarios =
    let open Benchmark_scenarios in
    [
      ("Trivial", fun () -> Benchmark_scenarios.Trivial.make ());
      ("ShallowTree", fun () -> ShallowTree.make ());
      ("DeepTree10", fun () -> DeepTree.Depth10.make ());
      ("DeepTree50", fun () -> DeepTree.Depth50.make ());
      ("WideTree10", fun () -> WideTree.Wide10.make ());
      ("WideTree100", fun () -> WideTree.Wide100.make ());
      ("WideTree500", fun () -> WideTree.Wide500.make ());
      ("Table10", fun () -> Table.Table10.make ());
      ("Table100", fun () -> Table.Table100.make ());
      ("Table500", fun () -> Table.Table500.make ());
      ("PropsSmall", fun () -> PropsHeavy.Small.make ());
      ("PropsMedium", fun () -> PropsHeavy.Medium.make ());
      ("Ecommerce24", fun () -> Ecommerce.Products24.make ());
      ("Ecommerce48", fun () -> Ecommerce.Products48.make ());
      ("Dashboard", fun () -> Dashboard.make ());
      ("Blog50", fun () -> Blog.Blog50.make ());
      ("Form", fun () -> Form.make ());
    ]
  in

  let results =
    List.map
      (fun (name, render_element) ->
        let result = measure_render_methods ~name ~iterations render_element in
        print_result result;
        result)
      scenarios
  in

  print_comparison_table results;

  Lwt.return ()

let () = Lwt_main.run (main ())
