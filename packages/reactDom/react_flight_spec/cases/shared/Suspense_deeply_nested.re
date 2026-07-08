/* Three levels of sync Suspense nesting: the "$Sreact.suspense" symbol row is
   outlined exactly once and every boundary's type references it ("$1"). */
let app = () =>
  <React.Suspense fallback={<span> {React.string("level one")} </span>}>
    <React.Suspense fallback={<span> {React.string("level two")} </span>}>
      <React.Suspense fallback={<span> {React.string("level three")} </span>}>
        <div> {React.string("deep")} </div>
      </React.Suspense>
    </React.Suspense>
  </React.Suspense>;
