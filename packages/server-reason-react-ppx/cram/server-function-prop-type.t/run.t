  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (library
  >  (name input)
  >  (modes melange)
  >  (libraries server-reason-react.runtime reason-react server-reason-react.rsc)
  >  (preprocess (pps melange.ppx server-reason-react.rsc.ppx)))
  > EOF

  $ cat > Alias.re << EOF
  > type callback = unit => Js.Promise.t(string);
  > let decode = rsc => [%of_rsc: Runtime.server_function(callback)](rsc);
  > EOF

  $ cat > Variable.re << EOF
  > let decode = rsc => [%of_rsc: Runtime.server_function('callback)](rsc);
  > EOF

  $ cat > NoArrow.re << EOF
  > let decode = rsc => [%of_rsc: Runtime.server_function(Js.Promise.t(string))](rsc);
  > EOF

  $ cat > NotPromise.re << EOF
  > let decode = rsc => [%of_rsc: Runtime.server_function(unit => string)](rsc);
  > EOF

  $ dune build
  File "Alias.re", line 2, characters 54-62:
  2 | let decode = rsc => [%of_rsc: Runtime.server_function(callback)](rsc);
                                                            ^^^^^^^^
  Error: server-reason-react: the callback type of Runtime.server_function must
         be written inline as an arrow type returning Js.Promise.t, for example
         Runtime.server_function(unit => Js.Promise.t(string))
  File "NoArrow.re", line 1, characters 54-74:
  1 | let decode = rsc => [%of_rsc: Runtime.server_function(Js.Promise.t(string))](rsc);
                                                            ^^^^^^^^^^^^^^^^^^^^
  Error: server-reason-react: the callback type of Runtime.server_function must
         be written inline as an arrow type returning Js.Promise.t, for example
         Runtime.server_function(unit => Js.Promise.t(string))
  File "NotPromise.re", line 1, characters 54-68:
  1 | let decode = rsc => [%of_rsc: Runtime.server_function(unit => string)](rsc);
                                                            ^^^^^^^^^^^^^^
  Error: server-reason-react: the callback type of Runtime.server_function must
         be written inline as an arrow type returning Js.Promise.t, for example
         Runtime.server_function(unit => Js.Promise.t(string))
  File "Variable.re", line 1, characters 54-63:
  1 | let decode = rsc => [%of_rsc: Runtime.server_function('callback)](rsc);
                                                            ^^^^^^^^^
  Error: server-reason-react: the callback type of Runtime.server_function must
         be written inline as an arrow type returning Js.Promise.t, for example
         Runtime.server_function(unit => Js.Promise.t(string))
  [1]
