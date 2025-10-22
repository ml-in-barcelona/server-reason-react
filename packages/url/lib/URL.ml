include URL_impl

let construct ?protocol ~hostname ?port ?pathname ?search ?hash ?password ?username () =
  let apply_opt f o = match o with None -> Fun.id | Some x -> fun u -> f u x in
  "https://example.com" |> makeExn |> apply_opt setProtocol protocol |> Fun.flip setHostname hostname
  |> apply_opt setPort port |> apply_opt setPathname pathname |> apply_opt setSearch search |> apply_opt setHash hash
  |> apply_opt setPassword password |> apply_opt setUsername username
