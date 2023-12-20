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

Replace Runtime.fail_impossible_action_in_ssr with print_endline so ocamlc can compile it without the Runtime module dependency
  $ echo "module Runtime = struct" >> output.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> output.ml
  $ echo "end" >> output.ml
  $ ocamlc -c output.ml
