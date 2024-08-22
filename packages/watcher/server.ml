let () =
  (* Print a message to the console *)
  Printf.printf
    "This is a simple OCaml program. It will now enter an infinite loop with a \
     sleep interval.\n\
     %!";

  (* Infinite loop with a sleep interval *)
  while true do
    (* Sleep for 5 seconds to avoid high CPU usage *)
    Unix.sleep 5
  done
