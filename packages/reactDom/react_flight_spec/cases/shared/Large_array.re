let app = () =>
  <ul>
    {React.array(
       Array.init(50, index =>
         <li key={"item-" ++ string_of_int(index)}>
           {React.string("Item " ++ string_of_int(index))}
         </li>
       ),
     )}
  </ul>;
