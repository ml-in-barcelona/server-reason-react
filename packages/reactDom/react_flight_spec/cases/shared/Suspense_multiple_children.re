let app = () =>
  <React.Suspense fallback={<span> {React.string("loading")} </span>}>
    <em> {React.string("one")} </em>
    <strong> {React.string("two")} </strong>
    {React.string("three")}
  </React.Suspense>;
