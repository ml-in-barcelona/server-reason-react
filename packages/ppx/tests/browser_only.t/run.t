With -js flag everything keeps as it is and browser_only extension disappears

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
  let labeled ~argument1 ~argument2 = setHtmlFetchState Loading
  let getById id = Webapi.Dom.getElementById id
  
  let make () =
    let _ = Webapi.Dom.getElementById "foo" in
    let loadInitialText () = setHtmlFetchState Loading in
    let loadInitialText argument1 = setHtmlFetchState Loading in
    let loadInitialText argument1 argument2 = setHtmlFetchState Loading in
    let labeled ~argument1 ~argument2 = setHtmlFetchState Loading in
    React.createElement "div"

Without -js flag, the compilation to native replaces the expression with `raise (ReactDOM.Impossible_in_ssr`

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  let valueFromEvent = Webapi.Dom.getElementById "foo"
  
  let valueFromEvent evt =
    raise
      (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27-32"]
  
  let valueFromEvent evt moar_arguments =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27-32"]
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let valueFromEvent =
      [%ocaml.error "browser only works on expressions or function definitions"]
    in
    let valueFromEvent =
     fun [@warning "-27"] evt ->
      raise
        (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
       [@@warning "-27-26"]
    in
    let valueFromEvent =
     fun [@warning "-27"] evt ->
      fun [@warning "-27"] moar_arguments ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
       [@@warning "-27-26"]
    in
    React.createElement "div"
  
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  
  let loadInitialText () =
    raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let loadInitialText argument1 =
    raise
      (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let loadInitialText argument1 argument2 =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let labeled ~argument1 ~argument2 =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun ~argument1 -> fun ~argument2 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let getById =
   fun [@warning "-27"] id ->
    raise (ReactDOM.Impossible_in_ssr "fun id -> Webapi.Dom.getElementById id")
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let loadInitialText =
     fun [@warning "-27"] () ->
      raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let loadInitialText =
     fun [@warning "-27"] argument1 ->
      raise
        (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let loadInitialText =
     fun [@warning "-27"] argument1 ->
      fun [@warning "-27"] argument2 ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let labeled =
     fun [@warning "-27"] ~argument1 ->
      fun [@warning "-27"] ~argument2 ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun ~argument1 -> fun ~argument2 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    React.createElement "div"


  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  let valueFromEvent = Webapi.Dom.getElementById "foo"
  
  let valueFromEvent evt =
    raise
      (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27-32"]
  
  let valueFromEvent evt moar_arguments =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
  [@@warning "-27-32"]
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let valueFromEvent =
      [%ocaml.error "browser only works on expressions or function definitions"]
    in
    let valueFromEvent =
     fun [@warning "-27"] evt ->
      raise
        (ReactDOM.Impossible_in_ssr "fun evt -> Webapi.Dom.getElementById \"foo\"")
       [@@warning "-27-26"]
    in
    let valueFromEvent =
     fun [@warning "-27"] evt ->
      fun [@warning "-27"] moar_arguments ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun evt -> fun moar_arguments -> Webapi.Dom.getElementById \"foo\"")
       [@@warning "-27-26"]
    in
    React.createElement "div"
  
  let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById")
  
  let loadInitialText () =
    raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let loadInitialText argument1 =
    raise
      (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let loadInitialText argument1 argument2 =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let labeled ~argument1 ~argument2 =
    raise
      (ReactDOM.Impossible_in_ssr
         "fun ~argument1 -> fun ~argument2 -> setHtmlFetchState Loading")
  [@@warning "-27-32"]
  
  let getById =
   fun [@warning "-27"] id ->
    raise (ReactDOM.Impossible_in_ssr "fun id -> Webapi.Dom.getElementById id")
  
  let make () =
    let _ = raise (ReactDOM.Impossible_in_ssr "Webapi.Dom.getElementById") in
    let loadInitialText =
     fun [@warning "-27"] () ->
      raise (ReactDOM.Impossible_in_ssr "fun () -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let loadInitialText =
     fun [@warning "-27"] argument1 ->
      raise
        (ReactDOM.Impossible_in_ssr "fun argument1 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let loadInitialText =
     fun [@warning "-27"] argument1 ->
      fun [@warning "-27"] argument2 ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun argument1 -> fun argument2 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    let labeled =
     fun [@warning "-27"] ~argument1 ->
      fun [@warning "-27"] ~argument2 ->
       raise
         (ReactDOM.Impossible_in_ssr
            "fun ~argument1 -> fun ~argument2 -> setHtmlFetchState Loading")
       [@@warning "-27-26"]
    in
    React.createElement "div"
