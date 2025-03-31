type rendering =
  | Done of { app : string; head : Html.element; body : Html.element; end_script : Html.element }
  | Async of {
      everything : string;
      head : Html.element;
      shell : Html.element;
      subscribe : (Html.element -> unit Lwt.t) -> unit Lwt.t;
    }

val render_html :
  bootstrapScriptContent:string ->
  bootstrapScripts:string list ->
  bootstrapModules:string list ->
  React.element ->
  rendering Lwt.t

val render_model : ?subscribe:(string -> unit Lwt.t) -> React.element -> string Lwt_stream.t Lwt.t

(* val render_html :
     bootstrapScriptContent:string ->
     bootstrapScripts:string list ->
     bootstrapModules:string list ->
     React.element ->
     (string * (string -> unit Lwt.t) -> unit Lwt.t) Lwt.t

   val render_model : ?subscribe:(string -> unit Lwt.t) -> React.element -> string Lwt_stream.t Lwt.t

   module Html : module type of Html
*)
