val expand : Ppxlib.expression -> Ppxlib.expression

val expand_attributes :
  loc:Ppxlib.Location.t -> (Ppxlib.arg_label * Ppxlib.expression) list -> (Ppxlib.arg_label * Ppxlib.expression) list
(** Expand a "styles" attribute into "className" and "style" on a lowercase element's argument list, merging with any
    existing ones. [expand] applies this to a whole JSX apply expression; callers that already hold the argument list
    can use this directly. *)
