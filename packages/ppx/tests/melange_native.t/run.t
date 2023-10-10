Labelled args with @@mel.send

  $ cat > input.ml <<EOF
  > external init : string -> param:int -> string = "init" [@@mel.send]
  > EOF

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (init : string -> param:int -> string) =
   fun _ ~param:_ ->
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

Labelled and unlabelled args with @@mel.obj

  $ cat > input.ml <<EOF
  > external makeInitParam : onLoad:string -> unit -> string = "" [@@mel.obj]
  > EOF

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (makeInitParam : onLoad:string -> unit -> string) =
   fun ~onLoad:_ _ ->
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

Only unlabelled

  $ cat > input.ml <<EOF
  > type keycloak
  > external keycloak : string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : string -> keycloak) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

Multiple args with optional

  $ cat > input.ml <<EOF
  > type keycloak
  > external keycloak : ?z:int -> int -> foo:string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : ?z:int -> int -> foo:string -> keycloak) =
   fun ?z:_ _ ~foo:_ ->
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

Single type (invalid OCaml, but valid in Melange)

  $ cat > input.ml <<EOF
  > type keycloak
  > external keycloak : keycloak = "default" [@@mel.module "keycloak-js"]
  > EOF

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : keycloak) =
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml
