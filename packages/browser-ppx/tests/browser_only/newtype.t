Newtype parameters (`fun (type a) -> ...`) are preserved on native. They
don't appear in the let-chain because they're type variables, not values.

  $ cat > input.ml << EOF
  > let%browser_only convert (type a) (x : a) (transform : a -> a) =
  >   transform x
  > EOF

With -js, the newtype is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let convert (type a) (x : a) (transform : a -> a) = transform x

Without -js, the newtype layer is preserved; only value args (`x`,
`transform`) appear in the let-chain.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (convert
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun (type a) (x : a) (transform : a -> a) ->
    let _ = x in
    let _ = transform in
    Runtime.fail_impossible_action_in_ssr "convert")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
