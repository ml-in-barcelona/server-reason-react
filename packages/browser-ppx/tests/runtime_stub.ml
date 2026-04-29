(* Stub for the Runtime module used by the browser_ppx-generated code.
   Each cram test concatenates this with the ppx output before compiling
   with `ocamlc -w @a-70 -c` to verify that no warnings fire. *)

module Runtime = struct
  let fail_impossible_action_in_ssr : string -> 'a = fun _ -> failwith ""
end
