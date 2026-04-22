(* Compare output of a known style, expected vs actual *)
let () =
  let s =
    ReactDOM.Style.make ~backgroundColor:"#ffffff" ~padding:"16px" ~margin:"8px" ~borderRadius:"8px"
      ~boxShadow:"0 2px 4px rgba(0,0,0,0.1)" ~transition:"all 0.3s ease" ~cursor:"pointer" ~userSelect:"none"
      ~overflow:"hidden" ~position:"relative" ~zIndex:"1" ()
  in
  Printf.printf "HeavyDiv style:\n%s\n" (ReactDOM.Style.to_string s);
  let s2 = ReactDOM.Style.make ~padding:"16px 24px" ~whiteSpace:"nowrap" ~fontSize:"14px" () in
  Printf.printf "HeavyTable cell:\n%s\n" (ReactDOM.Style.to_string s2)
