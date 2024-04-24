(* Based on melange version:
   https://github.com/melange-re/melange/blob/482112aa4988634bf4102955c47fbe8f0538b4f3/ppx/ast_derive/ast_derive_js_mapper.mli
*)

open Ppxlib

val derive_structure :
  newType:bool -> type_declaration list -> structure_item list

val derive_signature :
  newType:bool -> type_declaration list -> signature_item list
