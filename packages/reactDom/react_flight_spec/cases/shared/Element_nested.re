let app = () =>
  <div id="root">
    <ul>
      <li key="first"> {React.string("First")} </li>
      <li key="second"> {React.string("Second")} </li>
    </ul>
    {React.array([|
       <span key="a"> {React.string("a")} </span>,
       <span key="b"> {React.string("b")} </span>,
     |])}
  </div>;
