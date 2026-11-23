let app = () =>
  Spec.client_component(
    ~importModule="spec/Layout.js",
    ~importName="default",
    ~props=[
      Spec.element(
        "children",
        <div>
          <h1> {React.string("Title")} </h1>
          <p> {React.string("Body")} </p>
        </div>,
      ),
    ],
    (),
  );
