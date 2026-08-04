type options = unit
type navigate = unit
type updateHash = unit

let link ~destination:_ ~children:_ ?options:_ () = ()
let useNavigate () = None
let useNavigation () = failwith "unused"
let useUpdateHash () = None
let useIsActive ~routeId:_ ~parameters:_ ~includeDescendants:_ = false
