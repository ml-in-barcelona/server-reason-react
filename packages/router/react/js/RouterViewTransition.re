type direction =
  | Push
  | Replace
  | Back
  | Forward;

let directionName = direction =>
  switch (direction) {
  | Push => "push"
  | Replace => "replace"
  | Back => "back"
  | Forward => "forward"
  };

type transition;
type document;
type element;

external document: document = "document";
[@mel.get] external documentElement: document => element = "documentElement";
[@mel.send]
external setAttribute: (element, string, string) => unit = "setAttribute";
[@mel.send]
external removeAttribute: (element, string) => unit = "removeAttribute";
[@mel.send]
external startViewTransition: (document, unit => unit) => transition =
  "startViewTransition";
[@mel.send] external skipTransition: transition => unit = "skipTransition";
[@mel.get] external ready: transition => Js.Promise.t(unit) = "ready";
[@mel.get] external finished: transition => Js.Promise.t(unit) = "finished";

let supported: unit => bool = [%mel.raw
  {|() => typeof document !== "undefined" && typeof document.startViewTransition === "function"|}
];

let attribute = "data-router-nav";

type t = {
  mutable generation: int,
  mutable active: option(transition),
};

let make = () => {
  generation: 0,
  active: None,
};

let supersede = state => {
  state.generation = state.generation + 1;
  switch (state.active) {
  | Some(transition) =>
    state.active = None;
    removeAttribute(documentElement(document), attribute);
    skipTransition(transition);
  | None => ()
  };
};

let run = (state, ~enabled, ~direction, update) =>
  if (!enabled || !supported()) {
    update();
  } else {
    supersede(state);
    let generation = state.generation;
    let current = () => state.generation == generation;
    let root = documentElement(document);
    setAttribute(root, attribute, directionName(direction));
    let transition =
      startViewTransition(document, () =>
        if (current()) {
          try(update()) {
          | error =>
            let _ = Js.Global.setTimeout(~f=() => raise(error), 0);
            ();
          };
        }
      );
    state.active = Some(transition);
    let settle = _ => {
      if (current()) {
        state.active = None;
        removeAttribute(root, attribute);
      };
      Js.Promise.resolve();
    };
    let _ = ready(transition) |> Js.Promise.catch(_ => Js.Promise.resolve());
    let _ =
      finished(transition)
      |> Js.Promise.then_(settle)
      |> Js.Promise.catch(settle);
    ();
  };
