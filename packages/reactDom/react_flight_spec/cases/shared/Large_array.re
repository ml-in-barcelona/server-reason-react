/* 50 keyed elements in one array: the row simply grows, there is no
   outlining or deduplication of repeated element shapes in the model. */
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
