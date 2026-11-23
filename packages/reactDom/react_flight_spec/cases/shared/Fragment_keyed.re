let app = () =>
  <ul>
    {React.array([|
       <React.Fragment key="a">
         <li> {React.string("alpha")} </li>
         <li> {React.string("beta")} </li>
       </React.Fragment>,
       <React.Fragment key="b">
         <li> {React.string("gamma")} </li>
       </React.Fragment>,
     |])}
  </ul>;
