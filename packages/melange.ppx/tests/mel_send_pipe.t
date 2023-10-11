[@@mel.send.pipe: t] should generate a function with the piped argument,
both on the type annotation, also on the function expression.
  $ cat > input.ml << EOF
  > external getPropertyPriority: string -> string = "getPropertyPriority" [@@mel.send.pipe: t]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (getPropertyPriority : string -> t -> string) =
   fun _ _ -> raise (Failure "called Melange external \"mel.\" from native")

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
    raise (Failure "called Melange external \"mel.\" from native")

Single argument (Ptyp_constr)
  $ cat > input.ml << EOF
  > external arrayBuffer : arrayBuffer Js.Promise.t = "arrayBuffer" [@@mel.send.pipe: T.t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (arrayBuffer : arrayBuffer Js.Promise.t -> T.t) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")

Labelled arguments
  $ cat > input.ml << EOF
  > external scale : x:float -> y:float -> unit = "scale"[@@mel.send.pipe : t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (scale : x:float -> y:float -> t -> unit) =
   fun ~x:_ ~y:_ _ ->
    raise (Failure "called Melange external \"mel.\" from native")

Nonlabelled arguments as functions
  $ cat > input.ml << EOF
  > external forEach : (string -> int -> unit) -> unit = "forEach" [@@mel.send.pipe : t]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (forEach : (string -> int -> unit) -> t -> unit) =
   fun _ _ -> raise (Failure "called Melange external \"mel.\" from native")

'a
  $ cat > input.ml << EOF
  > external postMessage : 'a -> string -> unit = "postMessage" [@@mel.send]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (postMessage : 'a -> string -> unit) =
   fun _ _ -> raise (Failure "called Melange external \"mel.\" from native")

  $ cat > input.ml << EOF
  > external postMessage : 'a -> string -> unit = "postMessage" [@@mel.send.pipe : t_window]

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (postMessage : 'a -> t_window -> string -> unit) =
   fun _ _ _ -> raise (Failure "called Melange external \"mel.\" from native")
