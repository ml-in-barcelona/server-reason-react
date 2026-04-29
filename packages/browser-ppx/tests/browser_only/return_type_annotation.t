Return-type annotations and outer binding annotations are dropped on native.
The function becomes fully polymorphic via the raise. Cross-platform type
unification is enforced at call sites.

  $ cat > input.ml << EOF
  > let%browser_only get_count : string -> int = fun id ->
  >   String.length id
  > 
  > let%browser_only compute id : string =
  >   string_of_int id
  > EOF

With -js, all annotations are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let get_count : string -> int = fun id -> String.length id
  let compute id : string = string_of_int id

Without -js, the outer/return annotations are dropped (the body is a raise
of type 'a). The function args are still preserved.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (get_count
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun id ->
    let _ = id in
    Runtime.fail_impossible_action_in_ssr "get_count")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let (compute
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun id ->
    let _ = id in
    let _ = string_of_int in
    Runtime.fail_impossible_action_in_ssr "compute")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
