let lower = <div />;
let lower_with_empty_attr = <div className="" />;
let lower_with_style =
  <div style={ReactDOM.Style.make(~backgroundColor="gainsboro", ())} />;
let lower_inner_html = <div dangerouslySetInnerHTML={"__html": text} />;
let lower_opt_attr = <div ?tabIndex />;
let upper = <Input />;

module React_component_without_props = {
  [@react.component]
  let make = (~lola, ~cosis) => {
    Js.log(cosis);

    <div>{React.string(lola)}</div>
  }
}

let upper = <React_component_without_props lola="flores" />;
