[@@mel.send.pipe: t] should generate a function with the piped argument,
both on the type annotation, also on the function expression.
  $ cat > input.ml << EOF
  > external getPropertyPriority: string -> string = "getPropertyPriority" [@@mel.send.pipe: t]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (getPropertyPriority : string -> t -> string) =
   fun _ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "getPropertyPriority")

  $ echo "type t" > main.ml
  $ echo "module Runtime = struct" >> main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ ocamlc -c main.ml

Make sure is placed correctly
  $ cat > input.ml << EOF
  > external createDocumentType : qualifiedName:string -> publicId:string -> systemId:string -> Dom.documentType = "createDocumentType" [@@mel.send.pipe: t]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (createDocumentType :
        qualifiedName:string ->
        publicId:string ->
        systemId:string ->
        t ->
        Dom.documentType) =
   fun ~qualifiedName:_ ~publicId:_ ~systemId:_ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "createDocumentType")

  $ echo "type t" > main.ml
  $ echo "module Dom = struct type documentType end" >> main.ml
  $ echo "module Runtime = struct" >> main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Single argument (Ptyp_constr)
  $ cat > input.ml << EOF
  > external arrayBuffer : arrayBuffer Js.Promise.t = "arrayBuffer" [@@mel.send.pipe: T.t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (arrayBuffer : arrayBuffer Js.Promise.t -> T.t) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "arrayBuffer")

Labelled arguments
  $ cat > input.ml << EOF
  > type t
  > external scale : x:float -> y:float -> unit = "scale"[@@mel.send.pipe : t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (scale : x:float -> y:float -> t -> unit) =
   fun ~x:_ ~y:_ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "scale")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Nonlabelled arguments as functions
  $ cat > input.ml << EOF
  > type t
  > external forEach : (string -> int -> unit) -> unit = "forEach" [@@mel.send.pipe : t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (forEach : (string -> int -> unit) -> t -> unit) =
   fun _ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "forEach")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

'a
  $ cat > input.ml << EOF
  > external postMessage : 'a -> string -> unit = "postMessage" [@@mel.send]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (postMessage : 'a -> string -> unit) =
   fun _ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "postMessage")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Send pipe with 'a
  $ cat > input.ml << EOF
  > external postMessage : 'a -> string -> unit = "postMessage" [@@mel.send.pipe : t_window]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (postMessage : 'a -> t_window -> string -> unit) =
   fun _ _ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "postMessage")
