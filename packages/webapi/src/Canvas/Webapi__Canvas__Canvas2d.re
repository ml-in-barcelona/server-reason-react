type t; /* Main type, representing the 2d canvas rendering context object */
type gradient;
type pattern;
type measureText;

/* Sub-modules (and their interfaces) for string enum arguments: */
module type CompositeType = {
  type t = pri string;

  let sourceOver: t;
  let sourceIn: t;
  let sourceOut: t;
  let sourceAtop: t;
  let destinationOver: t;
  let destinationIn: t;
  let destinationOut: t;
  let destinationAtop: t;
  let lighter: t;
  let copy: t;
  let xor: t;
};

module Composite: CompositeType = {
  type t = string;

  let sourceOver: t = "source-over";
  let sourceIn: t = "source-in";
  let sourceOut: t = "source-out";
  let sourceAtop: t = "source-atop";
  let destinationOver: t = "destination-over";
  let destinationIn: t = "destination-in";
  let destinationOut: t = "destination-out";
  let destinationAtop: t = "destination-atop";
  let lighter: t = "lighter";
  let copy: t = "copy";
  let xor: t = "xor";
};

module type LineCapType = {
  type t = pri string;

  let butt: t;
  let round: t;
  let square: t;
};

module LineCap: LineCapType = {
  type t = string;

  let butt: t = "butt";
  let round: t = "round";
  let square: t = "square";
};

module type LineJoinType = {
  type t = pri string;

  let round: t;
  let bevel: t;
  let miter: t;
};

module LineJoin: LineJoinType = {
  type t = string;

  let round: t = "round";
  let bevel: t = "bevel";
  let miter: t = "miter";
};

