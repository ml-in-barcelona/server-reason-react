(** Memory Benchmark Suite for server-reason-react

    Measures:
    - Memory allocation per render
    - GC pressure (minor/major collections)
    - Peak memory usage
    - Memory efficiency compared to output size *)

module Gc_stats = struct
  type t = {
    minor_words : float;
    major_words : float;
    minor_collections : int;
    major_collections : int;
    heap_words : int;
    compactions : int;
  }

  let capture () =
    let stat = Gc.stat () in
    {
      minor_words = stat.minor_words;
      major_words = stat.major_words;
      minor_collections = stat.minor_collections;
      major_collections = stat.major_collections;
      heap_words = stat.heap_words;
      compactions = stat.compactions;
    }

  let diff before after =
    {
      minor_words = after.minor_words -. before.minor_words;
      major_words = after.major_words -. before.major_words;
      minor_collections = after.minor_collections - before.minor_collections;
      major_collections = after.major_collections - before.major_collections;
      heap_words = after.heap_words - before.heap_words;
      compactions = after.compactions - before.compactions;
    }
end

type scenario_result = {
  name : string;
  iterations : int;
  output_bytes : int;
  total_minor_words : float;
  total_major_words : float;
  minor_collections : int;
  major_collections : int;
  avg_minor_words_per_iter : float;
  bytes_per_word : float;
}

let measure_scenario ~name ~iterations render_fn =
  (* Stabilize GC first *)
  Gc.full_major ();
  Gc.compact ();

  let before = Gc_stats.capture () in

  let output_bytes = ref 0 in
  for _ = 1 to iterations do
    let html = render_fn () in
    output_bytes := !output_bytes + String.length html
  done;

  let after = Gc_stats.capture () in
  let diff = Gc_stats.diff before after in

  {
    name;
    iterations;
    output_bytes = !output_bytes;
    total_minor_words = diff.minor_words;
    total_major_words = diff.major_words;
    minor_collections = diff.minor_collections;
    major_collections = diff.major_collections;
    avg_minor_words_per_iter = diff.minor_words /. float_of_int iterations;
    bytes_per_word = float_of_int !output_bytes /. (diff.minor_words +. diff.major_words);
  }

let print_result r =
  Printf.printf "\n%s\n" (String.make 60 '=');
  Printf.printf "Scenario: %s\n" r.name;
  Printf.printf "%s\n" (String.make 60 '-');
  Printf.printf "Iterations:           %d\n" r.iterations;
  Printf.printf "Output size:          %d bytes (%.2f KB/iter)\n" r.output_bytes
    (float_of_int r.output_bytes /. float_of_int r.iterations /. 1024.0);
  Printf.printf "Minor words total:    %.0f (%.0f/iter)\n" r.total_minor_words r.avg_minor_words_per_iter;
  Printf.printf "Major words total:    %.0f\n" r.total_major_words;
  Printf.printf "Minor GC cycles:      %d\n" r.minor_collections;
  Printf.printf "Major GC cycles:      %d\n" r.major_collections;
  Printf.printf "Output/allocation:    %.4f bytes/word\n" r.bytes_per_word

let print_summary_table results =
  Printf.printf "\n%s\n" (String.make 80 '=');
  Printf.printf "SUMMARY TABLE\n";
  Printf.printf "%s\n" (String.make 80 '=');
  Printf.printf "%-20s %10s %15s %12s %10s\n" "Scenario" "KB/iter" "Words/iter" "MinorGC" "MajorGC";
  Printf.printf "%s\n" (String.make 80 '-');

  List.iter
    (fun r ->
      Printf.printf "%-20s %10.2f %15.0f %12d %10d\n" r.name
        (float_of_int r.output_bytes /. float_of_int r.iterations /. 1024.0)
        r.avg_minor_words_per_iter r.minor_collections r.major_collections)
    results;

  Printf.printf "%s\n" (String.make 80 '=')

let print_json results =
  Printf.printf "\n{\n  \"results\": [\n";
  let rec print_list = function
    | [] -> ()
    | [ r ] ->
        Printf.printf
          "    {\"name\": \"%s\", \"iterations\": %d, \"output_bytes\": %d, \"minor_words_per_iter\": %.0f, \
           \"major_words_total\": %.0f, \"minor_gc\": %d, \"major_gc\": %d}"
          r.name r.iterations r.output_bytes r.avg_minor_words_per_iter r.total_major_words r.minor_collections
          r.major_collections
    | r :: rest ->
        Printf.printf
          "    {\"name\": \"%s\", \"iterations\": %d, \"output_bytes\": %d, \"minor_words_per_iter\": %.0f, \
           \"major_words_total\": %.0f, \"minor_gc\": %d, \"major_gc\": %d},\n"
          r.name r.iterations r.output_bytes r.avg_minor_words_per_iter r.total_major_words r.minor_collections
          r.major_collections;
        print_list rest
  in
  print_list results;
  Printf.printf "\n  ]\n}\n"

let () =
  let iterations = 1000 in

  Printf.printf "Memory Benchmark for server-reason-react\n";
  Printf.printf "Iterations per scenario: %d\n" iterations;
  Printf.printf "OCaml version: %s\n" Sys.ocaml_version;

  let scenarios =
    let open Benchmark_scenarios in
    [
      ("Trivial", fun () -> ReactDOM.renderToStaticMarkup (Trivial.make ()));
      ("ShallowTree", fun () -> ReactDOM.renderToStaticMarkup (ShallowTree.make ()));
      ("DeepTree10", fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth10.make ()));
      ("DeepTree50", fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth50.make ()));
      ("WideTree10", fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide10.make ()));
      ("WideTree100", fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide100.make ()));
      ("Table10", fun () -> ReactDOM.renderToStaticMarkup (Table.Table10.make ()));
      ("Table100", fun () -> ReactDOM.renderToStaticMarkup (Table.Table100.make ()));
      ("PropsSmall", fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Small.make ()));
      ("PropsMedium", fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Medium.make ()));
      ("Dashboard", fun () -> ReactDOM.renderToStaticMarkup (Dashboard.make ()));
      ("Form", fun () -> ReactDOM.renderToStaticMarkup (Form.make ()));
    ]
  in

  let results =
    List.map
      (fun (name, render_fn) ->
        let result = measure_scenario ~name ~iterations render_fn in
        print_result result;
        result)
      scenarios
  in

  print_summary_table results;

  (* Also output JSON for programmatic consumption *)
  if Array.length Sys.argv > 1 && Sys.argv.(1) = "--json" then print_json results
