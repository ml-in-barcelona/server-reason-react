exception Impossible_in_ssr of string
(** Exception to throw when operations aren't meant to be running on native, mostly used by browser_ppx or ReactDOM *)

val fail_impossible_action_in_ssr : string -> 'a
