/* Multi-property style objects: React preserves the key order of the JS
   style object, which for reason-react's [ReactDOM.Style.make] is the
   [@mel.obj] signature order. srr's ReactDOM.Style.make emits its property
   list in the same signature order. */
let app = () =>
  <div
    style={ReactDOM.Style.make(~backgroundColor="black", ~color="white", ())}
  />;
