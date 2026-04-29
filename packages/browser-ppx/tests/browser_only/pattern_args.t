Function arguments can be patterns (tuples, records, constructors). All
names bound by the pattern are extracted and referenced.

  $ cat > input.ml << EOF
  > type point = { x : int; y : int }
  > 
  > let%browser_only handle_click (px, py) { x; y } (Some inner) =
  >   ignore (px, py, x, y, inner)
  > EOF

With -js, the pattern arguments are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type point = { x : int; y : int }
  
  let handle_click (px, py) { x; y } (Some inner) = ignore (px, py, x, y, inner)

Without -js, all names bound inside the pattern arguments are referenced
in the let-chain.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  type point = { x : int; y : int }
  
  let (handle_click
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun (px, py) { x; y } (Some inner) ->
    let _ = px in
    let _ = py in
    let _ = x in
    let _ = y in
    let _ = inner in
    let _ = ignore in
    Runtime.fail_impossible_action_in_ssr "handle_click")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
  File "final.ml", line 16, characters 24-36:
  16 |  (fun (px, py) { x; y } (Some inner) ->
                               ^^^^^^^^^^^^
  Error (warning 8 [partial-match]): this pattern-matching is not exhaustive.
    Here is an example of a case that is not matched: None
  [2]
