type t = Dom.domRect;

[@mel.new]
external make: (~x: float, ~y: float, ~width: float, ~height: float) => t =
  "DOMRect"; /* experimental */

[@mel.get] external top: t => float = "top";
[@mel.get] external bottom: t => float = "bottom";
[@mel.get] external left: t => float = "left";
[@mel.get] external right: t => float = "right";
[@mel.get] external height: t => float = "height";
[@mel.get] external width: t => float = "width";
[@mel.get] external x: t => float = "x";
[@mel.get] external y: t => float = "y";
