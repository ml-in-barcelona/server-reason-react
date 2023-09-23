With -js flag everything keeps as it is

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let _ = Webapi.Dom.getElementById "foo"
  let valueFromEvent = Webapi.Dom.getElementById "foo"
  let valueFromEvent evt = Webapi.Dom.getElementById "foo"
  let valueFromEvent evt moar_arguments = Webapi.Dom.getElementById "foo"
  
  let make () =
    let _ = Webapi.Dom.getElementById "foo" in
    let valueFromEvent = Webapi.Dom.getElementById "foo" in
    let valueFromEvent evt = Webapi.Dom.getElementById "foo" in
    let valueFromEvent evt moar_arguments = Webapi.Dom.getElementById "foo" in
    React.createElement "div"
  
  let _ = Webapi.Dom.getElementById "foo"
  let loadInitialText () = setHtmlFetchState Loading
  let loadInitialText argument1 = setHtmlFetchState Loading
  let loadInitialText argument1 argument2 = setHtmlFetchState Loading
  
  let make () =
    let _ = Webapi.Dom.getElementById "foo" in
    let loadInitialText () = setHtmlFetchState Loading in
    let loadInitialText argument1 = setHtmlFetchState Loading in
    let loadInitialText argument1 argument2 = setHtmlFetchState Loading in
    React.createElement "div"
