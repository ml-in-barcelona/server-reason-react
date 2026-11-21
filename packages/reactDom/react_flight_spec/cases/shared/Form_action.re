let app = () =>
  Spec.form_with_action(
    ~action=Spec.server_function(~id="spec/actions#submit"),
    <button> {React.string("Submit")} </button>,
  );
