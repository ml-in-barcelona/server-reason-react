/* JSON null in every model position: top-level prop, array item, object
   field. Note the asymmetry with `undefined`: React can serialize a JS
   `undefined` prop value as "$undefined", but React.Model (native) has no
   undefined constructor, so `undefined` is inexpressible single-source and
   only `null` is specced here. */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Nullable.js",
    ~importName="default",
    ~props=[
      Spec.json_null("nothing"),
      Spec.list("items", [Spec.model_null, Spec.model_string("present")]),
      Spec.object_("meta", [("missing", Spec.model_null)]),
    ],
    (),
  );
