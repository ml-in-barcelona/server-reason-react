module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external bubbles: T.t => bool = "bubbles";
  [@mel.get] external cancelable: T.t => bool = "cancelable";
  [@mel.get] external composed: T.t => bool = "composed";
  [@mel.get] external currentTarget: T.t => Dom.eventTarget = "currentTarget";
  [@mel.get] external defaultPrevented: T.t => bool = "defaultPrevented";
  [@mel.get] external eventPhase: T.t => int = "eventPhase";

  let eventPhase: T.t => Webapi__Dom__Types.EventPhase.t = self =>
    Webapi__Dom__Types.EventPhase.decode(eventPhase(self));

  [@mel.get] external target: T.t => Dom.eventTarget = "target";
  [@mel.get] external timeStamp: T.t => float = "timeStamp";
  [@mel.get] external type_: T.t => string = "type";
  [@mel.get] external isTrusted: T.t => bool = "isTrusted";

  [@mel.send.pipe: T.t] external preventDefault: unit = "preventDefault";
  [@mel.send.pipe: T.t]
  external stopImmediatePropagation: unit = "stopImmediatePropagation";
  [@mel.send.pipe: T.t] external stopPropagation: unit = "stopPropagation";
};

type t = Dom.event;

include Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "Event";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "Event";
