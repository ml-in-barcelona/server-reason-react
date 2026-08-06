  $ server-reason-react.router-gen --mode handles --source input.ml < input.ml > Router.ml
  $ server-reason-react.router-gen --mode interface --source input.ml < input.ml > Router.mli
  $ ocamlc -c RouterRuntime.ml
  $ ocamlc -c React.ml
  $ ocamlc -c RouterReact.ml
  $ ocamlc -c NoteId.ml
  $ ocamlc -c Router.mli
  $ ocamlc -c Router.ml
  $ ocamlc -c bad.ml
  File "bad.ml", line 1, characters 17-36:
  1 | let _ : string = Router.Note.href ()
                       ^^^^^^^^^^^^^^^^^^^
  Error: This expression has type id:NoteId.t -> string
         but an expression was expected of type string
  Hint: This function application is partial, maybe some arguments are missing.
  [2]

  $ server-reason-react.router-gen --mode handles --source unknown-argument.ml < unknown-argument.ml
  Fatal error: exception router: unknown router argument ~laoyut
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-manifest.ml < duplicate-manifest.ml
  Fatal error: exception router: expected exactly one Router.make declaration
  [2]
