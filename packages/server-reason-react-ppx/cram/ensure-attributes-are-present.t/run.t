  $ ../ppx.sh --output ml input.re
  include struct
    let makeProps () =
      let __js_obj = object end in
      (Js.Obj.Internal.register_abstract __js_obj [] : < > Js.t)
  
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
  
    let make ?(key : string option) (_Props : < > Js.t) = make ?key ()
  end [@@platform js]
