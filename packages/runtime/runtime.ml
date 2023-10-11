exception Impossible_in_ssr of string

let fail_impossible_action_in_ssr fn =
  let backtrace = Printexc.get_callstack 8 in
  let raw_callstack = Printexc.raw_backtrace_to_string backtrace in
  let () =
    Printf.printf
      {|
The function '%s' should only run on the client. Make sure you aren't accidentally calling this function in a server-side context.

Here's the raw callstack:

%s
|}
      fn raw_callstack
  in
  raise
    (Impossible_in_ssr
       (Printf.sprintf {|The function '%s' shouldn't run on the server|} fn))
