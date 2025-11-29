(** Provide bindings for JS Date *)

type t

(** returns the primitive value of this date, equivalent to getTime *)
let valueOf _t = Js_internal.notImplemented "Js.Date" "valueOf"

(** returns a date representing the current time *)
let make _ = Js_internal.notImplemented "Js.Date" "make"

let fromFloat _ = Js_internal.notImplemented "Js.Date" "fromFloat"
let fromString _ = Js_internal.notImplemented "Js.Date" "fromString"
let makeWithYM ~year:_ ~month:_ = Js_internal.notImplemented "Js.Date" "makeWithYM"
let makeWithYMD ~year:_ ~month:_ ~date:_ = Js_internal.notImplemented "Js.Date" "makeWithYMD"
let makeWithYMDH ~year:_ ~month:_ ~date:_ ~hours:_ = Js_internal.notImplemented "Js.Date" "makeWithYMDH"
let makeWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "makeWithYMDHM"

let makeWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ =
  Js_internal.notImplemented "Js.Date" "makeWithYMDHMS"

let utcWithYM ~year:_ ~month:_ = Js_internal.notImplemented "Js.Date" "utcWithYM"
let utcWithYMD ~year:_ ~month:_ ~date:_ = Js_internal.notImplemented "Js.Date" "utcWithYMD"
let utcWithYMDH ~year:_ ~month:_ ~date:_ ~hours:_ = Js_internal.notImplemented "Js.Date" "utcWithYMDH"
let utcWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "utcWithYMDHM"

let utcWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ =
  Js_internal.notImplemented "Js.Date" "utcWithYMDHMS"

(** returns the number of milliseconds since Unix epoch *)
let now _ = Js_internal.notImplemented "Js.Date" "now"

(** returns NaN if passed invalid date string *)
let parseAsFloat _ = Js_internal.notImplemented "Js.Date" "parseAsFloat"

(** return the day of the month (1-31) *)
let getDate _ = Js_internal.notImplemented "Js.Date" "getDate"

(** returns the day of the week (0-6) *)
let getDay _ = Js_internal.notImplemented "Js.Date" "getDay"

let getFullYear _ = Js_internal.notImplemented "Js.Date" "getFullYear"
let getHours _ = Js_internal.notImplemented "Js.Date" "getHours"
let getMilliseconds _ = Js_internal.notImplemented "Js.Date" "getMilliseconds"
let getMinutes _ = Js_internal.notImplemented "Js.Date" "getMinutes"

(** returns the month (0-11) *)
let getMonth _ = Js_internal.notImplemented "Js.Date" "getMonth"

let getSeconds _ = Js_internal.notImplemented "Js.Date" "getSeconds"

(** returns the number of milliseconds since Unix epoch *)
let getTime _ = Js_internal.notImplemented "Js.Date" "getTime"

let getTimezoneOffset _ = Js_internal.notImplemented "Js.Date" "getTimezoneOffset"

(** return the day of the month (1-31) *)
let getUTCDate _ = Js_internal.notImplemented "Js.Date" "getUTCDate"

(** returns the day of the week (0-6) *)
let getUTCDay _ = Js_internal.notImplemented "Js.Date" "getUTCDay"

let getUTCFullYear _ = Js_internal.notImplemented "Js.Date" "getUTCFullYear"
let getUTCHours _ = Js_internal.notImplemented "Js.Date" "getUTCHours"
let getUTCMilliseconds _ = Js_internal.notImplemented "Js.Date" "getUTCMilliseconds"
let getUTCMinutes _ = Js_internal.notImplemented "Js.Date" "getUTCMinutes"

(** returns the month (0-11) *)
let getUTCMonth _ = Js_internal.notImplemented "Js.Date" "getUTCMonth"

