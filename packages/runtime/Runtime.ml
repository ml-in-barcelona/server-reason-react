exception Impossible_in_ssr = Ppx_platform.Melange_only

let fail_impossible_action_in_ssr = Ppx_platform.fail_melange_only

(* QUESTION: Can we create a lint ensuring that the callback function is uncurried? *)
type 'callback server_function = { id : string; call : 'callback }
