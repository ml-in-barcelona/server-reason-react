Labelled (~name), optional without default (?name), and optional with
default (?(name = expr)) arguments are all preserved with their full
metadata. Default expressions are kept verbatim.

  $ cat > input.ml << EOF
  > let%browser_only perform ?abortController ?(base = "/api") ~method_ url payload =
  >   Js.log abortController;
  >   Js.log base;
  >   Js.log method_;
  >   Js.log url;
  >   Js.log payload
  > EOF

With -js, all argument forms are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let perform ?abortController ?(base = "/api") ~method_ url payload =
    Js.log abortController;
    Js.log base;
    Js.log method_;
    Js.log url;
    Js.log payload

Without -js, all argument forms (including labels and defaults) are kept.
Each argument is referenced by the let-chain.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (perform
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun ?abortController ?(base = "/api") ~method_ url payload ->
    let _ = abortController in
    let _ = base in
    let _ = method_ in
    let _ = url in
    let _ = payload in
    Runtime.fail_impossible_action_in_ssr "perform")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
