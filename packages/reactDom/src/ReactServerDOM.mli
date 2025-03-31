type rendering =
  | Done of { app : string; head : Html.element; body : Html.element; end_script : Html.element }
  | Async of { head : Html.element; shell : Html.element; subscribe : (Html.element -> unit Lwt.t) -> unit Lwt.t }

val render_html : React.element -> rendering Lwt.t
val render_model : ?subscribe:(string -> unit Lwt.t) -> React.element -> string Lwt_stream.t Lwt.t
val act : ?subscribe:(string -> unit Lwt.t) -> React.rsc_value -> string Lwt_stream.t Lwt.t

module Html : module type of Html
