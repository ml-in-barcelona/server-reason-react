let test ~isLazy =
 fun ?alt ->
  fun ?ariaHidden ->
   fun ?onLoad ->
    fun ~srcDesktop ->
     (img ~src:srcDesktop
        ?loading:(match isLazy with true -> Some "lazy" [@explicit_arity] | false -> None)
        ?alt ?ariaHidden ?onLoad ~children:[] () [@JSX])
