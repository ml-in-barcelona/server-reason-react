external init : keycloak -> param:initParam -> init = "init" [@@mel.send]
external makeInitParam : onLoad:string -> unit -> initParam = "" [@@mel.obj]
external keycloak : keycloak = "default" [@@mel.module "keycloak-js"]
