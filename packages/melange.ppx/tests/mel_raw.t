mel.raw as a value

  $ cat > input.ml << EOF
  > let javi_es_un_crack = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  include (
    struct
      let javi_es_un_crack =
        raise (Failure "called Melange external \"mel.\" from native")
    end :
      sig
        val javi_es_un_crack : 'a [@@alert unimplemented "ojo aqui"]
      end)

  $ ocamlc output.ml

mel.raw with type

$ cat > input.ml << EOF
> type t
> let global: t = [%mel.raw "window"]
> EOF

$ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml

$ ocamlc output.ml
