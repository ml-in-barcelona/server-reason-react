module Meta = {
  type t = {logCalls: bool};
  let default = { logCalls: false };
};

include ReactServerDOM.FunctionReferences.Make(Meta);
