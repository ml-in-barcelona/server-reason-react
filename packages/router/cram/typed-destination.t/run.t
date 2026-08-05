  $ refmt --parse re --print ml input.re | server-reason-react.router-gen --mode handles --source input.re > Router.ml
  $ refmt --parse re --print ml input.re | server-reason-react.router-gen --mode interface --source input.re > Router.mli
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

  $ refmt --parse re --print ml unknown-argument.re | server-reason-react.router-gen --mode handles --source unknown-argument.re
  Fatal error: exception router: unknown router argument ~laoyut
  [2]

  $ refmt --parse re --print ml duplicate-manifest.re | server-reason-react.router-gen --mode handles --source duplicate-manifest.re
  Fatal error: exception router: expected exactly one Router.make declaration
  [2]
