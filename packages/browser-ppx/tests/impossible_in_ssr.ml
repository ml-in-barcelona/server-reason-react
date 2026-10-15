let%browser_only focus (_ : int) = ()

(* The ppx raises Ppx_platform_runtime.Impossible_in_ssr; handlers on Runtime's alias must still catch it. *)
let[@alert "-browser_only"] () =
  try focus 1 with Runtime.Impossible_in_ssr _ -> print_endline "caught Runtime.Impossible_in_ssr"
