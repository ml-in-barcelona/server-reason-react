  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (init : keycloak -> param:initParam -> init) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
  
  let (makeInitParam : onLoad:string -> unit -> initParam) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
  
  let (keycloak : keycloak) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
  
  let (keycloak : string -> keycloak) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
  
  let (keycloak : int -> string -> keycloak) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
