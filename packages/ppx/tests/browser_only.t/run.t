Without -js flag, the compilation to native replaces the expression with `raise (ReactDOM.Impossible_in_ssr`

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  let valueFromEvent = Webapi.Dom.getElementById "foo"
  
  let valueFromEvent evt =
    raise
      (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27"]
  
  let valueFromEvent evt moar_arguments =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27"]
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let valueFromEvent =
      [%ocaml.error "browser only works on expressions or function definitions"]
    in
    let valueFromEvent evt =
      raise
        (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
        [@@warning "-27"]
    in
    let valueFromEvent evt moar_arguments =
      raise
        (ReactDOM.Impossible_in_ssr
           "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
        [@@warning "-27"]
    in
    React.createElement "div"
  
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  
  let loadInitialText () =
    raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
  [@@warning "-27"]
  
  let loadInitialText argument1 =
    raise
      (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
  [@@warning "-27"]
  
  let loadInitialText argument1 argument2 =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
  [@@warning "-27"]
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let loadInitialText () =
      raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
        [@@warning "-27"]
    in
    let loadInitialText argument1 =
      raise
        (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
        [@@warning "-27"]
    in
    let loadInitialText argument1 argument2 =
      raise
        (ReactDOM.Impossible_in_ssr
           "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
        [@@warning "-27"]
    in
    React.createElement "div"

$ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
