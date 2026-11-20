include ReactServerDOM.FunctionReferences.Make (struct
  type t = unit

  let default = ()
end)

let ids = ref []

let register ~id ~name ~meta handler =
  register ~id ~name ~meta handler;
  ids := id :: !ids
