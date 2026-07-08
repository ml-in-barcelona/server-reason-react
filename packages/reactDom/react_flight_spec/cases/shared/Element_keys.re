/* Keys on host elements inside an array: the key travels as the third slot
   of the element tuple ["$",tag,key,props], not as a prop. */
let app = () =>
  <ul>
    {React.array([|
       <li key="a"> {React.string("alpha")} </li>,
       <li key="b"> {React.string("beta")} </li>,
       <li key="c"> {React.string("gamma")} </li>,
     |])}
  </ul>;
