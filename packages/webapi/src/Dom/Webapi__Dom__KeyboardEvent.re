type t = Dom.keyboardEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "KeyboardEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "KeyboardEvent";

[@mel.get] external altKey: t => bool = "altKey";
[@mel.get] external code: t => string = "code";
[@mel.get] external ctrlKey: t => bool = "ctrlKey";
[@mel.get] external isComposing: t => bool = "isComposing";
[@mel.get] external key: t => string = "key";
[@mel.get] external locale: t => string = "locale";
[@mel.get] external location: t => int = "location";
[@mel.get] external metaKey: t => bool = "metaKey";
[@mel.get] external repeat: t => bool = "repeat";
[@mel.get] external shiftKey: t => bool = "shiftKey";

[@mel.send.pipe: t]
external getModifierState: string /* modifierKey enum */ => bool =
  "getModifierState";
let getModifierState: (Webapi__Dom__Types.modifierKey, t) => bool =
  (key, self) =>
    getModifierState(Webapi__Dom__Types.encodeModifierKey(key), self);
