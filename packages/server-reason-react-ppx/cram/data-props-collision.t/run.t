  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executables
  >  (names required_required required_optional acronym_alias underscore_alias)
  >  (libraries server-reason-react.react server-reason-react.reactDom)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/)))
  > EOF

  $ dune build 2>&1 | grep -v "^  *\^"
  File "acronym_alias.re", line 1, characters 39-42:
  1 | let element = <div dataURL="a" dataUrl="b" />;
  Error: server-reason-react: dataUrl and dataURL both render as the attribute
         data-url
  File "required_optional.re", line 1, characters 40-44:
  1 | let element = <div dataFoo="a" dataFoo=?None />;
  Error: server-reason-react: the prop dataFoo appears more than once on <div>
  File "required_required.re", line 1, characters 39-42:
  1 | let element = <div dataFoo="a" dataFoo="b" />;
  Error: server-reason-react: the prop dataFoo appears more than once on <div>
  File "underscore_alias.re", line 1, characters 48-52:
  1 | let element = <div dataFoo_bar="a" dataFoo_Bar=?None />;
  Error: server-reason-react: dataFoo_Bar and dataFoo_bar both render as the
         attribute data-foo_bar
