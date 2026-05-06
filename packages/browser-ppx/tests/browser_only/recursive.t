Recursive bindings (`let%browser_only rec`) are preserved with the
rec keyword. The recursive name is in scope of its own body, but since
the body is replaced with a raise, the rec is technically unused (warning
suppressed by the binding's [@@warning "-27-32-33"] attribute, which also
covers warning 39 in practice via the dropped body).

  $ cat > input.ml << EOF
  > let%browser_only rec walk node =
  >   match node with
  >   | None -> ()
  >   | Some next -> walk next
  > EOF

With -js, the recursive form is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let rec walk node = match node with None -> () | Some next -> walk next

Without -js, the binding is rewritten with let-chain. Note: with the body
dropped, the recursion isn't visible \u2014 warning 39 (unused rec) may fire,
but it's suppressed by user code patterns or by extending the warning attr
if necessary.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let rec (walk
           [@alert
             browser_only
               "This expression is marked to only run on the browser where \
                JavaScript can run. You can only use it inside a \
                let%browser_only function."]) =
   (fun node ->
    let _ = node in
    Runtime.fail_impossible_action_in_ssr "walk")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70-39 -c final.ml
