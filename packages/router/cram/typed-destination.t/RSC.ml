type t = unit
type of_rsc_error = Rsc_error of string

exception Of_rsc_error of of_rsc_error

module Primitives = struct
  let string_to_rsc _ = ()
  let string_of_rsc _ = ""
  let list_to_rsc _ _ = ()
  let list_of_rsc _ _ = []
  let tuple2_to_rsc _ _ _ = ()
  let tuple2_of_rsc _ _ _ = ("", [])
end
