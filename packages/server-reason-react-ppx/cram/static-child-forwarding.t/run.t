A forwarded single child takes the validation state of the slot it lands in. A
host child list gives state 1, a runtime list gives state 2, whatever the type
annotation on the component. Literal siblings under a component form a
React.Static_children group and keep state 1. Custom child types still compile.

  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom lwt.unix)
  >  (preprocess (pps server-reason-react.ppx)))
  > EOF

  $ dune exec ./input.exe -- default
  host slot:
  0:["$","div",null,{"children":["$","span",null,{"children":"Hello"},null,null,1]},null,null,1]
  HTML: <div><span>Hello</span></div>
  two literal children:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1],["$","span",null,{"children":"World"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span><span>World</span></div>
  unannotated variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  dynamic list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>

  $ dune exec ./input.exe -- Prod
  host slot:
  0:["$","div",null,{"children":["$","span",null,{"children":"Hello"},null,null,1]},null,null,1]
  HTML: <div><span>Hello</span></div>
  two literal children:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1],["$","span",null,{"children":"World"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span><span>World</span></div>
  unannotated variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  dynamic list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>

  $ dune exec ./input.exe -- Dev
  host slot:
  0:["$","div",null,{"children":["$","span",null,{"children":"Hello"},null,null,1]},null,null,1]
  HTML: <div><span>Hello</span></div>
  two literal children:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1],["$","span",null,{"children":"World"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span><span>World</span></div>
  unannotated variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX in a list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  dynamic list:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
