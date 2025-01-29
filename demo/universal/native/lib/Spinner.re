[@react.component]
let make = (~active) => {
  <div
    role="progressbar"
    ariaBusy=true
    style={ReactDOM.Style.make(
      ~display="inline-block",
      ~transition="opacity linear 0.1s",
      ~width="20px",
      ~height="20px",
      ~border="3px solid rgba(80, 80, 80, 0.5)",
      ~borderRadius="50%",
      ~borderTopColor="#fff",
      ~animation={active ? "spin 1s ease-in-out infinite" : "none"},
      ~opacity={active ? "1" : "0"},
      (),
    )}
  />;
};
