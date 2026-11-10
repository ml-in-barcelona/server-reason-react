  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executables
  >  (names repeated_id repeated_aria punned_optional required_required required_optional acronym_alias underscore_alias object_data class_name)
  >  (flags (:standard -w -32))
  >  (libraries server-reason-react.react server-reason-react.reactDom)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/)))
  > EOF

  $ dune build 2>&1 | grep -v "^  *\^"
  File "acronym_alias.re", line 1, characters 39-42:
  1 | let element = <div dataURL="a" dataUrl="b" />;
  Error: server-reason-react: dataUrl and dataURL both render as the attribute
         data-url
  File "punned_optional.re", line 1, characters 47-50:
  1 | let make = (id: option(string)) => <div ?id id="b" />;
  Error: server-reason-react: the prop id appears more than once on <div>
  File "repeated_aria.re", line 1, characters 43-46:
  1 | let element = <div ariaLabel="a" ariaLabel="b" />;
  Error: server-reason-react: the prop ariaLabel appears more than once on
         <div>
  File "repeated_id.re", line 1, characters 29-32:
  1 | let element = <div id="a" id="b" />;
  Error: server-reason-react: the prop id appears more than once on <div>
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

  $ dune build ./object_data.exe ./class_name.exe
