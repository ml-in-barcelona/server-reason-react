let app = () =>
  <div>
    {React.string("text child")}
    <span> {React.string("element child")} </span>
    React.null
    {React.array([|
       <b key="x"> {React.string("x")} </b>,
       <b key="y"> {React.string("y")} </b>,
     |])}
  </div>;
