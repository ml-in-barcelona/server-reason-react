/* Nested key-less fragments with siblings around them: fragments are
   transparent in the Flight model, so only their children's grouping
   survives in the children array. (A keyed fragment serializes as a
   react.fragment symbol element in React, but server-reason-react's
   React.Fragment cannot carry a key, so that variant is not expressible
   single-source.) */
let app = () =>
  <div>
    {React.string("before")}
    <>
      <span> {React.string("inside first")} </span>
      <> <em> {React.string("nested")} </em> {React.string("deep text")} </>
      <span> {React.string("inside last")} </span>
    </>
    {React.string("after")}
  </div>;
