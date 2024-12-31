Pexp_apply with Pexp_let without attribute

  $ cat > input_include.ml << EOF
  > let _ = foo ((let x = 42 in let y = 44 in y + x))
  > EOF

Running standalone.exe should not fail

  $ ./standalone.exe -impl input_include.ml
  let _ = foo (let x = 42 in let y = 44 in y + x)

Running ocamlformat should not fail

  $ ocamlformat input_include.ml --enable-outside-detected-project --impl
  let _ =
    foo
      (let x = 42 in
       let y = 44 in
       y + x)


Pexp_apply with Pexp_let with attribute

  $ cat > input_include.ml << EOF
  > let _ = foo ((let x = 42 in let y = 44 in y + x)[@bla])
  > EOF

Running standalone.exe should not fail

  $ ./standalone.exe -impl input_include.ml
  let _ = foo ((let x = 42 in let y = 44 in y + x)[@bla ])

Running ocamlformat should fail

  $ ocamlformat input_include.ml --enable-outside-detected-project --impl
  let baz =
    foo
      ((let x = 42 in
       let y = 44 in
       y + x)[@bla])
