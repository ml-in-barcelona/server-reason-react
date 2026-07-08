/* A server function as the [action] prop of a <form> host element. In the
   model direction there is no form-specific rewriting on either side: the
   action serializes like any other server-function prop ({"id","bound"} row
   + "$F" reference). */
let app = () =>
  Spec.form_with_action(
    ~action=Spec.server_function(~id="spec/actions#submit"),
    <button> {React.string("Submit")} </button>,
  );
