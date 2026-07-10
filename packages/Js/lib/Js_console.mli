val log : 'a -> unit
val log2 : 'a -> 'b -> unit
val log3 : 'a -> 'b -> 'c -> unit
val log4 : 'a -> 'b -> 'c -> 'd -> unit
val logMany : 'a array -> unit
val info : 'a -> unit
val info2 : 'a -> 'b -> unit
val info3 : 'a -> 'b -> 'c -> unit
val info4 : 'a -> 'b -> 'c -> 'd -> unit
val infoMany : 'a array -> unit
val error : 'a -> unit
val error2 : 'a -> 'b -> unit
val error3 : 'a -> 'b -> 'c -> unit
val error4 : 'a -> 'b -> 'c -> 'd -> unit
val errorMany : 'a array -> unit
val warn : 'a -> unit
val warn2 : 'a -> 'b -> unit
val warn3 : 'a -> 'b -> 'c -> unit
val warn4 : 'a -> 'b -> 'c -> 'd -> unit
val warnMany : 'a array -> unit
val trace : unit -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val timeStart : 'a -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val timeEnd : 'a -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
