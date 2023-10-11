%mel.raw
  $ cat > input.ml <<EOF
  > let asHtmlElement = [%mel.raw {| function(element) { console.log(element } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let asHtmlElement = ()

  $ ocamlc output.ml
