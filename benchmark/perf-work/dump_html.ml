(* Dump HTML for comparison *)
let () =
  let which = try Sys.argv.(1) with _ -> "PropsSmall" in
  let html =
    match which with
    | "PropsSmall" ->
        ReactDOM.renderToStaticMarkup
          (Benchmark_scenarios.PropsHeavy.Small.make (Benchmark_scenarios.PropsHeavy.Small.makeProps ()))
    | "PropsMedium" ->
        ReactDOM.renderToStaticMarkup
          (Benchmark_scenarios.PropsHeavy.Medium.make (Benchmark_scenarios.PropsHeavy.Medium.makeProps ()))
    | _ -> failwith "unknown"
  in
  print_string html
