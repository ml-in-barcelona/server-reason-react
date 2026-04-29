`let%browser_only` only accepts function definitions or simple identifier
re-exports as the RHS. For other shapes (function applications, record
literals, complex expressions), the ppx emits a compile-time error
directing the user to use `switch%platform` or `[@platform js]` instead.

  $ cat > input.ml << EOF
  > let%browser_only an_apply = String.length "foo"
  > 
  > let%browser_only a_record = { foo = 1; bar = 2 }
  > 
  > let%browser_only a_constant = 42
  > 
  > let%browser_only an_apply_in_let_in =
  >   let inner = String.length "foo" in
  >   let%browser_only x = inner + 1 in
  >   x
  > EOF

With -js, these are all valid \u2014 the extension just disappears.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let an_apply = String.length "foo"
  let a_record = { foo = 1; bar = 2 }
  let a_constant = 42
  
  let an_apply_in_let_in =
    let inner = String.length "foo" in
    let x = inner + 1 in
    x

Without -js, each non-function/non-Pexp_ident binding is rejected with a
compile-time error pointing the user to `switch%platform` or `[@platform js]`.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (an_apply
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
    [%ocaml.error
      "[browser_ppx] browser_only only works on function definitions or simple \
       identifier re-exports. For other cases, use switch%platform or [@platform \
       js] to conditionally include the binding based on the platform."]
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let (a_record
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
    [%ocaml.error
      "[browser_ppx] browser_only only works on function definitions or simple \
       identifier re-exports. For other cases, use switch%platform or [@platform \
       js] to conditionally include the binding based on the platform."]
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let (a_constant
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
    [%ocaml.error
      "[browser_ppx] browser_only only works on function definitions or simple \
       identifier re-exports. For other cases, use switch%platform or [@platform \
       js] to conditionally include the binding based on the platform."]
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let (an_apply_in_let_in
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
    [%ocaml.error
      "[browser_ppx] browser_only only works on function definitions or simple \
       identifier re-exports. For other cases, use switch%platform or [@platform \
       js] to conditionally include the binding based on the platform."]
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
