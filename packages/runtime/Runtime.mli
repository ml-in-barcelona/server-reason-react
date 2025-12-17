(** A small utility to raise issues with SSR

    Mostly used internally by the ppxes *)

exception Impossible_in_ssr of string
(** Exception to throw when operations aren't meant to be running on native, mostly used by browser_ppx or ReactDOM *)

val fail_impossible_action_in_ssr : string -> 'a

type platform =
  | Server
  | Client
      (** `Runtime.platform` is required to use switch%platform. It's a simple variant that expresses the 2 platforms *)

type 'callback server_function = { id : string; call : 'callback }
(** Type for server actions contract.

    The 'callback function must to be uncurried as we don't know the amount of arguments.

    - [id]: Server Function ID, this will be used on server only
    - [call]: The Server function implementation

    E.g. React.server_function(. ~name: string, ~age: int) => Js.Promise.t(string) *)
