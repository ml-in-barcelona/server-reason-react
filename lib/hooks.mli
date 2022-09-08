val use_ref : 'value -> 'value ref
val use_ref_lazy : (unit -> 'value) -> 'value ref
val use_state : 'state -> 'state * (('state -> 'state) -> unit)
val use_state_lazy : (unit -> 'state) -> 'state * (('state -> 'state) -> unit)

val use_reducer :
     init:(unit -> 'state)
  -> ('state -> 'action -> 'state)
  -> 'state * ('action -> unit)

val use_effect :
     on:'deps
  -> ?equal:('deps -> 'deps -> bool)
  -> ?before_render:bool
  -> ?cleanup:(unit -> unit)
  -> (unit -> unit)
  -> unit

val use_effect_once :
  ?before_render:bool -> ?cleanup:(unit -> unit) -> (unit -> unit) -> unit

val use_effect_always :
  ?before_render:bool -> ?cleanup:(unit -> unit) -> (unit -> unit) -> unit

val use_resource :
     on:'deps
  -> ?equal:('deps -> 'deps -> bool)
  -> ?before_render:bool
  -> release:('resource -> unit)
  -> (unit -> 'resource)
  -> unit

val use_memo :
  on:'deps -> ?equal:('deps -> 'deps -> bool) -> (unit -> 'value) -> 'value

val use_context : 'value Core.Context.t -> 'value
