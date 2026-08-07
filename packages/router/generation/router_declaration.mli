open Ppxlib

type parameter = { name : string; typ : core_type; parser : Longident.t; to_string : Longident.t; loc : Location.t }
type search_kind = Required | Optional | Default of expression | Many

type search = {
  name : string;
  typ : core_type;
  parser : Longident.t;
  to_string : Longident.t;
  kind : search_kind;
  loc : Location.t;
}

type loader = { run : expression; result_label : string; loc : Location.t }

type attachments = {
  layout : expression option;
  loading : expression option;
  not_found : expression option;
  error : expression option;
  loader : loader option;
  metadata : expression option;
  headers : expression option;
}

type scope = {
  id : string;
  path : string;
  parameters : parameter list;
  search : search list;
  attachments : attachments;
  loc : Location.t;
}

type leaf = { name : string; page : expression; scope : scope; loc : Location.t }

type group = { scope : scope; children : node list }
and node = Group of group | Route of leaf

type route = {
  name : string;
  page : expression;
  path : string;
  parameters : parameter list;
  search : search list;
  scopes : scope list;
  loc : Location.t;
}

type t = {
  base_path : string;
  application_error : Longident.t option;
  invalid_search : expression option;
  root : group;
  loc : Location.t;
}

val find : structure -> t option
val root_search : t -> search list
val routes : t -> route list
