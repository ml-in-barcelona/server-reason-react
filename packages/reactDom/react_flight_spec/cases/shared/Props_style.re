/* The style prop serializes as a JSON object with camelCase CSS property
   names, exactly as the user-side style object looks in JS. A single
   property keeps the key order deterministic across both Style.make
   implementations; multi-property ordering lives in Props_style_order. */
let app = () =>
  <div style={ReactDOM.Style.make(~color="rebeccapurple", ())} />;
