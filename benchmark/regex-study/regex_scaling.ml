let dense_input n = String.init n (fun i -> if i mod 10 = 9 then 'x' else 'a')
let sparse_input n = String.make n 'a'

let dense_utf8_input n =
  let block = "ééééx" in
  let block_bytes = String.length block in
  String.concat "" (List.init (n / block_bytes) (fun _ -> block)) ^ String.make (n mod block_bytes) 'a'

let measure ~iterations f =
  for _ = 1 to 5 do
    ignore (Sys.opaque_identity (f ()))
  done;
  Gc.full_major ();
  let before = Gc.allocated_bytes () in
  let started = Unix.gettimeofday () in
  for _ = 1 to iterations do
    ignore (Sys.opaque_identity (f ()))
  done;
  let elapsed = Unix.gettimeofday () -. started in
  let allocated = Gc.allocated_bytes () -. before in
  (elapsed *. 1e6 /. Float.of_int iterations, allocated /. Float.of_int iterations)

let run_case ?(make_input = dense_input) ?(match_count = fun size -> size / 10) ~name ~sizes ~iterations make_f =
  Printf.printf "\n%s\n" name;
  Printf.printf "%8s %8s %14s %16s\n" "bytes" "matches" "us/op" "allocated/op";
  List.iter
    (fun size ->
      let input = make_input size in
      let us, allocated = measure ~iterations:(iterations size) (make_f input) in
      Printf.printf "%8d %8d %14.2f %16.0f\n" (String.length input) (match_count size) us allocated)
    sizes

let () =
  let sizes = [ 1_000; 2_000; 4_000; 8_000; 16_000 ] in
  let iterations size = if size <= 2_000 then 200 else if size <= 8_000 then 50 else 10 in

  run_case ~name:"replaceByRe /x/g -> y, 10% matches" ~sizes ~iterations (fun input () ->
      Js.String.replaceByRe ~regexp:(Js.Re.fromStringWithFlags "x" ~flags:"g") ~replacement:"y" input);

  run_case ~name:"Js.Re.exec loop /x/g, discard matches" ~sizes ~iterations (fun input () ->
      let regexp = Js.Re.fromStringWithFlags "x" ~flags:"g" in
      let rec loop () = match Js.Re.exec ~str:input regexp with None -> () | Some _ -> loop () in
      loop ());

  run_case ~name:"Js.Re.Prepared.exec loop /x/g, discard matches" ~sizes ~iterations (fun input () ->
      let regexp = Js.Re.fromStringWithFlags "x" ~flags:"g" in
      let prepared = Js.Re.Prepared.make input in
      let rec loop () = match Js.Re.Prepared.exec prepared regexp with None -> () | Some _ -> loop () in
      loop ());

  run_case ~name:"byte_index_of_utf16 loop, every tenth index" ~sizes ~iterations (fun input () ->
      for index = 1 to String.length input / 10 do
        ignore (Quickjs.String.byte_index_of_utf16 input (index * 10))
      done);

  run_case ~name:"splitByRe /(x)/g, 10% matches" ~sizes ~iterations (fun input () ->
      Js.String.splitByRe ~regexp:(Js.Re.fromStringWithFlags "(x)" ~flags:"g") input);

  let utf8_matches size = size / String.length "ééééx" in
  run_case ~make_input:dense_utf8_input ~match_count:utf8_matches ~name:"replaceByRe /x/g -> y, UTF-8 input" ~sizes
    ~iterations (fun input () ->
      Js.String.replaceByRe ~regexp:(Js.Re.fromStringWithFlags "x" ~flags:"g") ~replacement:"y" input);

  run_case ~make_input:dense_utf8_input ~match_count:utf8_matches ~name:"splitByRe /(x)/g, UTF-8 input" ~sizes
    ~iterations (fun input () -> Js.String.splitByRe ~regexp:(Js.Re.fromStringWithFlags "(x)" ~flags:"g") input);

  Printf.printf "\nreplaceByRe /x/g -> y, no matches\n";
  Printf.printf "%8s %14s %16s\n" "bytes" "us/op" "allocated/op";
  List.iter
    (fun size ->
      let input = sparse_input size in
      let us, allocated =
        measure ~iterations:500 (fun () ->
            Js.String.replaceByRe ~regexp:(Js.Re.fromStringWithFlags "x" ~flags:"g") ~replacement:"y" input)
      in
      Printf.printf "%8d %14.2f %16.0f\n" size us allocated)
    sizes
