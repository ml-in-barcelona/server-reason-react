Argument types that can never be sent from the client are compile errors that
name the problem. A named type without a JSON deriver is reported at the type.

  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (library
  >  (name cases)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom server-reason-react.js melange-json-native server-reason-react.rsc-native lwt)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx server-reason-react.rsc-native.ppx melange-json-native.ppx)))
  > EOF

  $ cat > FunctionReferences.re << EOF
  > let register = (_id: string, _handler: ReactServerDOM.server_function) => ();
  > EOF

  $ cat > FunctionArg.re << EOF
  > [@react.server.function]
  > let run = (callback: int => int): Js.Promise.t(int) =>
  >   Lwt.return(callback(1));
  > EOF

  $ cat > NestedOption.re << EOF
  > [@react.server.function]
  > let run = (value: option(option(int))): Js.Promise.t(int) => {
  >   let _ = value;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > DateArg.re << EOF
  > [@react.server.function]
  > let run = (~at: Js.Date.t): Js.Promise.t(int) => {
  >   let _ = at;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > TypeVariable.re << EOF
  > [@react.server.function]
  > let run = (value: list('a)): Js.Promise.t(int) => {
  >   let _ = value;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > NestedFormData.re << EOF
  > [@react.server.function]
  > let run = (forms: list(Js.FormData.t)): Js.Promise.t(int) => {
  >   let _ = forms;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > MissingDeriver.re << EOF
  > type user = {name: string};
  > 
  > [@react.server.function]
  > let run = (~user: user): Js.Promise.t(string) => Lwt.return(user.name);
  > EOF

  $ cat > UnitOption.re << EOF
  > [@react.server.function]
  > let run = (value: option(unit)): Js.Promise.t(int) => {
  >   let _ = value;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > JsonOption.re << EOF
  > [@react.server.function]
  > let run = (raw: option(Js.Json.t)): Js.Promise.t(int) => {
  >   let _ = raw;
  >   Lwt.return(1);
  > };
  > EOF

  $ cat > Duplicate.re << EOF
  > [@react.server.function]
  > let save = (): Js.Promise.t(string) => Lwt.return("first");
  > 
  > [@react.server.function]
  > let save = (): Js.Promise.t(string) => Lwt.return("second");
  > EOF

  $ dune build -j 1
  File "DateArg.re", line 2, characters 16-25:
  2 | let run = (~at: Js.Date.t): Js.Promise.t(int) => {
                      ^^^^^^^^^
  Error: server-reason-react: server function arguments can't be Js.Date.t.
         Send a float (Js.Date.getTime) or a string instead.
  File "Duplicate.re", lines 4-5, characters 0-59:
  4 | [@react.server.function]
  5 | let save = (): Js.Promise.t(string) => Lwt.return("second").
  Error: server-reason-react: duplicate server function id "Duplicate#save".
         Two server functions in the same module have the same name; rename one
         of them.
  File "FunctionArg.re", line 2, characters 21-31:
  2 | let run = (callback: int => int): Js.Promise.t(int) =>
                           ^^^^^^^^^^
  Error: server-reason-react: server function arguments can't be functions.
         Only data that has a JSON encoding can be sent from the client.
  File "JsonOption.re", line 2, characters 16-33:
  2 | let run = (raw: option(Js.Json.t)): Js.Promise.t(int) => {
                      ^^^^^^^^^^^^^^^^^
  Error: server-reason-react: server function arguments can't be option(unit)
         or option(Js.Json.t): None and Some(_) have the same JSON encoding
         (null). Use a variant instead.
  File "MissingDeriver.re", line 4, characters 18-22:
  4 | let run = (~user: user): Js.Promise.t(string) => Lwt.return(user.name);
                        ^^^^
  Error: Unbound value user_of_json
  File "NestedFormData.re", line 2, characters 23-36:
  2 | let run = (forms: list(Js.FormData.t)): Js.Promise.t(int) => {
                             ^^^^^^^^^^^^^
  Error: server-reason-react: Js.FormData.t can only be a direct argument of a
         server function, not inside another type.
  File "NestedOption.re", line 2, characters 18-37:
  2 | let run = (value: option(option(int))): Js.Promise.t(int) => {
                        ^^^^^^^^^^^^^^^^^^^
  Error: server-reason-react: server function arguments can't be nested
         options: None and Some(None) have the same JSON encoding. Use a
         variant instead.
  File "TypeVariable.re", line 2, characters 23-25:
  2 | let run = (value: list('a)): Js.Promise.t(int) => {
                             ^^
  Error: server-reason-react: server function arguments need a concrete type,
         not a type variable.
  File "UnitOption.re", line 2, characters 18-30:
  2 | let run = (value: option(unit)): Js.Promise.t(int) => {
                        ^^^^^^^^^^^^
  Error: server-reason-react: server function arguments can't be option(unit)
         or option(Js.Json.t): None and Some(_) have the same JSON encoding
         (null). Use a variant instead.
  [1]
