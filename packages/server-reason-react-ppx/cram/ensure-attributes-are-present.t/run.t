  $ ../ppx.sh --output ml input.re
  let make ?key:(_ : string option) () =
    React.Upper_case_component
      ( Stdlib.__FUNCTION__,
        fun () ->
          React.Static
            {
              prerendered = "<div>lol</div>";
              original = React.createElement "div" [] [ React.string "lol" ];
            } )
  [@@platform js]
