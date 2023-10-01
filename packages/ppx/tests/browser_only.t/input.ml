let _ = [%browser_only Webapi.Dom.getElementById "foo"]
let%browser_only valueFromEvent = Webapi.Dom.getElementById "foo"
let%browser_only valueFromEvent evt = Webapi.Dom.getElementById "foo"

let%browser_only valueFromEvent evt moar_arguments =
  Webapi.Dom.getElementById "foo"

let make () =
  let _ = [%browser_only Webapi.Dom.getElementById "foo"] in
  let%browser_only valueFromEvent = Webapi.Dom.getElementById "foo" in
  let%browser_only valueFromEvent evt = Webapi.Dom.getElementById "foo" in

  let%browser_only valueFromEvent evt moar_arguments =
    Webapi.Dom.getElementById "foo"
  in

  React.createElement "div"

let _ = [%browser_only Webapi.Dom.getElementById "foo"]
let%browser_only loadInitialText () = setHtmlFetchState Loading
let%browser_only loadInitialText argument1 = setHtmlFetchState Loading
let%browser_only loadInitialText argument1 argument2 = setHtmlFetchState Loading
let%browser_only labeled ~argument1 ~argument2 = setHtmlFetchState Loading

let make () =
  let _ = [%browser_only Webapi.Dom.getElementById "foo"] in

  let%browser_only loadInitialText () = setHtmlFetchState Loading in

  let%browser_only loadInitialText argument1 = setHtmlFetchState Loading in

  let%browser_only loadInitialText argument1 argument2 =
    setHtmlFetchState Loading
  in

  React.createElement "div"
