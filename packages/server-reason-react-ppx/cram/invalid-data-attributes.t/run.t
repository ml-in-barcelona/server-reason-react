  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executables
  >  (names static dynamic optional_none optional_some valid)
  >  (flags (:standard -w -32))
  >  (libraries server-reason-react.react server-reason-react.reactDom)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/)))
  > EOF

  $ dune build static.exe
  File "static.re", line 1, characters 28-35:
  1 | let element = <div dataFoo'="value" />;
                                  ^^^^^^^
  Error: server-reason-react: dataFoo' renders as the invalid DOM attribute
         name "data-foo'"
  [1]

  $ dune build dynamic.exe
  File "dynamic.re", line 1, characters 34-39:
  1 | let make = value => <div dataFoo'=value />;
                                        ^^^^^
  Error: server-reason-react: dataFoo' renders as the invalid DOM attribute
         name "data-foo'"
  [1]

  $ dune build optional_none.exe
  File "optional_none.re", line 1, characters 29-33:
  1 | let element = <div dataFoo'=?None />;
                                   ^^^^
  Error: server-reason-react: dataFoo' renders as the invalid DOM attribute
         name "data-foo'"
  [1]

  $ dune build optional_some.exe
  File "optional_some.re", line 1, characters 29-44:
  1 | let element = <div dataFoo'=?{Some("value")} />;
                                   ^^^^^^^^^^^^^^^
  Error: server-reason-react: dataFoo' renders as the invalid DOM attribute
         name "data-foo'"
  [1]

  $ dune exec ./valid.exe
  <div data-label="it&apos;s fine" data-foo_bar="ok" data-version2="2"></div>
