let%melange_only focus (_ : int) = ()

(* The ppx raises Ppx_platform.Melange_only; handlers on Runtime's alias must still catch it. *)
let[@alert "-melange_only"] () =
  try focus 1 with Runtime.Impossible_in_ssr _ -> print_endline "caught Runtime.Impossible_in_ssr"
