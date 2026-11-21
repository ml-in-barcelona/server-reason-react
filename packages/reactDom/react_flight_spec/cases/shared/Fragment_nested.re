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
