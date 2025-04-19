  $ ../ppx.sh --output ml input.re
  let make ?key:(_ : string option) () =
    React.Upper_case_component
      ( __FUNCTION__,
        fun () ->
          React.createElementWithKey ~key:None "div" [] [ React.string "lol" ] )
  [@@platform js]
