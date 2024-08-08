module Bench = Core_bench.Bench;

module TinyApp = {
  [@react.component]
  let make = () => {
    <html>
      <body>
        <h1> {React.string("Hello World")} </h1>
        <p> {React.string("This is an example")} </p>
      </body>
    </html>;
  };
};

let bench_static_markup_with_simple_app =
  Bench.Test.create(~name="bench_static_markup_with_simple_app", () =>
    ReactDOM.renderToStaticMarkup(<TinyApp />)
  );

let main = tests => {
  Printf.printf("\n\nRunning benchmarks\n");
  Bench.bench(
    ~analysis_configs=
      Bench.Analysis_config.default
      |> List.map(
           Bench.Analysis_config.with_error_estimation(
             ~bootstrap_trials=10000,
           ),
         ),
    ~run_config=
      Bench.Run_config.create(
        ~quota=Bench.Quota.Num_calls(100000),
        ~stabilize_gc_between_runs=true,
        ~fork_each_benchmark=true,
        (),
      ),
    ~save_to_file=
      measurement =>
        "bench/results/" ++ Bench.Measurement.name(measurement) ++ ".csv",
    tests,
  );
};

main([bench_static_markup_with_simple_app]);
