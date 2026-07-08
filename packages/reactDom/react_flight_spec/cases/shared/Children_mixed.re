/* Mixed children: text, an element, React.null and a nested array all in one
   children list. Nulls stay as JSON null slots; the nested array nests. */
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
