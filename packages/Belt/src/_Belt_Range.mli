(** A small module to provide a inclusive range operations [\[start, finsish\]],
    it use a for-loop internally instead of creating an array
*)

val forEachU : int -> int -> ((int -> unit)[@bs]) -> unit

val forEach : int -> int -> (int -> unit) -> unit
(** [forEach start finish action]

    equivalent to [Belt.Array.(forEach (range start finish) action)]
*)

val everyU : int -> int -> ((int -> bool)[@bs]) -> bool

val every : int -> int -> (int -> bool) -> bool
(** [every start finish p]

    equivalent to [Belt.Array.(every (range start finish) p )]
*)

val everyByU : int -> int -> step:int -> ((int -> bool)[@bs]) -> bool

val everyBy : int -> int -> step:int -> (int -> bool) -> bool
(** [everyBy start finish ~step p]

    {b See} {!Belt.Array.rangeBy}

    equivalent to [Belt.Array.(every (rangeBy start finish ~step) p)]
*)

val someU : int -> int -> ((int -> bool)[@bs]) -> bool

val some : int -> int -> (int -> bool) -> bool
(** [some start finish p]

    equivalent to [Belt.Array.(some (range start finish) p)]
*)

val someByU : int -> int -> step:int -> ((int -> bool)[@bs]) -> bool

val someBy : int -> int -> step:int -> (int -> bool) -> bool
(** [someBy start finish ~step  p]

    {b See} {!Belt.Array.rangeBy}

    equivalent to [Belt.Array.(some (rangeBy start finish ~step) p)]
*)
