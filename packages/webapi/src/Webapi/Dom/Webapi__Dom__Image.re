type t;

[@mel.new]
external makeWithData:
  (
    ~array: Js.Typed_array.Uint8ClampedArray.t,
    ~width: float,
    ~height: float
  ) =>
  t =
  "ImageData";

[@mel.new] external make: (~width: float, ~height: float) => t = "ImageData";

[@mel.get] external data: t => Js.Typed_array.Uint8ClampedArray.t = "data";
[@mel.get] external height: t => float = "height";
[@mel.get] external width: t => float = "width";
