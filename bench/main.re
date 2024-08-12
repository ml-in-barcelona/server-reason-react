open Core;

module Bench = Core_bench.Bench;

let print_list_of_files = filenames => {
  print_endline("\nList of measurements:");
  List.iter(filenames, ~f=print_endline);
  print_endline("");
};

let run_config =
  Bench.Run_config.create(
    ~quota=Bench.Quota.Num_calls(10000),
    ~stabilize_gc_between_runs=true,
    ~fork_each_benchmark=true,
    (),
  );

let run = (tests: list(Bench.Test.t)) => {
  let filenames =
    List.map(
      ~f=test => {Printf.sprintf("%s.csv", Bench.Test.name(test))},
      tests,
    );
  print_list_of_files(filenames);
  let analysis_configs = [Bench.Analysis_config.nanos_vs_runs];
  let analyze = m => m |> Bench.analyze(~analysis_configs) |> Or_error.ok_exn;

  let measurements = Bench.measure(~run_config, tests);
  let results = List.map(measurements, ~f=analyze);
  Bench.display(results);
};

let test_component =
  Bench.Test.create(~name="renderToStaticMarkup_component", () => {
    ignore(ReactDOM.renderToStaticMarkup(<HelloWorld />))
  });

let test_app =
  Bench.Test.create(~name="renderToStaticMarkup_app", () => {
    ignore(ReactDOM.renderToStaticMarkup(<App />))
  });

run([test_component, test_app]);
