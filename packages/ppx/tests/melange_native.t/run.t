  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  external init : keycloak -> param:initParam -> init = "init" [@@mel.send]
  external makeInitParam : onLoad:string -> unit -> initParam = "" [@@mel.obj]
  
  let (keycloak : keycloak) =
   fun _ -> raise (Failure "called Melange external @mel from native")
  
  let (keycloak : string -> keycloak) =
   fun _ -> raise (Failure "called Melange external @mel from native")
  
  let (keycloak : int -> string -> keycloak) =
   fun _ -> raise (Failure "called Melange external @mel from native")
