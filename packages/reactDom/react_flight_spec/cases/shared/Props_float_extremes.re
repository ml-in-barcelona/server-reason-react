/* Float values at JavaScript's number-printing boundaries: JSON.stringify
   prints integral doubles in full digits up to 1e21 (9e18 crosses the wire
   as 9000000000000000000, beyond OCaml's 2^53-exact range), switches to
   exponent form at 1e21 and below 1e-6, prints -0 as 0, and shortest
   round-trip decimals otherwise. */
let app = () =>
  Spec.client_component(
    ~importModule="spec/FloatSink.js",
    ~importName="default",
    ~props=[
      Spec.float("largeInteger", 9e18),
      Spec.float("exponentThreshold", 1e21),
      Spec.float("small", 1e-7),
      Spec.float("shortestRoundTrip", 0.30000000000000004),
      Spec.float("negativeZero", -0.),
      Spec.float("notANumber", Float.nan),
      Spec.float("positiveInfinity", Float.infinity),
      Spec.float("negativeInfinity", Float.neg_infinity),
    ],
    (),
  );
