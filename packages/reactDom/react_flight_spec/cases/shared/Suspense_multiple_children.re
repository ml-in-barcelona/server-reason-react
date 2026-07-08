/* Suspense with an array of children, all sync: children serialize as a JSON
   array inside the boundary's props, inline in the root row. */
let app = () =>
  <React.Suspense fallback={<span> {React.string("loading")} </span>}>
    <em> {React.string("one")} </em>
    <strong> {React.string("two")} </strong>
    {React.string("three")}
  </React.Suspense>;
