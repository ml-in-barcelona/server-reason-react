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
