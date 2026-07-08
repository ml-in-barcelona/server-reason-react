/* The SAME server function reference passed as two props. React dedups on
   the reference's identity (writtenServerReferences): one {"id","bound"}
   row, both props holding the same "$F" reference. */
let app = () => {
  let save = Spec.server_function(~id="spec/actions#save");
  Spec.client_component(
    ~importModule="spec/Form.js",
    ~importName="Form",
    ~props=[
      Spec.server_function_prop("left", save),
      Spec.server_function_prop("right", save),
    ],
    (),
  );
};
