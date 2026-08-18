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
type redirect_leaf = { id : string; target : expression; scope : scope; loc : Location.t }

type group = { scope : scope; children : node list }
and node = Group of group | Route of leaf | Redirect of redirect_leaf

type route = {
  name : string;
  page : expression;
  path : string;
  parameters : parameter list;
  search : search list;
  scopes : scope list;
  loc : Location.t;
}

type redirect = {
  id : string;
  target : expression;
  path : string;
  parameters : parameter list;
  search : search list;
  loc : Location.t;
}

type endpoint = Page of route | RedirectTo of redirect
type trailing_slash = Redirect | Reject

type t = {
  base_path : string;
  trailing_slash : trailing_slash;
  application_error : Longident.t option;
  invalid_search : expression option;
  root : group;
  loc : Location.t;
}

val find : structure -> t option
val root_search : t -> search list
val endpoints : t -> endpoint list
val routes : t -> route list
