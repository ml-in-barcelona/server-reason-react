switch%platform (Runtime.platform) {
| Runtime.Server => doServerSideLogic()
| Client => doClientSideLogic()
};

let value =
  switch%platform (Runtime.platform) {
  | Server => doServerSideLogic()
  | Client => doClientSideLogic()
  };

let universal_fn = () => {
  switch%platform (Runtime.platform) {
  | Server => doServerSideLogic()
  | Client => doClientSideLogic()
  };
};

let universal_fn_with_arg1 = arg1 => {
  switch%platform (Runtime.platform) {
  | Server => doServerSideLogic(arg1)
  | Client => doClientSideLogic()
  };
};
