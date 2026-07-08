/* React.null as children: a sole null child, nulls between siblings, and a
   conditional that took the null branch. Note: boolean children (JS
   {true}/{false}, which React renders as nothing) are not expressible in
   typed Reason JSX on either side — there is no React.bool — so this case
   only covers null. */
let show = false;

let app = () =>
  <div>
    <p> React.null </p>
    React.null
    <span> {React.string("between")} </span>
    {show ? <em> {React.string("never")} </em> : React.null}
  </div>;
