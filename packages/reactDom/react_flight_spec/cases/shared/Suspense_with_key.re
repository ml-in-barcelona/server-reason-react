let app = () =>
  <React.Suspense
    key="boundary" fallback={<span> {React.string("loading")} </span>}>
    <div> {React.string("keyed")} </div>
  </React.Suspense>;
