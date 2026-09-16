Single children keep their prop types. In these cases, the unannotated element
variable and the dynamic-list member have missing-key state 2. An explicit
React.element annotation or direct JSX preserves static state 1.

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
  unannotated variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  typed dynamic list:
  0:["$","div",null,{"children":[[["$","span",null,{"children":"Hello"},null,null,2]]]},null,null,1]
  HTML: <div><span>Hello</span></div>

  $ dune exec ./input.exe -- Prod
  unannotated variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  typed dynamic list:
  0:["$","div",null,{"children":[[["$","span",null,{"children":"Hello"},null,null,2]]]},null,null,1]
  HTML: <div><span>Hello</span></div>

  $ dune exec ./input.exe -- Dev
  unannotated variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,2]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  typed variable:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  direct JSX:
  0:["$","div",null,{"children":[["$","span",null,{"children":"Hello"},null,null,1]]},null,null,1]
  HTML: <div><span>Hello</span></div>
  string prop:
  0:["$","span",null,{"children":"Hello"},null,null,1]
  HTML: <span>Hello</span>
  typed dynamic list:
  0:["$","div",null,{"children":[[["$","span",null,{"children":"Hello"},null,null,2]]]},null,null,1]
  HTML: <div><span>Hello</span></div>
