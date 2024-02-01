  $ cat > input.ml << EOF
  > [%%browser_only let ( let+ ) = fun p f -> map f p]
  > 
  > let%browser_only pexp_ident = Webapi__Dom__Element.asHtmlElement
  > 
  > let%browser_only pexp_fun_1arg_structure_item evt =
  >   Webapi.Dom.getElementById "foo"
  >  
  > let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  >   let a = "foo" in
  >   Webapi.Dom.getElementById a
  > 
  > let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  >   let a = "foo" in
  >   let a = "foo" in
  >   Webapi.Dom.getElementById a
  > 
  > let%browser_only perform ?abortController ?(base = defaultBase) (req : ('handler, 'a, 'i, 'o) Client.request) input =
  >   Js.log abortController;
  >   Js.log base;
  >   Js.log req;
  >   Js.log input
  > 
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let ( let+ ) p f = map f p
  let pexp_ident = Webapi__Dom__Element.asHtmlElement
  let pexp_fun_1arg_structure_item evt = Webapi.Dom.getElementById "foo"
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    let a = "foo" in
    Webapi.Dom.getElementById a
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    let a = "foo" in
    let a = "foo" in
    Webapi.Dom.getElementById a
  
  let perform ?abortController ?(base = defaultBase)
      (req : ('handler, 'a, 'i, 'o) Client.request) input =
    Js.log abortController;
    Js.log base;
    Js.log req;
    Js.log input

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (( let+ )
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] p f ->
    Runtime.fail_impossible_action_in_ssr "let+"
  [@@warning "-27-32"]
  
  let (pexp_ident
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
    (Obj.magic () [@alert "-browser_only"])
  [@@warning "-27-32"]
  
  let (pexp_fun_1arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] evt ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_1arg_structure_item"
  [@@warning "-27-32"]
  
  let (pexp_fun_2arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] evt moar_arguments ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_2arg_structure_item"
  [@@warning "-27-32"]
  
  let (pexp_fun_2arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] evt moar_arguments ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_2arg_structure_item"
  [@@warning "-27-32"]
  
  let (perform
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] ?abortController ?base req input ->
    Runtime.fail_impossible_action_in_ssr "perform"
  [@@warning "-27-32"]

Replace Runtime.fail_impossible_action_in_ssr with print_endline so ocamlc can compile it without the Runtime module dependency
  $ echo "module Runtime = struct" >> output.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> output.ml
  $ echo "end" >> output.ml
  $ ocamlc -c output.ml
