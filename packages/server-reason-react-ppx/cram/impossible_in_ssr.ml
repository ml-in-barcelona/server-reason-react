let%melange_only focus (_ : int) = ()

let[@alert "-melange_only"] () =
  try focus 1 with Runtime.Impossible_in_ssr _ -> print_endline "caught Runtime.Impossible_in_ssr"
