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

let transition = (~owner, ~children, saved, operation) => {
  switch (operation) {
  | NoPatch => (saved.child, None)
  | RefreshFull(refresh) => (
      children,
      refresh.serial > saved.serial
        ? Some({
            serial: refresh.serial,
            child: children,
          })
        : None,
    )
  | ApplyPatch(patch) when String.equal(patch.graftAt, owner) => (
      patch.payload,
      patch.serial > saved.serial
        ? Some({
            serial: patch.serial,
            child: patch.payload,
          })
        : None,
    )
  | ApplyPatch(patch) => (
      saved.child,
      patch.serial > saved.serial && List.mem(owner, patch.targetLayouts)
        ? Some({
            ...saved,
            serial: patch.serial,
          })
        : None,
    )
  };
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
  let (visible, nextSaved) = transition(~owner, ~children, saved, operation);
  React.useLayoutEffect1(
    () => {
      switch (nextSaved) {
      | Some(saved) => setSaved(_ => saved)
      | None => ()
      };
      None;
    },
    [|operation|],
  );
  visible;
};
