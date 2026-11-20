(** A small utility to raise issues with SSR

    Mostly used internally by the ppxes *)

exception Impossible_in_ssr of string
(** Exception to throw when operations aren't meant to be running on native, mostly used by ppx_platform or ReactDOM.
    Re-exported from [ppx_platform], so handlers on either name catch the same exception. *)

val fail_impossible_action_in_ssr : string -> 'a

type 'callback server_function = { id : string; call : 'callback }
(** A server function.

    - [id]: the server function ID. Only the server uses it. On the client it is [""].
    - [call]: the function to call.

    Write the callback type inline as an arrow type that returns [Js.Promise.t].

    E.g. [Runtime.server_function((~name: string, ~age: int) => Js.Promise.t(string))] *)
