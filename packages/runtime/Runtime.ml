exception Impossible_in_ssr = Ppx_platform_runtime.Impossible_in_ssr

let fail_impossible_action_in_ssr = Ppx_platform_runtime.fail_impossible_action_in_ssr

type platform = Server | Client

(* QUESTION: Can we create a lint ensuring that the callback function is uncurried? *)
type 'callback server_function = { id : string; call : 'callback }
