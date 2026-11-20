module FunctionReferences =
  ReactServerDOM.FunctionReferences.Make({
    type t = unit;
    let default = ();
  });


[@react.server.function]
let withTwoFormData =
    (country: string, a: Js.FormData.t, b: Js.FormData.t)
    : Js.Promise.t(string) => {
  let _ = (a, b);
  Lwt.return(country);
};
