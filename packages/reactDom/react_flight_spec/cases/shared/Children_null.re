let show = false;

let app = () =>
  <div>
    <p> React.null </p>
    React.null
    <span> {React.string("between")} </span>
    {show ? <em> {React.string("never")} </em> : React.null}
  </div>;
