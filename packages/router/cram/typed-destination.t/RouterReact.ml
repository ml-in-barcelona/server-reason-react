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

type blocker = Unblocked
type invalidation = All

module Link = struct
  type attributes = unit

  let createElement ~destination:_ ?attributes:_ ?className:_ ?target:_ ?download:_ ?ariaCurrent:_ ?history:_
      ?revalidate:_ ~children:_ () =
    ()
end
let navigate ?history:_ ?revalidate:_ _destination = failwith "not used"
let updateHash ~hash:_ ?history:_ () = failwith "not used"
let useNavigation () = (navigate, RouterRuntime.Navigation.Idle)
let useCurrentRoute () = None
let useUpdateHash () = updateHash
let useSearch () = ([], fun ~owned:_ ~values:_ ?history:_ () -> ())
let useUpdateSearchWith () ~owned:_ ?history:_ _update = failwith "not used"
let useMatches () : RouterRuntime.Navigation.matched list = []
let useLocation () = RouterRuntime.Navigation.{ pathname = "/"; search = ""; hash = ""; key = "" }
let useIsCurrent _destination = false
let useBlocker _shouldBlock = Unblocked
let useInvalidate () _invalidation = ()
