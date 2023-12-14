  $ cat > input.re << EOF
  > let%browser_only getSortedWordCountsBrowserOnly =
  >                 (words: array(string)): array((string, int)) => {
  >   words
  >   ->Js.Array2.reduce(
  >       (acc, word) => {
  >         Map.String.update(acc, word, count =>
  >           switch (count) {
  >           | Some(existingCount) => Some(existingCount + 1)
  >           | None => Some(1)
  >           }
  >         )
  >       },
  >       Map.String.empty,
  >     )
  >   ->Map.String.toArray
  >   ->Js.Array2.sortInPlaceWith(((_, a), (_, b)) => b - a);
  > };
  > EOF

  $ refmt --print ml input.re > input.ml

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
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
  let (getSortedWordCountsBrowserOnly
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@alert "-browser_only"] words ->
    Runtime.fail_impossible_action_in_ssr "getSortedWordCountsBrowserOnly"
  [@@warning "-27-32"]