type image('a) =
  | Number: image(float)
  | ImageData: image(Webapi__Dom__Image.t);

type style(_) =
  | String: style(string)
  | Gradient: style(gradient)
  | Pattern: style(pattern);

/* 2d Canvas API, following https://simon.html5.org/dump/html5-canvas-cheat-sheet.html */
[@mel.send.pipe: t] external save: unit = "save";
[@mel.send.pipe: t] external restore: unit = "restore";

/* Transformation */
[@mel.send.pipe: t] external scale: (~x: float, ~y: float) => unit = "scale";
[@mel.send.pipe: t] external rotate: float => unit = "rotate";
[@mel.send.pipe: t]
external translate: (~x: float, ~y: float) => unit = "translate";
[@mel.send.pipe: t]
external transform:
  (
    ~m11: float,
    ~m12: float,
    ~m21: float,
    ~m22: float,
    ~dx: float,
    ~dy: float
  ) =>
  unit =
  "transform";
[@mel.send.pipe: t]
external setTransform:
  (
    ~m11: float,
    ~m12: float,
    ~m21: float,
    ~m22: float,
    ~dx: float,
    ~dy: float
  ) =>
  unit =
  "setTransform";

/* Compositing */
[@mel.set] external globalAlpha: (t, float) => unit = "globalAlpha";
[@mel.set]
external globalCompositeOperation: (t, Composite.t) => unit =
  "globalCompositeOperation";

/* Line Styles */
[@mel.set] external lineWidth: (t, float) => unit = "lineWidth";
[@mel.set] external lineCap: (t, LineCap.t) => unit = "lineCap";
[@mel.set] external lineJoin: (t, LineJoin.t) => unit = "lineJoin";
[@mel.set] external miterLimit: (t, float) => unit = "miterLimit";

/* Colors, Styles, and Shadows */
[@mel.set] external setFillStyle: (t, 'a) => unit = "fillStyle";
[@mel.set] external setStrokeStyle: (t, 'a) => unit = "strokeStyle";

/* in re unused warnings
   awaiting release of https://github.com/bloomberg/bucklescript/issues/1656
   to just use [@@mel.set] directly with an ignored (style a) */
let setStrokeStyle = (type a, ctx: t, _: style(a), v: a) =>
  setStrokeStyle(ctx, v);

let setFillStyle = (type a, ctx: t, _: style(a), v: a) =>
  setFillStyle(ctx, v);

let reifyStyle = (type a, x: 'a): (style(a), a) => {
  let isCanvasGradient: 'a => bool = [%raw
    {|
    function(x) { return x instanceof CanvasGradient; }
  |}
  ];

  let isCanvasPattern: 'a => bool = [%raw
    {|
    function(x) { return x instanceof CanvasPattern; }
  |}
  ];

  (
    if (Js.typeof(x) == "string") {
      Obj.magic(String);
    } else if (isCanvasGradient(x)) {
      Obj.magic(Gradient);
    } else if (isCanvasPattern(x)) {
      Obj.magic(Pattern);
    } else {
      invalid_arg(
        "Unknown canvas style kind. Known values are: String, CanvasGradient, CanvasPattern",
      );
    },
    Obj.magic(x),
  );
};

[@mel.get] external fillStyle: t => 'a = "fillStyle";
[@mel.get] external strokeStyle: t => 'a = "strokeStyle";

let fillStyle = (ctx: t) => ctx |> fillStyle |> reifyStyle;

let strokeStyle = (ctx: t) => ctx |> strokeStyle |> reifyStyle;

[@mel.set] external shadowOffsetX: (t, float) => unit = "shadowOffsetX";
[@mel.set] external shadowOffsetY: (t, float) => unit = "shadowOffsetY";
[@mel.set] external shadowBlur: (t, float) => unit = "shadowBlur";
[@mel.set] external shadowColor: (t, string) => unit = "shadowColor";

/* Gradients */
[@mel.send.pipe: t]
external createLinearGradient:
  (~x0: float, ~y0: float, ~x1: float, ~y1: float) => gradient =
  "createLinearGradient";
[@mel.send.pipe: t]
external createRadialGradient:
  (~x0: float, ~y0: float, ~x1: float, ~y1: float, ~r0: float, ~r1: float) =>
  gradient =
  "createRadialGradient";
[@mel.send.pipe: gradient]
external addColorStop: (float, string) => unit = "addColorStop";
external createPattern:
  (
    t,
    Dom.element,
    [@mel.string] [
      | `repeat
      | [@mel.as "repeat-x"] `repeatX
      | [@mel.as "repeat-y"] `repeatY
      | [@mel.as "no-repeat"] `noRepeat
    ]
  ) =>
  pattern =
  "createPattern";

/* Paths */
[@mel.send.pipe: t] external beginPath: unit = "beginPath";
[@mel.send.pipe: t] external closePath: unit = "closePath";
[@mel.send.pipe: t] external fill: unit = "fill";
[@mel.send.pipe: t] external stroke: unit = "stroke";
[@mel.send.pipe: t] external clip: unit = "clip";
[@mel.send.pipe: t] external moveTo: (~x: float, ~y: float) => unit = "moveTo";
[@mel.send.pipe: t] external lineTo: (~x: float, ~y: float) => unit = "lineTo";
[@mel.send.pipe: t]
external quadraticCurveTo:
  (~cp1x: float, ~cp1y: float, ~x: float, ~y: float) => unit =
  "quadraticCurveTo";
[@mel.send.pipe: t]
external bezierCurveTo:
  (
    ~cp1x: float,
    ~cp1y: float,
    ~cp2x: float,
    ~cp2y: float,
    ~x: float,
    ~y: float
  ) =>
  unit =
  "bezierCurveTo";
[@mel.send.pipe: t]
external arcTo:
  (~x1: float, ~y1: float, ~x2: float, ~y2: float, ~r: float) => unit =
  "arcTo";
[@mel.send.pipe: t]
external arc:
  (
    ~x: float,
    ~y: float,
    ~r: float,
    ~startAngle: float,
    ~endAngle: float,
    ~anticw: bool
  ) =>
  unit =
  "arc";
[@mel.send.pipe: t]
external rect: (~x: float, ~y: float, ~w: float, ~h: float) => unit = "rect";
[@mel.send.pipe: t]
external isPointInPath: (~x: float, ~y: float) => bool = "isPointInPath";

/* Text */
[@mel.set] external font: (t, string) => unit = "font";
[@mel.set] external textAlign: (t, string) => unit = "textAlign";
[@mel.set] external textBaseline: (t, string) => unit = "textBaseline";
[@mel.send.pipe: t]
external fillText: (string, ~x: float, ~y: float, ~maxWidth: float=?) => unit =
  "fillText";
[@mel.send.pipe: t]
external strokeText: (string, ~x: float, ~y: float, ~maxWidth: float=?) => unit =
  "strokeText";
[@mel.send.pipe: t]
external measureText: string => measureText = "measureText";
[@mel.get] external width: measureText => float = "width";

/* Rectangles */
[@mel.send.pipe: t]
external fillRect: (~x: float, ~y: float, ~w: float, ~h: float) => unit =
  "fillRect";
[@mel.send.pipe: t]
external strokeRect: (~x: float, ~y: float, ~w: float, ~h: float) => unit =
  "strokeRect";
[@mel.send.pipe: t]
external clearRect: (~x: float, ~y: float, ~w: float, ~h: float) => unit =
  "clearRect";

[@mel.send]
external createImageDataCoords:
  (t, ~width: float, ~height: float) => Webapi__Dom__Image.t =
  "createImageData";
[@mel.send]
external createImageDataFromImage:
  (t, Webapi__Dom__Image.t) => Webapi__Dom__Image.t =
  "createImageData";

[@mel.send]
external getImageData:
  (t, ~sx: float, ~sy: float, ~sw: float, ~sh: float) => Webapi__Dom__Image.t =
  "getImageData";

[@mel.send]
external putImageData:
  (t, ~imageData: Webapi__Dom__Image.t, ~dx: float, ~dy: float) => unit =
  "putImageData";

[@mel.send]
external putImageDataWithDirtyRect:
  (
    t,
    ~imageData: Webapi__Dom__Image.t,
    ~dx: float,
    ~dy: float,
    ~dirtyX: float,
    ~dirtyY: float,
    ~dirtyWidth: float,
    ~dirtyHeight: float
  ) =>
  unit =
  "putImageData";
