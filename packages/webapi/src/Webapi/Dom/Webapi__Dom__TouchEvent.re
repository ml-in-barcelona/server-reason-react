type touchList; /* TODO, Touch Events */

module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external altKey: T.t => bool = "altKey";
  [@mel.get] external changedTouches: T.t => touchList = "changedTouches";
  [@mel.get] external ctrlKey: T.t => bool = "ctrlKey";
  [@mel.get] external metaKey: T.t => bool = "metaKey";
  [@mel.get] external shiftKey: T.t => bool = "shiftKey";
  [@mel.get] external targetTouches: T.t => touchList = "targetTouches";
  [@mel.get] external touches: T.t => touchList = "touches";
};

type t = Dom.touchEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Webapi__Dom__UiEvent.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "TouchEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "TouchEvent";
