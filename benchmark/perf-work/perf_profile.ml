(* CPU-cycle profiling runner for SSR rendering.

   Companion to [alloc_profile.ml]. Where the allocation profiler answers
   "which source location allocated heap?", this runner answers "which
   source location spent CPU cycles?"

   This binary does not itself read hardware counters — those are unreliable
   under virtualization and need kernel configuration that varies by host.
   Instead, the binary is a minimal, deterministic render loop intended to
   be driven by an external sampling or instrumenting profiler:

     - [valgrind --tool=callgrind]: deterministic instruction/branch counts
       attributed to OCaml source locations via the debug-info in the
       unstripped executable. Recommended for ranking hypotheses because
       the numbers are reproducible across runs.

     - [perf stat -e cycles:u,instructions:u,...]: real hardware counters
       when the host permits. Faster than callgrind, but noisy and gated on
       [kernel.perf_event_paranoid]. Use for coarse wall-cycle totals.

     - [perf record -g]: sampled call-graph profile. Good for "where are
       the cycles?" visual answers (flamegraphs); less good for deciding
       between two candidate fixes because a 2% shift is inside the noise
       floor. Prefer callgrind for ranking.

   The companion driver [perf_profile.sh] orchestrates callgrind and perf
   invocations across all scenarios and aggregates the output into a table
   matching [alloc_profile.exe]'s format.

   Usage:

     dune build benchmark/perf-work/perf_profile.exe
     _build/default/benchmark/perf-work/perf_profile.exe --help

     # Standalone wall-clock run (no external profiler):
     _build/default/benchmark/perf-work/perf_profile.exe --scenario wide500

     # Driven by callgrind (from the driver script):
     valgrind --tool=callgrind --instr-atstart=no \
       --toggle-collect='camlReactDOM.renderToStaticMarkup_*' \
       _build/default/benchmark/perf-work/perf_profile.exe \
         --scenario wide500 --warmup 50 --iters 500

   Design notes:

   - No [Gc.Memprof] tracker: memprof adds per-alloc callstack capture cost
     that distorts cycle attribution. Run [alloc_profile.exe] separately
     for allocation questions.

   - GC behaviour is stabilized with [Gc.full_major] + [Gc.compact] before
     the timed loop, then a ref-kept [last_result] prevents the compiler
     from eliding the call to [f ()] entirely.

   - Warmup runs are emitted before instrumentation is toggled by the
     external profiler. The [--toggle-collect] flag above relies on the
     fact that [renderToStaticMarkup] is re-entered per iteration, so
     collection starts/stops on each boundary. Warmup amortizes first-call
     cache misses and JIT-like effects in the OCaml runtime (minor heap
     resize, Obj caching inside [Js_obj]) so the instrumented window
     reflects steady state. *)

open Benchmark_scenarios

type scenario = { name : string; run : unit -> string }

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
  ]

(* [sink] prevents [run] calls from being dead-code-eliminated. The compiler
   cannot know [run ()] has no observable effect (it allocates and writes to
   a buffer), but a redundant [ignore] at every call site risks codegen
   surprises under future flambda2 experiments. Storing the last result in a
   ref forces the result to be kept live across iterations. *)
let sink : string ref = ref ""

let run_loop ~warmup ~iters ~scenario =
  (* Stabilize GC state before the run so any minor/major collection inside
     the timed window is attributable to this scenario's allocation rate,
     not to prior test state. *)
  Gc.full_major ();
  Gc.compact ();
  (* Warmup: same entry point as the measured loop so the external profiler
     (if using [--toggle-collect]) picks up and discards these calls via
     its own warmup handling. *)
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
