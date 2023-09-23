type t = Dom.relatedEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "RelatedEvent";
[@mel.new]
external makeWithOptions: (string, Js.t({..})) => t = "RelatedEvent";

[@mel.get] [@mel.return nullable]
external relatedTarget: t => option(Dom.eventTarget) = "relatedTarget";
