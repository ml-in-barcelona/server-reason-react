open Ppxlib

type value

val public : string -> value
val generated : string -> value
val user : string -> value
val evar : loc:location -> value -> expression
val pvar : loc:location -> value -> pattern
val is_var : value -> expression -> bool
val own : loc:location -> string -> string list -> longident loc

type scan

val scan_structure : structure -> scan
val scan_signature : signature -> scan

type plan

val plan : user_expressions:expression list -> defined_modules:string list -> scan list -> plan
val structure : loc:location -> restore_in:string list -> plan -> structure -> structure
val signature : loc:location -> restore_in:string list -> plan -> signature -> signature
