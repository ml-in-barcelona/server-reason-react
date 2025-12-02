val log : string -> unit
val log2 : string -> string -> unit
val log3 : string -> string -> string -> unit
val log4 : string -> string -> string -> string -> unit
val logMany : string array -> unit
val info : string -> unit
val info2 : string -> string -> unit
val info3 : string -> string -> string -> unit
val info4 : string -> string -> string -> string -> unit
val infoMany : string array -> unit
val error : string -> unit
val error2 : string -> string -> unit
val error3 : string -> string -> string -> unit
val error4 : string -> string -> string -> string -> unit
val errorMany : string array -> unit
val warn : string -> unit
val warn2 : string -> string -> unit
val warn3 : string -> string -> string -> unit
val warn4 : string -> string -> string -> string -> unit
val warnMany : string array -> unit
val trace : unit -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val timeStart : 'a -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val timeEnd : 'a -> unit [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
