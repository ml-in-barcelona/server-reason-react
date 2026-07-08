/* Multi-property style objects: React preserves the insertion order of the
   JS style object (Style.make argument order on the melange side), while
   srr's ReactDOM.Style.make builds its property list by prepending in
   declaration order, so the resulting JSON keys come out reversed. */
let app = () =>
  <div
    style={ReactDOM.Style.make(~backgroundColor="black", ~color="white", ())}
  />;
