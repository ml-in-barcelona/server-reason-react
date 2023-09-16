module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external altKey: T.t => bool = "altKey";
  [@mel.get] external button: T.t => int = "button";
  [@mel.get] external buttons: T.t => int /* bitmask */ = "buttons";
  [@mel.get] external clientX: T.t => int = "clientX";
  [@mel.get] external clientY: T.t => int = "clientY";
  [@mel.get] external ctrlKey: T.t => bool = "ctrlKey";
  [@mel.get] external metaKey: T.t => bool = "metaKey";
  [@mel.get] external movementX: T.t => int = "movementX";
  [@mel.get] external movementY: T.t => int = "movementY";
  [@mel.get] external offsetX: T.t => int = "offsetX"; /* experimental, but widely supported */
  [@mel.get] external offsetY: T.t => int = "offsetY"; /* experimental, but widely supported */
  [@mel.get] external pageX: T.t => int = "pageX"; /* experimental, but widely supported */
  [@mel.get] external pageY: T.t => int = "pageY"; /* experimental, but widely supported */
  [@mel.get] [@mel.return nullable]
  external region: T.t => option(string) = "region";
  [@mel.get] [@mel.return nullable]
  external relatedTarget: T.t => option(Dom.eventTarget) = "relatedTarget";
  [@mel.get] external screenX: T.t => int = "screenX";
  [@mel.get] external screenY: T.t => int = "screenY";
  [@mel.get] external shiftKey: T.t => bool = "shiftKey";
  [@mel.get] external x: T.t => int = "x"; /* experimental */
  [@mel.get] external y: T.t => int = "y"; /* experimental */
  [@mel.send.pipe: T.t]
  external getModifierState: string /* modifierKey enum */ => bool =
    "getModifierState";
  let getModifierState: (Webapi__Dom__Types.modifierKey, T.t) => bool =
    (key, self) =>
      getModifierState(Webapi__Dom__Types.encodeModifierKey(key), self);
};

type t = Dom.mouseEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "MouseEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "MouseEvent";
