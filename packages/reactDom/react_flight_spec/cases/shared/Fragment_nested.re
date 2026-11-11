/* Nested key-less fragments with siblings around them: fragments are
   transparent in the Flight model, so only their children's grouping
   survives in the children array. Keyed fragments are covered by
   Fragment_keyed. */
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
