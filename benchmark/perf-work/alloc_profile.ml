(* Allocation profiler for SSR rendering.

   Uses [Gc.Memprof] to attribute minor/major-heap allocations to source
   locations in the call stack. Output is an aggregated table: for each
   scenario, list the top allocation sites by attributed sample count.

   Usage:

     dune build benchmark/perf-work/alloc_profile.exe
     _build/default/benchmark/perf-work/alloc_profile.exe
     _build/default/benchmark/perf-work/alloc_profile.exe --scenario wide500
     _build/default/benchmark/perf-work/alloc_profile.exe --top 30

   The sampling rate is tuned for ~100k samples per scenario. Raise
   [--rate] for higher precision at the cost of runtime overhead. *)

open Benchmark_scenarios

(* A sample is keyed by a short textual rendering of its callstack. We
   keep the top [callstack_depth] frames to avoid over-splitting (each
   allocation in OCaml has a slightly different stack at the top because
   of inlining decisions; trimming deep frames groups related sites). *)
let callstack_depth = 6
let default_sampling_rate = 1e-4

(* Mutable aggregation table keyed by trimmed callstack string. *)
module Site_table = Hashtbl.Make (struct
  type t = string

  let equal = String.equal
  let hash = Hashtbl.hash
end)

type site_stats = { mutable samples : int; mutable bytes : int }

let make_tracker (table : site_stats Site_table.t) : (unit, unit) Gc.Memprof.tracker =
  let on_alloc (alloc : Gc.Memprof.allocation) =
    let slots = Printexc.backtrace_slots alloc.callstack in
    let key =
      match slots with
      | None -> "<unknown>"
      | Some arr ->
          let len = min callstack_depth (Array.length arr) in
          let buf = Buffer.create 128 in
          for i = 0 to len - 1 do
            match Printexc.Slot.format i arr.(i) with
            | Some s ->
                if i > 0 then Buffer.add_string buf " <- ";
                Buffer.add_string buf s
            | None -> ()
          done;
          Buffer.contents buf
    in
    let stats =
      match Site_table.find_opt table key with
      | Some s -> s
      | None ->
          let s = { samples = 0; bytes = 0 } in
          Site_table.add table key s;
          s
    in
    stats.samples <- stats.samples + alloc.n_samples;
    stats.bytes <- stats.bytes + (alloc.size * Sys.word_size / 8);
    Some ()
  in
  {
    Gc.Memprof.alloc_minor = on_alloc;
    alloc_major = on_alloc;
    promote = (fun () -> None);
    dealloc_minor = (fun () -> ());
    dealloc_major = (fun () -> ());
  }

type run_result = {
  elapsed : float;
  iterations : int;
  minor_words : float;
  major_words : float;
  promoted_words : float;
  table : site_stats Site_table.t;
}

let run_with_memprof ~sampling_rate ~iterations ~name f =
  Printexc.record_backtrace true;
  Gc.full_major ();
  Gc.compact ();
  let table : site_stats Site_table.t = Site_table.create 1024 in
  let tracker = make_tracker table in
  let _handle = Gc.Memprof.start ~sampling_rate ~callstack_size:32 tracker in
  let before = Gc.quick_stat () in
  let t0 = Unix.gettimeofday () in
  for _ = 1 to iterations do
    let _ = f () in
    ()
  done;
  let t1 = Unix.gettimeofday () in
  let after = Gc.quick_stat () in
  Gc.Memprof.stop ();
  let minor = after.minor_words -. before.minor_words in
  let major = after.major_words -. before.major_words in
  let promoted = after.promoted_words -. before.promoted_words in
  (name, { elapsed = t1 -. t0; iterations; minor_words = minor; major_words = major; promoted_words = promoted; table })

