/* Microbenchmarks using Core_bench for precise measurements */

open Core;
open Benchmark_scenarios;
module Bench = Core_bench.Bench;

let run_config =
  Bench.Run_config.create(
    ~quota=Bench.Quota.Num_calls(10000),
    ~stabilize_gc_between_runs=true,
    ~fork_each_benchmark=true,
    (),
  );

let analyze_and_display = tests => {
  let analysis_configs = [Bench.Analysis_config.nanos_vs_runs];
  let analyze = m => m |> Bench.analyze(~analysis_configs) |> Or_error.ok_exn;
  let measurements = Bench.measure(~run_config, tests);
  let results = List.map(measurements, ~f=analyze);
  Bench.display(results);
};

/* ============================================================================
   Trivial Benchmarks - Baseline measurements
   ============================================================================ */
let trivial_benchmarks = [
  Bench.Test.create(~name="trivial/render", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Trivial />);
    ();
  }),
  Bench.Test.create(~name="trivial/renderToString", () => {
    let _ = ReactDOM.renderToString(<Trivial />);
    ();
  }),
];

/* ============================================================================
   Depth Benchmarks - Tree depth scaling
   ============================================================================ */
let depth_benchmarks = [
  Bench.Test.create(~name="depth/10", () => {
    let _ = ReactDOM.renderToStaticMarkup(<DeepTree.Depth10 />);
    ();
  }),
  Bench.Test.create(~name="depth/25", () => {
    let _ = ReactDOM.renderToStaticMarkup(<DeepTree.Depth25 />);
    ();
  }),
  Bench.Test.create(~name="depth/50", () => {
    let _ = ReactDOM.renderToStaticMarkup(<DeepTree.Depth50 />);
    ();
  }),
  Bench.Test.create(~name="depth/100", () => {
    let _ = ReactDOM.renderToStaticMarkup(<DeepTree.Depth100 />);
    ();
  }),
];

/* ============================================================================
   Width Benchmarks - Sibling count scaling
   ============================================================================ */
let width_benchmarks = [
  Bench.Test.create(~name="width/10", () => {
    let _ = ReactDOM.renderToStaticMarkup(<WideTree.Wide10 />);
    ();
  }),
  Bench.Test.create(~name="width/100", () => {
    let _ = ReactDOM.renderToStaticMarkup(<WideTree.Wide100 />);
    ();
  }),
  Bench.Test.create(~name="width/500", () => {
    let _ = ReactDOM.renderToStaticMarkup(<WideTree.Wide500 />);
    ();
  }),
  Bench.Test.create(~name="width/1000", () => {
    let _ = ReactDOM.renderToStaticMarkup(<WideTree.Wide1000 />);
    ();
  }),
];

/* ============================================================================
   Table Benchmarks - Real-world data table
   ============================================================================ */
let table_benchmarks = [
  Bench.Test.create(~name="table/10", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Table.Table10 />);
    ();
  }),
  Bench.Test.create(~name="table/50", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Table.Table50 />);
    ();
  }),
  Bench.Test.create(~name="table/100", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Table.Table100 />);
    ();
  }),
  Bench.Test.create(~name="table/500", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Table.Table500 />);
    ();
  }),
];

/* ============================================================================
   Props Heavy Benchmarks - Attribute-heavy components
   ============================================================================ */
let props_benchmarks = [
  Bench.Test.create(~name="props/small", () => {
    let _ = ReactDOM.renderToStaticMarkup(<PropsHeavy.Small />);
    ();
  }),
  Bench.Test.create(~name="props/medium", () => {
    let _ = ReactDOM.renderToStaticMarkup(<PropsHeavy.Medium />);
    ();
  }),
  Bench.Test.create(~name="props/large", () => {
    let _ = ReactDOM.renderToStaticMarkup(<PropsHeavy.Large />);
    ();
  }),
];

/* ============================================================================
   Real-World Benchmarks - Complete page scenarios
   ============================================================================ */
