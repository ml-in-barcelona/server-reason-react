let fragment = foo => [@bla] <> foo </>;

let poly_children_fragment = (foo, bar) => <> foo bar </>;
let nested_fragment = (foo, bar, baz) => <> foo <> bar baz </> </>;

let nested_fragment_with_lower = foo => <> <div> foo </div> </>;

module Fragment = {
  [@react.component]
  let make = (~name="") =>
    <>
      <div> {React.string("First " ++ name)} </div>
      <Hello one="1"> {React.string("2nd " ++ name)} </Hello>
    </>;
};
