Process [@@deriving jsConverter]

  $ cat > input.ml << EOF
  > type action =
  >   | Click
  >   | Submit [@mel.as 3]
  >   | Cancel
  > [@@deriving jsConverter]
  > 
  > let a = actionToJs Click
  > let b = actionToJs Submit
  > let c = a + b
  > let () = Js.log c
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type action = Click | Submit [@mel.as 3] | Cancel [@@deriving jsConverter]
  
  let a = actionToJs Click
  let b = actionToJs Submit
  let c = a + b
  let () = Js.log c

  $ ocamlc -c output.ml
  File "output.ml", line 3, characters 8-18:
  3 | let a = actionToJs Click
              ^^^^^^^^^^
  Error: Unbound value actionToJs
  [2]

