/* Suspense without a fallback prop: how does React serialize the missing
   prop? (React omits the key entirely from the props object.) */
let app = () =>
  <React.Suspense>
    <div> {React.string("no fallback")} </div>
  </React.Suspense>;
