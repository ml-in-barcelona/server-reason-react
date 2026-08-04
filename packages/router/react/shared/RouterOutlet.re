type patch = {
  serial: int,
  graftAt: string,
  targetLayouts: list(string),
  payload: React.element,
};

type operation =
  | NoPatch
  | RefreshFull({serial: int})
  | ApplyPatch(patch);

let context: React.Context.t(operation) = React.createContext(NoPatch);
let provider = React.Context.provider(context);

type saved = {
  serial: int,
  child: React.element,
};

[@react.client.component]
let make = (~owner: string, ~children: React.element) => {
  let operation = React.useContext(context);
  let (saved, setSaved) =
    React.useState(() =>
      {
        serial: 0,
        child: children,
      }
    );
  let targeted =
    switch (operation) {
    | ApplyPatch(patch) when String.equal(patch.graftAt, owner) =>
      Some(patch)
    | ApplyPatch(_)
    | RefreshFull(_)
    | NoPatch => None
    };
  let refreshed =
    switch (operation) {
    | ApplyPatch(patch) =>
      !String.equal(patch.graftAt, owner)
      && List.mem(owner, patch.targetLayouts)
    | RefreshFull(_) => true
    | NoPatch => false
    };
  let visible =
    switch (targeted) {
    | Some(patch) => patch.payload
    | None => refreshed ? children : saved.child
    };
  React.useLayoutEffect1(
    () => {
      switch (targeted) {
      | Some(patch) when patch.serial > saved.serial =>
        setSaved(_ =>
          {
            serial: patch.serial,
            child: patch.payload,
          }
        )
      | Some(_) => ()
      | None when refreshed =>
        switch (operation) {
        | ApplyPatch(patch) when patch.serial > saved.serial =>
          setSaved(_ =>
            {
              serial: patch.serial,
              child: children,
            }
          )
        | ApplyPatch(_) => ()
        | RefreshFull(refresh) when refresh.serial > saved.serial =>
          setSaved(_ =>
            {
              serial: refresh.serial,
              child: children,
            }
          )
        | RefreshFull(_)
        | NoPatch => ()
        }
      | None => ()
      };
      None;
    },
    [|operation|],
  );
  visible;
};
