let%melange_only gate = (name: string) => {
  let open_: string => Js.Promise.t(unit) = [%mel.raw
    {js|(name) => {
      window.routerE2eRendered = name;
      if (!window.routerE2eGate) {
        let release;
        window.routerE2eGate = new Promise((resolve) => (release = resolve));
        window.routerE2eRelease = () => release();
      }
      return window.routerE2eGate;
    }|js}
  ];
  open_(name);
};

[@react.client.component]
let make = (~name: string) => {
  switch%platform () {
  | Melange => React.Experimental.usePromise(gate(name))
  | Native => ()
  };
  React.null;
};
