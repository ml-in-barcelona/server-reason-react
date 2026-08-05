type options = unit
type navigate = unit
type updateHash = unit

let link ~destination:_ ?className:_ ?target:_ ?download:_ ?ariaCurrent:_ ?options:_ ~children:_ () = ()
let useNavigation () = (None, RouterRuntime.Navigation.Idle)
let useUpdateHash () = None
let useIsActive ~routeId:_ ~parameters:_ ~includeDescendants:_ = false
