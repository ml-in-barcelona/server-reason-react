type benchmark = { name : string; run : unit -> unit }
type result = { name : string; nanoseconds : float; words : float }

let sink = ref 0
let samples = 7
let sample_seconds = 0.03
let route ~id ~path = RouterServer.Route.make ~id ~path

let registry routes =
  match RouterServer.Registry.make routes with
  | Ok registry -> registry
  | Error _ -> failwith "invalid benchmark registry"

let static_registry count =
  List.init count (fun index ->
      let value = Printf.sprintf "%04d" index in
      route ~id:("static-" ^ value) ~path:("/static/" ^ value))
  |> registry

let dynamic_registry count =
  List.init count (fun index ->
      let value = Printf.sprintf "%04d" index in
      route ~id:("dynamic-" ^ value) ~path:("/resource/" ^ value ^ "/:id<string>"))
  |> registry

let endpoint ~id ~path =
  RouterServer.Endpoint.make ~id ~path ~activeRoutes:[] ~fingerprint:id ~decode:(fun _ ->
      Ok
        (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
             RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:()))))

let static_endpoint_registry count =
  List.init count (fun index ->
      let value = Printf.sprintf "%04d" index in
      endpoint ~id:("static-" ^ value) ~path:("/static/" ^ value))
  |> RouterServer.EndpointRegistry.makeExn

let dynamic_endpoint_registry count =
  List.init count (fun index ->
      let value = Printf.sprintf "%04d" index in
      endpoint ~id:("dynamic-" ^ value) ~path:("/resource/" ^ value ^ "/:id<string>"))
  |> RouterServer.EndpointRegistry.makeExn

let consume_match registry pathname () =
  match RouterServer.Match.find registry ~pathname with
  | Ok (Some matched) -> sink := !sink + String.length (RouterServer.Route.id matched.route)
  | Ok None -> sink := !sink + 1
  | Error _ -> sink := !sink + 2

let consume_path pathname () =
  match RouterServer.Path.decodePathname pathname with
  | Ok segments -> sink := !sink + List.length segments
  | Error _ -> sink := !sink + 1

let consume_endpoint_match registry pathname () =
  match RouterServer.EndpointRegistry.find registry ~pathname with
  | Ok (Some matched) ->
      sink := !sink + String.length (RouterServer.EndpointRegistry.route matched |> RouterServer.Route.id)
  | Ok None -> sink := !sink + 1
  | Error _ -> sink := !sink + 2

let consume_search search () =
  match RouterServer.Search.parse search with
  | Ok parsed -> sink := !sink + List.length (RouterServer.Search.values parsed "tag")
  | Error _ -> sink := !sink + 1

let run_iterations iterations run =
  for _ = 1 to iterations do
    run ()
  done

let elapsed iterations run =
  let start = Unix.gettimeofday () in
  run_iterations iterations run;
  Unix.gettimeofday () -. start

let calibrate run =
  let rec loop iterations =
    let duration = elapsed iterations run in
    if duration >= sample_seconds || iterations >= 1_048_576 then iterations
    else
      let scale = max 2 (int_of_float (sample_seconds /. max duration 0.000_001)) in
      loop (min 1_048_576 (iterations * scale))
  in
  loop 1

let median values =
  let values = Array.of_list values in
  Array.sort Float.compare values;
  values.(Array.length values / 2)

let measure benchmark =
  run_iterations 100 benchmark.run;
  let iterations = calibrate benchmark.run in
  let rec collect count timings allocations =
    if count = 0 then { name = benchmark.name; nanoseconds = median timings; words = median allocations }
    else (
      Gc.full_major ();
      let allocated_before = Gc.allocated_bytes () in
      let duration = elapsed iterations benchmark.run in
      let allocated = Gc.allocated_bytes () -. allocated_before in
      let divisor = float_of_int iterations in
      collect (count - 1)
        ((duration *. 1_000_000_000. /. divisor) :: timings)
        ((allocated /. float_of_int (Sys.word_size / 8) /. divisor) :: allocations))
  in
  collect samples [] []

let geomean values =
  let total = List.fold_left (fun sum value -> sum +. log value) 0. values in
  exp (total /. float_of_int (List.length values))

let print_table results =
  Printf.printf "\n%-36s %12s %12s\n" "Benchmark" "ns/op" "words/op";
  Printf.printf "%s\n" (String.make 62 '-');
  List.iter (fun result -> Printf.printf "%-36s %12.1f %12.1f\n" result.name result.nanoseconds result.words) results

let print_json results =
  let entries =
    List.map
      (fun result ->
        Printf.sprintf {|  {"name": "router/%s", "unit": "ops/sec", "value": %.2f}|} result.name
          (1_000_000_000. /. result.nanoseconds))
      results
  in
  Printf.printf "[\n%s\n]\n" (String.concat ",\n" entries)

let print_metrics results =
  let latency = geomean (List.map (fun result -> result.nanoseconds) results) in
  let words =
    List.fold_left (fun total result -> total +. result.words) 0. results /. float_of_int (List.length results)
  in
  List.iter
    (fun result -> Printf.printf "CASE name=%s ns=%.3f words=%.3f\n" result.name result.nanoseconds result.words)
    results;
  Printf.printf "METRIC router_geomean_ns=%.3f\n" latency;
  Printf.printf "METRIC router_mean_words=%.3f\n" words

let () =
  let small_static = static_registry 16 in
  let large_static = static_registry 512 in
  let large_dynamic = dynamic_registry 512 in
  let large_static_endpoints = static_endpoint_registry 512 in
  let large_dynamic_endpoints = dynamic_endpoint_registry 512 in
  let benchmarks =
    [
      { name = "match/static-small-first"; run = consume_match small_static "/static/0000" };
      { name = "match/static-small-last"; run = consume_match small_static "/static/0015" };
      { name = "match/static-large-first"; run = consume_match large_static "/static/0000" };
      { name = "match/static-large-last"; run = consume_match large_static "/static/0511" };
      { name = "match/static-large-miss"; run = consume_match large_static "/static/missing" };
      { name = "match/dynamic-large-first"; run = consume_match large_dynamic "/resource/0000/alpha" };
      { name = "match/dynamic-large-last"; run = consume_match large_dynamic "/resource/0511/alpha" };
      { name = "endpoint/static-large-last"; run = consume_endpoint_match large_static_endpoints "/static/0511" };
      {
        name = "endpoint/dynamic-large-last";
        run = consume_endpoint_match large_dynamic_endpoints "/resource/0511/alpha";
      };
      { name = "parse/path-plain"; run = consume_path "/api/projects/alpha/issues/42" };
      { name = "parse/path-encoded"; run = consume_path "/api/projects/caf%C3%A9/issues/hello%20world" };
      { name = "parse/search"; run = consume_search "?tag=one&tag=two&page=42&filter=caf%C3%A9+open" };
    ]
  in
  let results = List.map measure benchmarks in
  if Array.exists (String.equal "--json") Sys.argv then print_json results
  else if Array.exists (String.equal "--metrics") Sys.argv then print_metrics results
  else print_table results
