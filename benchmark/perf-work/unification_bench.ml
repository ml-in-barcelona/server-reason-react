(* Microbench: Static vs Writer unification. *)

let bench label iterations f =
  Gc.full_major ();
  Gc.compact ();
  let before = (Gc.stat ()).minor_words in
  let t0 = Unix.gettimeofday () in
  for _ = 1 to iterations do
    let _ = f () in
    ()
  done;
  let t1 = Unix.gettimeofday () in
  let after = (Gc.stat ()).minor_words in
  let avg_ns = (t1 -. t0) *. 1e9 /. float_of_int iterations in
  let avg_words = (after -. before) /. float_of_int iterations in
  Printf.printf "%-55s %.1f ns/op  %.1f words/op\n" label avg_ns avg_words

(* Construction only — no render involved. *)
let make_static () : React.element = React.Static { prerendered = "<div>foo</div>"; original = React.Empty }

let make_writer () : React.element =
  React.Writer { emit = (fun b -> Buffer.add_string b "<div>foo</div>"); original = (fun () -> React.Empty) }

(* Workload that mirrors WideTree500: construct 500 fresh elements and
   render into a SHARED buffer (simulating being inside a parent emit). *)
let write_many_into_buf make =
  let buf = Buffer.create 65536 in
  for _ = 1 to 500 do
    let el = make () in
    ReactDOM.write_to_buffer buf el
  done

(* Just construct 500, no render. Isolate allocation cost. *)
let construct_many make =
  for _ = 1 to 500 do
    let _ = make () in
    ()
  done

let () =
  Printf.printf "\n--- Just construction, 500x (100 iters) ---\n";
  bench "Static: 500 construct only" 100 (fun () -> construct_many make_static);
  bench "Writer: 500 construct only" 100 (fun () -> construct_many make_writer);

  Printf.printf "\n--- 500 fresh make+write_to_buffer into shared buf (100 iters) ---\n";
  bench "Static: 500 make+write_to_buffer" 100 (fun () -> write_many_into_buf make_static);
  bench "Writer: 500 make+write_to_buffer" 100 (fun () -> write_many_into_buf make_writer);

  Printf.printf "\n--- Construction cost (100_000 iters, per-call) ---\n";
  bench "Static construction" 100_000 make_static;
  bench "Writer construction" 100_000 make_writer;

  Printf.printf "\n(Per-operation: divide by 500 in 500x bench)\n"
