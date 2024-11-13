type rendering =
  | Done of {
      head : Html.element;
      body : Html.element;
      end_script : Html.element;
    }
  | Async of {
      head : Html.element;
      shell : Html.element;
      subscribe : (Html.element -> unit Lwt.t) -> unit Lwt.t;
    }

val render_to_html : React.element -> rendering Lwt.t

val render_to_model :
  ?subscribe:(string -> unit Lwt.t) ->
  React.element ->
  string Lwt_stream.t Lwt.t
