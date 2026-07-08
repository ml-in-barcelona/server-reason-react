/* A client component with element children: "children" is a prop like any
   other, so server-rendered elements cross the boundary inside the props
   object of the client reference element. */
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
