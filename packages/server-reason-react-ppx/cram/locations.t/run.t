Test some locations

  $ cat > test.opam << EOF
  > EOF

  $ cat > dune-project << EOF
  > (lang dune 3.8)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (library
  >  (libraries server-reason-react.react server-reason-react.reactDom)
  >  (public_name test)
  >  (preprocess
  >   (pps server-reason-react.melange.ppx server-reason-react.ppx)))
  > EOF

  $ dune build

let make = (~lola) => {
______________^

  $ ocamlmerlin single type-enclosing -position 4:5 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "(~key: 'a=?, ~lola: string, unit) => React.element"

let make = (~lola) => {
______________^

  $ ocamlmerlin single type-enclosing -position 4:14 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "string"

module Uppercase = {
[@react.component]
let make = (~children as upperCaseChildren) => {
_____^

  $ ocamlmerlin single type-enclosing -position 19:8 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "(~key: 'a=?, ~children: React.element, unit) => React.element"

<button onClick={_ => setValue(value => value + 1)}>
___^

  $ ocamlmerlin single type-enclosing -position 12:4 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "list(option(React.JSX.prop))"

<button onClick={_ => setValue(value => value + 1)}>
__________^

  $ ocamlmerlin single type-enclosing -position 12:15 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "list(option(React.JSX.prop))"

let a = <Uppercase> <div /> </Uppercase>;
________^

  $ ocamlmerlin single type-enclosing -position 24:8 -verbosity 0 \
  > -filename input.re < input.re | jq '.value[0].type'
  "('a, 'a) => bool"
