type 'a t = 'a Lwt.t
type error = exn

val make : (resolve:('a -> unit) -> reject:(exn -> unit) -> unit) -> 'a Lwt.t
val resolve : 'a -> 'a Lwt.t
val reject : exn -> 'a Lwt.t
val all : 'a Lwt.t array -> 'a array Lwt.t
val all2 : 'a Lwt.t * 'b Lwt.t -> ('a * 'b) Lwt.t
val all3 : 'a Lwt.t * 'b Lwt.t * 'c Lwt.t -> ('a * 'b * 'c) Lwt.t
val all4 : 'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t -> ('a * 'b * 'c * 'd) Lwt.t
val all5 : 'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t * 'e Lwt.t -> ('a * 'b * 'c * 'd * 'e) Lwt.t
val all6 : 'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t * 'e Lwt.t * 'f Lwt.t -> ('a * 'b * 'c * 'd * 'e * 'f) Lwt.t
val race : 'a Lwt.t array -> 'a Lwt.t
val then_ : ('a -> 'b Lwt.t) -> 'a Lwt.t -> 'b Lwt.t
val catch : (exn -> 'a Lwt.t) -> 'a Lwt.t -> 'a Lwt.t
