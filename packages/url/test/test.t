  $ cat > dune-project << EOF
  > (lang dune 3.8)
  > (using melange 0.1)
  > EOF

  $ cat > dune <<EOF
  > (melange.emit
  >  (target output)
  >  (alias js)
  >  (emit_stdlib false)
  >  (preprocess (pps melange.ppx)))
  > EOF

  $ cat > main.ml <<EOF
  > let unsafeDeleteKey = [%raw "2"]
  > EOF

  $ dune build @mel