let print_report ~top (name, result) =
  Printf.printf "\n### %s\n" name;
  Printf.printf "  iterations: %d  elapsed: %.3fs  per-iter: %.2fµs\n" result.iterations result.elapsed
    (result.elapsed *. 1e6 /. float_of_int result.iterations);
  Printf.printf "  minor words: %.0f  (%.0f per iter)\n" result.minor_words
    (result.minor_words /. float_of_int result.iterations);
  Printf.printf "  major words: %.0f  promoted: %.0f\n" result.major_words result.promoted_words;
  let sites =
    Site_table.fold (fun k v acc -> (k, v) :: acc) result.table []
    |> List.sort (fun (_, a) (_, b) -> compare b.samples a.samples)
  in
  let total_samples = List.fold_left (fun acc (_, s) -> acc + s.samples) 0 sites in
  Printf.printf "\n  Top %d allocation sites (total samples: %d):\n" top total_samples;
  Printf.printf "  %-8s  %-8s  %s\n" "samples" "share" "callstack";
  Printf.printf "  %s\n" (String.make 70 '-');
  let shown = ref 0 in
  List.iter
    (fun (k, s) ->
      if !shown < top then begin
        let share = if total_samples = 0 then 0.0 else float_of_int s.samples *. 100.0 /. float_of_int total_samples in
        Printf.printf "  %-8d  %6.2f%%   %s\n" s.samples share k;
        incr shown
      end)
    sites

let scenarios =
  [
    ("wide100", fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide100.make (WideTree.Wide100.makeProps ())));
    ("wide500", fun () -> ReactDOM.renderToStaticMarkup (WideTree.Wide500.make (WideTree.Wide500.makeProps ())));
    ("table100", fun () -> ReactDOM.renderToStaticMarkup (Table.Table100.make (Table.Table100.makeProps ())));
    ("table500", fun () -> ReactDOM.renderToStaticMarkup (Table.Table500.make (Table.Table500.makeProps ())));
    ("deep50", fun () -> ReactDOM.renderToStaticMarkup (DeepTree.Depth50.make (DeepTree.Depth50.makeProps ())));
    ("propsmedium", fun () -> ReactDOM.renderToStaticMarkup (PropsHeavy.Medium.make (PropsHeavy.Medium.makeProps ())));
    ("form", fun () -> ReactDOM.renderToStaticMarkup (Form.make (Form.makeProps ())));
    ("dashboard", fun () -> ReactDOM.renderToStaticMarkup (Dashboard.make (Dashboard.makeProps ())));
    ("blog50", fun () -> ReactDOM.renderToStaticMarkup (Blog.Blog50.make (Blog.Blog50.makeProps ())));
    ( "ecommerce48",
      fun () -> ReactDOM.renderToStaticMarkup (Ecommerce.Products48.make (Ecommerce.Products48.makeProps ())) );
  ]

let default_iterations = 2000

let usage () =
  print_endline "Usage: alloc_profile.exe [--scenario NAME] [--rate FLOAT] [--iters N] [--top N]";
  print_endline "";
  print_endline "Scenarios:";
  List.iter (fun (n, _) -> Printf.printf "  - %s\n" n) scenarios

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  let selected = ref None in
  let sampling_rate = ref default_sampling_rate in
  let iterations = ref default_iterations in
  let top = ref 20 in
  let rec parse = function
    | [] -> ()
    | "--scenario" :: v :: rest ->
        selected := Some v;
        parse rest
    | "--rate" :: v :: rest ->
        sampling_rate := float_of_string v;
        parse rest
    | "--iters" :: v :: rest ->
        iterations := int_of_string v;
        parse rest
    | "--top" :: v :: rest ->
        top := int_of_string v;
        parse rest
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
    | Some name ->
        (match List.assoc_opt name scenarios with
        | Some _ -> ()
        | None ->
            Printf.eprintf "Unknown scenario: %s\n" name;
            usage ();
            exit 2);
        [ (name, List.assoc name scenarios) ]
  in
  Printf.printf "=== alloc_profile ===\n";
  Printf.printf "sampling_rate=%g  iterations=%d  top=%d\n" !sampling_rate !iterations !top;
  List.iter
    (fun (name, f) ->
      let result = run_with_memprof ~sampling_rate:!sampling_rate ~iterations:!iterations ~name f in
      print_report ~top:!top result)
    to_run