let getUTCSeconds _ = Js_internal.notImplemented "Js.Date" "getUTCSeconds"
let setDate _ _ = Js_internal.notImplemented "Js.Date" "setDate"
let setFullYear _ = Js_internal.notImplemented "Js.Date" "setFullYear"
let setFullYearM ~year:_ ~month:_ = Js_internal.notImplemented "Js.Date" "setFullYearM"
let setFullYearMD ~year:_ ~month:_ ~date:_ = Js_internal.notImplemented "Js.Date" "setFullYearMD"
let setHours _ = Js_internal.notImplemented "Js.Date" "setHours"
let setHoursM ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "setHoursM"
let setHoursMS ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "setHoursMS"
let setHoursMSMs ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ = Js_internal.notImplemented "Js.Date" "setHoursMSMs"
let setMilliseconds _ = Js_internal.notImplemented "Js.Date" "setMilliseconds"
let setMinutes _ = Js_internal.notImplemented "Js.Date" "setMinutes"
let setMinutesS ~minutes:_ = Js_internal.notImplemented "Js.Date" "setMinutesS"
let setMinutesSMs ~minutes:_ = Js_internal.notImplemented "Js.Date" "setMinutesSMs"
let setMonth _ = Js_internal.notImplemented "Js.Date" "setMonth"
let setMonthD ~month:_ ~date:_ _ = Js_internal.notImplemented "Js.Date" "setMonthD"
let setSeconds _ = Js_internal.notImplemented "Js.Date" "setSeconds"
let setSecondsMs ~seconds:_ ~milliseconds:_ _ = Js_internal.notImplemented "Js.Date" "setSecondsMs"
let setTime _ = Js_internal.notImplemented "Js.Date" "setTime"
let setUTCDate _ = Js_internal.notImplemented "Js.Date" "setUTCDate"
let setUTCFullYear _ = Js_internal.notImplemented "Js.Date" "setUTCFullYear"
let setUTCFullYearM ~year:_ ~month:_ _ = Js_internal.notImplemented "Js.Date" "setUTCFullYearM"
let setUTCFullYearMD ~year:_ ~month:_ ~date:_ _ = Js_internal.notImplemented "Js.Date" "setUTCFullYearMD"
let setUTCHours _ = Js_internal.notImplemented "Js.Date" "setUTCHours"
let setUTCHoursM ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "setUTCHoursM"
let setUTCHoursMS ~hours:_ ~minutes:_ = Js_internal.notImplemented "Js.Date" "setUTCHoursMS"

let setUTCHoursMSMs ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ =
  Js_internal.notImplemented "Js.Date" "setUTCHoursMSMs"

let setUTCMilliseconds _ = Js_internal.notImplemented "Js.Date" "setUTCMilliseconds"
let setUTCMinutes _ = Js_internal.notImplemented "Js.Date" "setUTCMinutes"
let setUTCMinutesS ~minutes:_ = Js_internal.notImplemented "Js.Date" "setUTCMinutesS"
let setUTCMinutesSMs ~minutes:_ = Js_internal.notImplemented "Js.Date" "setUTCMinutesSMs"
let setUTCMonth _ = Js_internal.notImplemented "Js.Date" "setUTCMonth"
let setUTCMonthD ~month:_ ~date:_ _ = Js_internal.notImplemented "Js.Date" "setUTCMonthD"
let setUTCSeconds _ = Js_internal.notImplemented "Js.Date" "setUTCSeconds"
let setUTCSecondsMs ~seconds:_ = Js_internal.notImplemented "Js.Date" "setUTCSecondsMs"
let setUTCTime _ = Js_internal.notImplemented "Js.Date" "setUTCTime"
let toDateString _string = Js_internal.notImplemented "Js.Date" "toDateString"
let toISOString _string = Js_internal.notImplemented "Js.Date" "toISOString"
let toJSON _string = Js_internal.notImplemented "Js.Date" "toJSON"
let toJSONUnsafe _string = Js_internal.notImplemented "Js.Date" "toJSONUnsafe"
let toLocaleDateString _string = Js_internal.notImplemented "Js.Date" "toLocaleDateString"

(* TODO: has overloads with somewhat poor browser support *)
let toLocaleString _string = Js_internal.notImplemented "Js.Date" "toLocaleString"

(* TODO: has overloads with somewhat poor browser support *)
let toLocaleTimeString _string = Js_internal.notImplemented "Js.Date" "toLocaleTimeString"

(* TODO: has overloads with somewhat poor browser support *)
let toString _string = Js_internal.notImplemented "Js.Date" "toString"
let toTimeString _string = Js_internal.notImplemented "Js.Date" "toTimeString"
let toUTCString _string = Js_internal.notImplemented "Js.Date" "toUTCString"
