(* Benchmark runner with JSON output for github-action-benchmark (customBiggerIsBetter) *)

let json_mode = ref false
let iterations = 10000

type benchmark_result = { name : string; ops_per_sec : float }

let measure_benchmark ~name render_fn =
  for _ = 1 to 100 do
    let _ = render_fn () in
    ()
  done;
  Gc.full_major ();
  Gc.compact ();
  let start = Unix.gettimeofday () in
  for _ = 1 to iterations do
    let _ = render_fn () in
    ()
  done;
  let elapsed = Unix.gettimeofday () -. start in
  let ops_per_sec = float_of_int iterations /. elapsed in
  { name; ops_per_sec }

let print_result r = Printf.printf "%-35s %12.0f ops/sec\n" r.name r.ops_per_sec

let print_results_table results =
  Printf.printf "\n%s\n" (String.make 50 '=');
  Printf.printf "server-reason-react Benchmarks\n";
  Printf.printf "%s\n" (String.make 50 '=');
  Printf.printf "%-35s %12s\n" "Benchmark" "Throughput";
  Printf.printf "%s\n" (String.make 50 '-');
  List.iter print_result results;
  Printf.printf "%s\n" (String.make 50 '=')

let print_results_json results =
  let json_entries =
    List.map
      (fun r -> Printf.sprintf {|  {"name": "%s", "unit": "ops/sec", "value": %.2f}|} r.name r.ops_per_sec)
      results
  in
  print_endline "[";
  print_endline (String.concat ",\n" json_entries);
  print_endline "]"

let () =
  let args = Array.to_list Sys.argv in
  json_mode := List.mem "--json" args;

  let open Benchmark_scenarios in
  let results =
    [
      measure_benchmark ~name:"trivial/renderToStaticMarkup" (fun () -> ReactDOM.renderToStaticMarkup (Trivial.make ()));
      measure_benchmark ~name:"trivial/renderToString" (fun () -> ReactDOM.renderToString (Trivial.make ()));
      measure_benchmark ~name:"depth/10" (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth10.make ()));
      measure_benchmark ~name:"depth/25" (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth25.make ()));
      measure_benchmark ~name:"depth/50" (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth50.make ()));
      measure_benchmark ~name:"depth/100" (fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth100.make ()));
      measure_benchmark ~name:"width/10" (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide10.make ()));
      measure_benchmark ~name:"width/100" (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide100.make ()));
      measure_benchmark ~name:"width/500" (fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide500.make ()));
      measure_benchmark ~name:"table/10" (fun () -> ReactDOM.renderToStaticMarkup (Table.Table10.make ()));
      measure_benchmark ~name:"table/100" (fun () -> ReactDOM.renderToStaticMarkup (Table.Table100.make ()));
      measure_benchmark ~name:"table/500" (fun () -> ReactDOM.renderToStaticMarkup (Table.Table500.make ()));
      measure_benchmark ~name:"props/small" (fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Small.make ()));
      measure_benchmark ~name:"props/medium" (fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Medium.make ()));
      measure_benchmark ~name:"props/large" (fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Large.make ()));
      measure_benchmark ~name:"realworld/ecommerce24" (fun () ->
          ReactDOM.renderToStaticMarkup (Ecommerce.Products24.make ()));
      measure_benchmark ~name:"realworld/dashboard" (fun () -> ReactDOM.renderToStaticMarkup (Dashboard.make ()));
      measure_benchmark ~name:"realworld/blog50" (fun () -> ReactDOM.renderToStaticMarkup (Blog.Blog50.make ()));
      measure_benchmark ~name:"realworld/form" (fun () -> ReactDOM.renderToStaticMarkup (Form.make ()));
    ]
  in

  if !json_mode then print_results_json results else print_results_table results
