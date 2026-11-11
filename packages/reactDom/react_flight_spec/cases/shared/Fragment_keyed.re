/* Keyed fragments inside an array: React serializes each one as an element
   whose type is the react.fragment symbol, with its key in the key slot. */
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