let realworld_benchmarks = [
  Bench.Test.create(~name="realworld/ecommerce24", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Ecommerce.Products24 />);
    ();
  }),
  Bench.Test.create(~name="realworld/ecommerce48", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Ecommerce.Products48 />);
    ();
  }),
  Bench.Test.create(~name="realworld/dashboard", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Dashboard />);
    ();
  }),
  Bench.Test.create(~name="realworld/blog50", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Blog.Blog50 />);
    ();
  }),
  Bench.Test.create(~name="realworld/form", () => {
    let _ = ReactDOM.renderToStaticMarkup(<Form />);
    ();
  }),
];

/* ============================================================================
   React Primitives Benchmarks - Low-level operations
   ============================================================================ */
let primitives_benchmarks = [
  Bench.Test.create(~name="primitive/React.string", () => {
    let _ = ReactDOM.renderToStaticMarkup(React.string("Hello"));
    ();
  }),
  Bench.Test.create(~name="primitive/React.int", () => {
    let _ = ReactDOM.renderToStaticMarkup(React.int(42));
    ();
  }),
  Bench.Test.create(~name="primitive/React.null", () => {
    let _ = ReactDOM.renderToStaticMarkup(React.null);
    ();
  }),
  Bench.Test.create(~name="primitive/createElement_empty", () => {
    let _ =
      ReactDOM.renderToStaticMarkup(React.createElement("div", [], []));
    ();
  }),
  Bench.Test.create(~name="primitive/createElement_children", () => {
    let children = List.init(10, ~f=i => React.string(Int.to_string(i)));
    let _ =
      ReactDOM.renderToStaticMarkup(
        React.createElement("div", [], children),
      );
    ();
  }),
  Bench.Test.create(~name="primitive/React.array_10", () => {
    let arr = Array.init(10, ~f=i => React.string(Int.to_string(i)));
    let _ =
      ReactDOM.renderToStaticMarkup(
        React.createElement("div", [], [React.array(arr)]),
      );
    ();
  }),
  Bench.Test.create(~name="primitive/React.array_100", () => {
    let arr = Array.init(100, ~f=i => React.string(Int.to_string(i)));
    let _ =
      ReactDOM.renderToStaticMarkup(
        React.createElement("div", [], [React.array(arr)]),
      );
    ();
  }),
  Bench.Test.create(~name="primitive/React.list_10", () => {
    let list = List.init(10, ~f=i => React.string(Int.to_string(i)));
    let _ =
      ReactDOM.renderToStaticMarkup(
        React.createElement("div", [], [React.list(list)]),
      );
    ();
  }),
  Bench.Test.create(~name="primitive/React.list_100", () => {
    let list = List.init(100, ~f=i => React.string(Int.to_string(i)));
    let _ =
      ReactDOM.renderToStaticMarkup(
        React.createElement("div", [], [React.list(list)]),
      );
    ();
  }),
];

/* ============================================================================
   All benchmarks combined
   ============================================================================ */
let all_benchmarks =
  List.concat([
    trivial_benchmarks,
    depth_benchmarks,
    width_benchmarks,
    table_benchmarks,
    props_benchmarks,
    realworld_benchmarks,
    primitives_benchmarks,
  ]);

/* ============================================================================
   Main - Run selected benchmark suite
   ============================================================================ */
let () = {
  let args = Sys.get_argv() |> Array.to_list;

  let suite =
    switch (List.nth(args, 1)) {
    | Some("trivial") => trivial_benchmarks
    | Some("depth") => depth_benchmarks
    | Some("width") => width_benchmarks
    | Some("table") => table_benchmarks
    | Some("props") => props_benchmarks
    | Some("realworld") => realworld_benchmarks
    | Some("primitives") => primitives_benchmarks
    | Some("all") => all_benchmarks
    | _ =>
      print_endline("Usage: micro_bench.exe <suite>");
      print_endline("");
      print_endline("Suites:");
      print_endline("  trivial    - Baseline measurements");
      print_endline("  depth      - Tree depth scaling");
      print_endline("  width      - Sibling count scaling");
      print_endline("  table      - Data table rendering");
      print_endline("  props      - Attribute-heavy components");
      print_endline("  realworld  - Complete page scenarios");
      print_endline("  primitives - Low-level React operations");
      print_endline("  all        - Run all suites");
      print_endline("");
      exit(1);
    };

  print_endline("\n=== server-reason-react Microbenchmarks ===\n");
  analyze_and_display(suite);
};
