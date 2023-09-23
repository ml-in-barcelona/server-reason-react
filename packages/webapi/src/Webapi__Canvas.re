module Canvas2d = Webapi__Canvas__Canvas2d;
module WebGl = Webapi__Canvas__WebGl;

module CanvasElement = {
  [@mel.send]
  external getContext2d: (Dom.element, [@mel.as "2d"] _) => Canvas2d.t =
    "getContext";
  [@mel.send]
  external getContextWebGl: (Dom.element, [@mel.as "webgl"] _) => WebGl.glT =
    "getContext";
  [@mel.get] external height: Dom.element => int = "height";
  [@mel.set] external setHeight: (Dom.element, int) => unit = "height";
  [@mel.get] external width: Dom.element => int = "width";
  [@mel.set] external setWidth: (Dom.element, int) => unit = "width";
};
