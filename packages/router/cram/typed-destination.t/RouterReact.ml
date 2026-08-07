type navigate =
  ?history:RouterRuntime.Navigation.historyAction ->
  ?revalidate:bool ->
  RouterRuntime.destination ->
  RouterRuntime.Navigation.Result.t Js.Promise.t
type updateHash =
  hash:string ->
  ?history:RouterRuntime.Navigation.historyAction ->
  unit ->
  RouterRuntime.Navigation.Result.t

let link ~destination:_ ?className:_ ?target:_ ?download:_ ?ariaCurrent:_ ?history:_ ?revalidate:_ ~children:_ () = ()
let navigate ?history:_ ?revalidate:_ _destination = failwith "not used"
let updateHash ~hash:_ ?history:_ () = failwith "not used"
let useNavigation () = (navigate, RouterRuntime.Navigation.Idle)
let useUpdateHash () = updateHash
let useIsActive ~routeId:_ ~parameters:_ ~includeDescendants:_ = false
