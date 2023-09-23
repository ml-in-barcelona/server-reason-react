module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external detail: T.t => int = "detail";
  [@mel.get] external view: T.t => Dom.window = "view"; /* technically returns a `WindowProxy` */
};

type t = Dom.uiEvent;

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});
include Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "UIEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "UIEvent";
