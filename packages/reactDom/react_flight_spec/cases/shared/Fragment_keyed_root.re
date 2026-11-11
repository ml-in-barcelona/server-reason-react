/* A keyed fragment as the root model value. */
let app = () =>
  <React.Fragment key="root">
    <span> {React.string("one")} </span>
    <span> {React.string("two")} </span>
  </React.Fragment>;
