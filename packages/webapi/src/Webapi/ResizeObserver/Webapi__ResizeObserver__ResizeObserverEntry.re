type t;

[@mel.get] external contentRect: t => Dom.domRect = "contentRect";
[@mel.get] external target: t => Dom.element = "target";
