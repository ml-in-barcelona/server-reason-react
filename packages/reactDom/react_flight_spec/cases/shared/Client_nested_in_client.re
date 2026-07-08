/* A client component element passed as a child prop of ANOTHER client
   component. The outer reference is encountered first (I row 1), the inner
   while serializing the outer's props (I row 2). */
let app = () =>
  Spec.client_component(
    ~importModule="spec/Outer.js",
    ~importName="default",
    ~props=[
      Spec.element(
        "children",
        Spec.client_component(
          ~importModule="spec/Inner.js",
          ~importName="default",
          ~props=[Spec.string("label", "nested")],
          (),
        ),
      ),
    ],
    (),
  );
