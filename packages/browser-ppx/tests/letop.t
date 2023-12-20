  $ cat > input.ml << EOF
  > [%%browser_only let ( let+ ) = fun p f -> map f p]
  > EOF

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let ( let+ ) p f = map f p

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (( let+ )
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] p f ->
    let _ = f and _ = p in
    Runtime.fail_impossible_action_in_ssr "let+"
  [@@warning "-27-32"]
