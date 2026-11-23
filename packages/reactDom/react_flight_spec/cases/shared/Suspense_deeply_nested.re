let app = () =>
  <React.Suspense fallback={<span> {React.string("level one")} </span>}>
    <React.Suspense fallback={<span> {React.string("level two")} </span>}>
      <React.Suspense fallback={<span> {React.string("level three")} </span>}>
        <div> {React.string("deep")} </div>
      </React.Suspense>
    </React.Suspense>
  </React.Suspense>;
