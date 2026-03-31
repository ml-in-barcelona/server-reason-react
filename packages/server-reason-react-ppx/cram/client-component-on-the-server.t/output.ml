[@@@warning "-32"]
open Melange_json.Primitives
type lola = {
  name: string }[@@deriving json]
let make ~initial:(initial : int) =
  fun ~lola:(lola : lola) ->
    fun ~children:(children : React.element) ->
      fun ~maybe_children:(maybe_children : React.element option) ->
        ((section
            ~children:[((h1 ~children:[React.string lola.name] ())
                      [@JSX ]);
                      ((p ~children:[React.int initial] ())
                      [@JSX ]);
                      ((div ~children:[children] ())
                      [@JSX ]);
                      (match maybe_children with
                       | ((Some (children))[@explicit_arity ]) -> children
                       | None -> React.null)] ())
        [@JSX ])[@@react.client.component ]