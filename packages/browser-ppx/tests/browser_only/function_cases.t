The `function | A -> ... | B x -> ...` form is rewritten as a function
taking a wildcard arg, dropping the cases entirely. Works at both
structure-item and let-in positions.

  $ cat > input.ml << EOF
  > let%browser_only classify = function
  >   | "yes" -> true
  >   | "no" -> false
  >   | other -> failwith other
  > 
  > let make () =
  >   let%browser_only handle = function
  >     | x when x < 0. -> None
  >     | x -> Some "bar"
  >   in
  >   ()
  > EOF

With -js, the function-cases form is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let classify = function
    | "yes" -> true
    | "no" -> false
    | other -> failwith other
  
  let make () =
    let handle = function x when x < 0. -> None | x -> Some "bar" in
    ()

Without -js, the cases are dropped and a `fun _ -> raise` is synthesized,
both at the structure-item position (`classify`) and inside the let-in (`handle`).

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (classify
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun _ ->
    let _ = failwith in
    Runtime.fail_impossible_action_in_ssr "classify")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let make () =
    let handle _ =
      Runtime.fail_impossible_action_in_ssr "handle"
        [@@alert "-browser_only"] [@@warning "-26-27-32-33"]
    in
    ()

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
