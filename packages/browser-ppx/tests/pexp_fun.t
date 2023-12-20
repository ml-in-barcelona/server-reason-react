  $ cat > input.ml << EOF
  > let%browser_only pexp_fun_1arg_structure_item evt =
  >   Webapi.Dom.getElementById "foo"
  >  
  > let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  >   Webapi.Dom.getElementById "foo"
  > 
  > let%browser_only perform ?abortController ?(base = defaultBase) (req : ('handler, 'a, 'i, 'o) Client.request) input =
  >   Js.log abortController;
  >   Js.log base;
  >   Js.log req;
  >   Js.log input
  > 
  > let make () =
  >   let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
  >     Webapi.Dom.getElementById "foo"
  >   in
  > 
  >   let%browser_only perform ?abortController ?(base = defaultBase) (req : ('handler, 'a, 'i, 'o) Client.request) input =
  >     Js.log abortController;
  >     Js.log base;
  >     Js.log req;
  >     Js.log input
  >   in
  > 
  >   let%browser_only fun_value_binding_labelled_args ~argument1 ~argument2 =
  >     setHtmlFetchState Loading
  >   in
  >   ()
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let pexp_fun_1arg_structure_item evt = Webapi.Dom.getElementById "foo"
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    Webapi.Dom.getElementById "foo"
  
  let perform ?abortController ?(base = defaultBase)
      (req : ('handler, 'a, 'i, 'o) Client.request) input =
    Js.log abortController;
    Js.log base;
    Js.log req;
    Js.log input
  
  let make () =
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Webapi.Dom.getElementById "foo"
    in
    let perform ?abortController ?(base = defaultBase)
        (req : ('handler, 'a, 'i, 'o) Client.request) input =
      Js.log abortController;
      Js.log base;
      Js.log req;
      Js.log input
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      setHtmlFetchState Loading
    in
    ()

Without -js flag, the compilation to native replaces the expression with a raise

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
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
  
  let (perform
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] ?abortController ?base req input ->
    let _ = abortController and _ = base and _ = input and _ = req in
    Runtime.fail_impossible_action_in_ssr "perform"
  [@@warning "-27-32"]
  
  let make () =
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
        [@@alert "-browser_only"]
    in
    let perform ?abortController ?base req input =
      let _ = abortController and _ = base and _ = input and _ = req in
      Runtime.fail_impossible_action_in_ssr "perform"
        [@@alert "-browser_only"]
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_labelled_args"
        [@@alert "-browser_only"]
    in
    ()

Replace Runtime.fail_impossible_action_in_ssr with print_endline so ocamlc can compile it without the Runtime module dependency
  $ sed "s/Runtime.fail_impossible_action_in_ssr/print_endline/g" output.ml > output.ml

  $ ocamlc -c output.ml
