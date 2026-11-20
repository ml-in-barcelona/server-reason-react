module Meta: {
  type t = {logCalls: bool};
  let default: t;
};

include ReactServerDOM.FunctionReferences with type meta = Meta.t;
