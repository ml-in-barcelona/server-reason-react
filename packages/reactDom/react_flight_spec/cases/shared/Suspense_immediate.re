let app = () =>
  <React.Suspense fallback={<span> {React.string("loading")} </span>}>
    <div> {React.string("ready")} </div>
  </React.Suspense>;
