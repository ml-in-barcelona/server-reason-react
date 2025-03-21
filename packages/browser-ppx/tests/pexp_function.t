  $ cat > input.re << EOF
  > let%browser_only foo = fun
  >     | x when x < 0. => None
  >     | x => Some("bar");
  > 
  > let make = () => {
  >   let%browser_only foo = fun
  >     | x when x < 0. => None
  >     | x => Some("bar");
  >   ();
  > };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let foo = function x when x < 0. -> None | x -> Some "bar" [@explicit_arity]
  
  let make () =
    let foo = function
      | x when x < 0. -> None
      | x -> Some "bar" [@explicit_arity]
    in
    ()

Without -js flag, the compilation to native errors out indicating that a function must be used

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (foo
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] _ -> Runtime.fail_impossible_action_in_ssr "foo"
  [@@warning "-27-32"]
  
  let make () =
    let foo =
      [%ocaml.error
        "[browser_ppx] browser_only works on function definitions. For other \
         cases, use switch%platform or feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]
    in
    ()
