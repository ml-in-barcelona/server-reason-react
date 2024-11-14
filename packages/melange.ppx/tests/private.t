let%private attribute
  $ cat > input.ml << EOF
  > [%%private let privi = 22]
  > let print () = Js.log privi
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  open! struct
    let privi = 22
  end
  
  let print () = Js.log privi

  $ cat > input.ml << EOF
  > [%%private module Lol = struct let x = 22 end]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  File "input.ml", line 1, characters 11-45:
  1 | [%%private module Lol = struct let x = 22 end]
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: the structure is not supported in local extension
