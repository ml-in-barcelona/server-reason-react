/* Array and nested-object props on a client component. Native builds
   React.Model.List/Assoc; melange builds plain JS arrays/objects. JSON key
   order must follow insertion order on both sides. */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Table.js",
    ~importName="default",
    ~props=[
      Spec.list(
        "tags",
        [
          Spec.model_string("alpha"),
          Spec.model_int(2),
          Spec.model_bool(false),
          Spec.model_null,
        ],
      ),
      Spec.object_(
        "user",
        [
          ("name", Spec.model_string("Ada")),
          ("age", Spec.model_int(36)),
          (
            "address",
            Spec.model_object([
              ("city", Spec.model_string("London")),
              ("zip", Spec.model_null),
            ]),
          ),
          (
            "scores",
            Spec.model_list([Spec.model_float(1.5), Spec.model_int(2)]),
          ),
        ],
      ),
    ],
    (),
  );
