A let%melange_only function called on native raises the exception that Runtime re-exports

  $ OCAMLRUNPARAM= ./impossible_in_ssr.exe | grep caught
  caught Runtime.Impossible_in_ssr
