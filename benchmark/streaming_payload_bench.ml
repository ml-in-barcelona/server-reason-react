let iterations = 300
let warmup_iterations = 20

let measure name render =
  for _ = 1 to warmup_iterations do
    Lwt_main.run (render ())
  done;
  Gc.full_major ();
  let start = Unix.gettimeofday () in
  for _ = 1 to iterations do
    Lwt_main.run (render ())
  done;
  let elapsed = Unix.gettimeofday () -. start in
  Printf.printf "METRIC %s=%.2f\n%!" name (float_of_int iterations /. elapsed)

let drain_ssr element =
  let%lwt stream, _abort = ReactDOM.renderToStream ~env:`Prod element in
  Lwt_stream.iter (fun _ -> ()) stream

let drain_rsc_html ?progressive_chunk_size element =
  let%lwt _shell, subscribe = ReactServerDOM.render_html ~env:`Prod ?progressive_chunk_size element in
  subscribe (fun _ -> Lwt.return ())

let async_boundaries count =
  let boundaries =
    Array.init count (fun index ->
        React.Suspense
          {
            key = None;
            fallback = Some (React.string "Loading");
            children =
              React.Async_component
                ( "StreamingPayloadBench",
                  fun () ->
                    let%lwt () = Lwt.pause () in
                    Lwt.return
                      (React.createElement "div"
                         [ React.JSX.int "data-index" "data-index" index ]
                         [ React.string "Resolved content" ]) );
          })
  in
  React.createElement "main" [] [ React.array boundaries ]

let wide100 () = Benchmark_scenarios.WideTree.Wide100.make (Benchmark_scenarios.WideTree.Wide100.makeProps ())

let () =
  measure "ssr_sync_ops_per_sec" (fun () -> drain_ssr (wide100 ()));
  measure "ssr_async_ops_per_sec" (fun () -> drain_ssr (async_boundaries 32));
  measure "rsc_model_ops_per_sec" (fun () ->
      ReactServerDOM.render_model ~env:`Prod ~subscribe:(fun _ -> Lwt.return ()) (wide100 ()));
  measure "rsc_html_async_ops_per_sec" (fun () -> drain_rsc_html ~progressive_chunk_size:1 (async_boundaries 32))
