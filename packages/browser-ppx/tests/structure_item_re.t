  $ cat > input.re << EOF
  > let%browser_only valueFromEvent = evt => React.Event.Form.target(evt)##value;
  > let%browser_only getSortedWordCountsBrowserOnly = (words: array(string)): array((string, int)) => {
  >   words->List.map->Js.log;
  > };
  > 
  > let%browser_only renderToElementWithId = (~id="", component) => {
  >   switch (ReactDOM.querySelector("#" ++ id)) {
  >     | Some(node) =>
  >       let root = ReactDOM.Client.createRoot(node);
  >       ReactDOM.Client.render(root, component);
  >     | None => Js.Console.error("RR.renderToElementWithId : no element of id '" ++ id ++ "' found in the HTML.")
  >     };
  >   };
  > 
  > let%browser_only getSortedWordCountsBrowserOnly = (words: array(string)): array((string, int)) => {
  >   words |> Js.log |> List.map;
  > };
  > 
  > let%browser_only getSortedWordCountsBrowserOnly = (words: array(string)): array((string, int)) => {
  >   words
  >   ->Js.Array2.reduce(
  >     (acc, word) => {
  >       Map.String.update(acc, word, count =>
  >         switch (count) {
  >         | Some(existingCount) => Some(existingCount + 1)
  >         | None => Some(1)
  >         }
  >       )
  >     },
  >     Map.String.empty
  >   )
  >   ->Map.String.toArray
  >   ->Js.Array2.sortInPlaceWith(((_, a), (_, b)) => b - a);
  > };
  > 
  > EOF

  $ refmt --print ml input.re > input.ml

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let valueFromEvent evt = (React.Event.Form.target evt)##value
  
  let getSortedWordCountsBrowserOnly (words : string array) : (string * int) array
      =
    words |. List.map |. Js.log
  
  let renderToElementWithId ?(id = "") component =
    match ReactDOM.querySelector ("#" ^ id) with
    | ((Some node) [@explicit_arity]) ->
        let root = ReactDOM.Client.createRoot node in
        ReactDOM.Client.render root component
    | None ->
        Js.Console.error
          ("RR.renderToElementWithId : no element of id '" ^ id
         ^ "' found in the HTML.")
  
  let getSortedWordCountsBrowserOnly (words : string array) : (string * int) array
      =
    words |> Js.log |> List.map
  
  let getSortedWordCountsBrowserOnly (words : string array) : (string * int) array
      =
    ((words |. Js.Array2.reduce)
       (fun acc word ->
         Map.String.update acc word (fun count ->
             match count with
             | ((Some existingCount) [@explicit_arity]) ->
                 Some (existingCount + 1) [@explicit_arity]
             | None -> Some 1 [@explicit_arity]))
       Map.String.empty
    |. Map.String.toArray |. Js.Array2.sortInPlaceWith) (fun (_, a) (_, b) ->
        b - a)

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (valueFromEvent
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] evt ->
    Runtime.fail_impossible_action_in_ssr "valueFromEvent"
  [@@warning "-27-32"]
  
  let (getSortedWordCountsBrowserOnly
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] words ->
    Runtime.fail_impossible_action_in_ssr "getSortedWordCountsBrowserOnly"
  [@@warning "-27-32"]
  
  let (renderToElementWithId
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] ?id component ->
    Runtime.fail_impossible_action_in_ssr "renderToElementWithId"
  [@@warning "-27-32"]
  
  let (getSortedWordCountsBrowserOnly
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] words ->
    Runtime.fail_impossible_action_in_ssr "getSortedWordCountsBrowserOnly"
  [@@warning "-27-32"]
  
  let (getSortedWordCountsBrowserOnly
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] words ->
    Runtime.fail_impossible_action_in_ssr "getSortedWordCountsBrowserOnly"
  [@@warning "-27-32"]
