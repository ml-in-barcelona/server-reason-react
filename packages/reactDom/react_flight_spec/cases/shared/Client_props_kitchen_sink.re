/* One client component exercising every scalar prop constructor at once,
   plus the two string edge cases: a user string starting with "$" (must be
   escaped to "$$" on the wire) and a non-ASCII string (UTF-8, unescaped). */
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
