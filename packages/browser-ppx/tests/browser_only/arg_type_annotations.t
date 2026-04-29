Argument-level type annotations like `(x : int)` are preserved on native
because they're part of the function's public signature.

  $ cat > input.ml << EOF
  > type my_event
  > 
  > let%browser_only typed_handler (event : my_event) (callback : unit -> string) =
  >   ignore (event, callback)
  > EOF

With -js, type annotations are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  type my_event
  
  let typed_handler (event : my_event) (callback : unit -> string) =
    ignore (event, callback)

Without -js, argument annotations are still kept.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  type my_event
  
  let (typed_handler
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun (event : my_event) (callback : unit -> string) ->
    let _ = event in
    let _ = callback in
    let _ = ignore in
    Runtime.fail_impossible_action_in_ssr "typed_handler")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
