let app = () =>
  <React.Suspense fallback=React.null>
    <div> {React.string("null fallback")} </div>
  </React.Suspense>;
