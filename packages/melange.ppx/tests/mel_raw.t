mel.raw as a value

  $ cat > input.ml << EOF
  > let javi_es_un_crack = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml

  $ ocamlc output.ml
