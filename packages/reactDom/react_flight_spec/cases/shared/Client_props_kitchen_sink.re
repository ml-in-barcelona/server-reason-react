let app = () =>
  Spec.client_component(
    ~importModule="spec/Kitchen.js",
    ~importName="Sink",
    ~props=[
      Spec.string("label", "plain"),
      Spec.int("count", 7),
      Spec.float("ratio", 0.25),
      Spec.bool("on", true),
      Spec.bool("off", false),
      Spec.json_null("empty"),
      Spec.string("price", "$money"),
      Spec.string("greeting", {js|héllo wörld — 日本語 🎉|js}),
    ],
    (),
  );
