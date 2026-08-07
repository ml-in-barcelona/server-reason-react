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
    switch (targeted, operation) {
    | (Some(patch), _) => patch.payload
    | (None, RefreshFull(_)) => children
    | (None, ApplyPatch(_))
    | (None, NoPatch) => saved.child
    };
  let nextSaved =
    switch (targeted) {
    | Some(patch) when patch.serial > saved.serial =>
      Some({
        serial: patch.serial,
        child: patch.payload,
      })
    | Some(_) => None
    | None when refreshed =>
      switch (operation) {
      | ApplyPatch(patch) when patch.serial > saved.serial =>
        Some({
          ...saved,
          serial: patch.serial,
        })
      | ApplyPatch(_) => None
      | RefreshFull(refresh) when refresh.serial > saved.serial =>
        Some({
          serial: refresh.serial,
          child: children,
        })
      | RefreshFull(_)
      | NoPatch => None
      }
    | None => None
    };
  (visible, nextSaved);
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
