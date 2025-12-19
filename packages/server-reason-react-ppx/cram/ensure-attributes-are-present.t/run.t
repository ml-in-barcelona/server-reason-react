  $ ../ppx.sh --output ml input.re
  let make ?key:(_ : string option) () =
    React.Upper_case_component
      (Stdlib.__FUNCTION__, fun () -> React.DangerouslyInnerHtml "<div>lol</div>")
  [@@platform js]
