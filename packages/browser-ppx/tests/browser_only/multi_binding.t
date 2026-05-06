Multiple bindings in a single let-rec via `and` are all transformed.

  $ cat > input.ml << EOF
  > let%browser_only rec is_even n = if n = 0 then true else is_odd (n - 1)
  > and is_odd n = if n = 0 then false else is_even (n - 1)
  > EOF

With -js, the recursive group is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let rec is_even n = if n = 0 then true else is_odd (n - 1)
  and is_odd n = if n = 0 then false else is_even (n - 1)

Without -js, both bindings are transformed.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let rec (is_even
           [@alert
             browser_only
               "This expression is marked to only run on the browser where \
                JavaScript can run. You can only use it inside a \
                let%browser_only function."]) =
   (fun n ->
    let _ = n in
    Runtime.fail_impossible_action_in_ssr "is_even")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  and (is_odd
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun n ->
    let _ = n in
    Runtime.fail_impossible_action_in_ssr "is_odd")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70-39 -c final.ml
