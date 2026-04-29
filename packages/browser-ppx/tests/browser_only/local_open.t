Local opens (`let open M in body`) inside the function body are re-emitted
around the generated let-chain, preserving any module scope they brought
into the body.

  $ cat > input.ml << EOF
  > module Helpers = struct
  >   let utility = 42
  > end
  > 
  > let%browser_only with_helpers arg =
  >   let open Helpers in
  >   ignore (utility, arg)
  > EOF

With -js, the local open is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  module Helpers = struct
    let utility = 42
  end
  
  let with_helpers arg =
    let open Helpers in
    ignore (utility, arg)

Without -js, the local open is re-emitted around the let-chain. The body's
free idents are not collected, so `utility` is not referenced.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  module Helpers = struct
    let utility = 42
  end
  
  let (with_helpers
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun arg ->
    let open Helpers in
    let _ = arg in
    Runtime.fail_impossible_action_in_ssr "with_helpers")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
