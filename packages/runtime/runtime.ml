exception Impossible_in_ssr of string

let fail_impossible_action_in_ssr fn =
  raise
    (Impossible_in_ssr
       (Printf.sprintf
          "'%s' shouldn't run on the server. Make sure to use it only in the \
           client. "
          fn))
