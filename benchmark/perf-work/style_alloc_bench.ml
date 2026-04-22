(* Measure Style.make allocation after PPX rewrite. *)

let bench label f =
  Gc.full_major ();
  Gc.compact ();
  let before = (Gc.stat ()).minor_words in
  for _ = 1 to 10000 do
    let _ = f () in
    ()
  done;
  let after = (Gc.stat ()).minor_words in
  Printf.printf "%-50s %.1f words/call\n" label ((after -. before) /. 10000.)

let () =
  bench "Style.make (0 args)" (fun () -> ReactDOM.Style.make ());
  bench "Style.make (1 arg)" (fun () -> ReactDOM.Style.make ~color:"red" ());
  bench "Style.make (11 args, PropsHeavy-like)" (fun () ->
      ReactDOM.Style.make ~backgroundColor:"#fff" ~padding:"16px" ~margin:"8px" ~borderRadius:"8px"
        ~boxShadow:"0 2px 4px rgba(0,0,0,0.1)" ~transition:"all 0.3s ease" ~cursor:"pointer" ~userSelect:"none"
        ~overflow:"hidden" ~position:"relative" ~zIndex:"1" ())
