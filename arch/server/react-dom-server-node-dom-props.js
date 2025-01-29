var properties = {}; // These props are reserved by React. They shouldn't be written to the DOM.

var reservedProps = [
  "children",
  "dangerouslySetInnerHTML", // TODO: This prevents the assignment of defaultValue to regular
  // elements (not just inputs). Now that ReactDOMInput assigns to the
  // defaultValue property -- do we need this?
  "defaultValue",
  "defaultChecked",
  "innerHTML",
  "suppressContentEditableWarning",
  "suppressHydrationWarning",
  "style",
];

reservedProps.forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    RESERVED,
    false, // mustUseProperty
    name, // attributeName
    null, // attributeNamespace
    false
  );
}); // A few React string attributes have a different name.
// This is a mapping from React prop names to the attribute names.

[
  ["acceptCharset", "accept-charset"],
  ["className", "class"],
  ["htmlFor", "for"],
  ["httpEquiv", "http-equiv"],
].forEach(function (_ref) {
  var name = _ref[0],
    attributeName = _ref[1];
  properties[name] = new PropertyInfoRecord(
    name,
    STRING,
    false, // mustUseProperty
    attributeName, // attributeName
    null, // attributeNamespace
    false
  );
}); // These are "enumerated" HTML attributes that accept "true" and "false".
// In React, we let users pass `true` and `false` even though technically
// these aren't boolean attributes (they are coerced to strings).

["contentEditable", "draggable", "spellCheck", "value"].forEach(function (
  name
) {
  properties[name] = new PropertyInfoRecord(
    name,
    BOOLEANISH_STRING,
    false, // mustUseProperty
    name.toLowerCase(), // attributeName
    null, // attributeNamespace
    false
  );
}); // These are "enumerated" SVG attributes that accept "true" and "false".
// In React, we let users pass `true` and `false` even though technically
// these aren't boolean attributes (they are coerced to strings).
// Since these are SVG attributes, their attribute names are case-sensitive.

[
  "autoReverse",
  "externalResourcesRequired",
  "focusable",
  "preserveAlpha",
].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    BOOLEANISH_STRING,
    false, // mustUseProperty
    name, // attributeName
    null, // attributeNamespace
    false
  );
}); // These are HTML boolean attributes.

[
  "allowFullScreen",
  "async", // Note: there is a special case that prevents it from being written to the DOM
  // on the client side because the browsers are inconsistent. Instead we call focus().
  "autoFocus",
  "autoPlay",
  "controls",
  "default",
  "defer",
  "disabled",
  "disablePictureInPicture",
  "formNoValidate",
  "hidden",
  "loop",
  "noModule",
  "noValidate",
  "open",
  "playsInline",
  "readOnly",
  "required",
  "reversed",
  "scoped",
  "seamless", // Microdata
  "itemScope",
].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    BOOLEAN,
    false, // mustUseProperty
    name.toLowerCase(), // attributeName
    null, // attributeNamespace
    false
  );
}); // These are the few React props that we set as DOM properties
// rather than attributes. These are all booleans.

[
  "checked", // Note: `option.selected` is not updated if `select.multiple` is
  // disabled with `removeAttribute`. We have special logic for handling this.
  "multiple",
  "muted",
  "selected", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    BOOLEAN,
    true, // mustUseProperty
    name, // attributeName
    null, // attributeNamespace
    false
  );
}); // These are HTML attributes that are "overloaded booleans": they behave like
// booleans, but can also accept a string value.

[
  "capture",
  "download", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    OVERLOADED_BOOLEAN,
    false, // mustUseProperty
    name, // attributeName
    null, // attributeNamespace
    false
  );
}); // These are HTML attributes that must be positive numbers.

[
  "cols",
  "rows",
  "size",
  "span", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    POSITIVE_NUMERIC,
    false, // mustUseProperty
    name, // attributeName
    null, // attributeNamespace
    false
  );
}); // These are HTML attributes that must be numbers.

["rowSpan", "start"].forEach(function (name) {
  properties[name] = new PropertyInfoRecord(
    name,
    NUMERIC,
    false, // mustUseProperty
    name.toLowerCase(), // attributeName
    null, // attributeNamespace
    false
  );
});
var CAMELIZE = /[\-\:]([a-z])/g;

var capitalize = function (token) {
  return token[1].toUpperCase();
}; // This is a list of all SVG attributes that need special casing, namespacing,
// or boolean value assignment. Regular attributes that just accept strings
// and have the same names are omitted, just like in the HTML whitelist.
// Some of these attributes can be hard to find. This list was created by
// scraping the MDN documentation.

[
  "accent-height",
  "alignment-baseline",
  "arabic-form",
  "baseline-shift",
  "cap-height",
  "clip-path",
  "clip-rule",
  "color-interpolation",
  "color-interpolation-filters",
  "color-profile",
  "color-rendering",
  "dominant-baseline",
  "enable-background",
  "fill-opacity",
  "fill-rule",
  "flood-color",
  "flood-opacity",
  "font-family",
  "font-size",
  "font-size-adjust",
  "font-stretch",
  "font-style",
  "font-variant",
  "font-weight",
  "glyph-name",
  "glyph-orientation-horizontal",
  "glyph-orientation-vertical",
  "horiz-adv-x",
  "horiz-origin-x",
  "image-rendering",
  "letter-spacing",
  "lighting-color",
  "marker-end",
  "marker-mid",
  "marker-start",
  "overline-position",
  "overline-thickness",
  "paint-order",
  "panose-1",
  "pointer-events",
  "rendering-intent",
  "shape-rendering",
  "stop-color",
  "stop-opacity",
  "strikethrough-position",
  "strikethrough-thickness",
  "stroke-dasharray",
  "stroke-dashoffset",
  "stroke-linecap",
  "stroke-linejoin",
  "stroke-miterlimit",
  "stroke-opacity",
  "stroke-width",
  "text-anchor",
  "text-decoration",
  "text-rendering",
  "underline-position",
  "underline-thickness",
  "unicode-bidi",
  "unicode-range",
  "units-per-em",
  "v-alphabetic",
  "v-hanging",
  "v-ideographic",
  "v-mathematical",
  "vector-effect",
  "vert-adv-y",
  "vert-origin-x",
  "vert-origin-y",
  "word-spacing",
  "writing-mode",
  "xmlns:xlink",
  "x-height", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (attributeName) {
  var name = attributeName.replace(CAMELIZE, capitalize);
  properties[name] = new PropertyInfoRecord(
    name,
    STRING,
    false, // mustUseProperty
    attributeName,
    null, // attributeNamespace
    false
  );
}); // String SVG attributes with the xlink namespace.

[
  "xlink:actuate",
  "xlink:arcrole",
  "xlink:role",
  "xlink:show",
  "xlink:title",
  "xlink:type", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (attributeName) {
  var name = attributeName.replace(CAMELIZE, capitalize);
  properties[name] = new PropertyInfoRecord(
    name,
    STRING,
    false, // mustUseProperty
    attributeName,
    "http://www.w3.org/1999/xlink",
    false
  );
}); // String SVG attributes with the xml namespace.

[
  "xml:base",
  "xml:lang",
  "xml:space", // NOTE: if you add a camelCased prop to this list,
  // you'll need to set attributeName to name.toLowerCase()
  // instead in the assignment below.
].forEach(function (attributeName) {
  var name = attributeName.replace(CAMELIZE, capitalize);
  properties[name] = new PropertyInfoRecord(
    name,
    STRING,
    false, // mustUseProperty
    attributeName,
    "http://www.w3.org/XML/1998/namespace",
    false
  );
}); // These attribute exists both in HTML and SVG.
// The attribute name is case-sensitive in SVG so we can't just use
// the React name like we do for attributes that exist only in HTML.

["tabIndex", "crossOrigin"].forEach(function (attributeName) {
  properties[attributeName] = new PropertyInfoRecord(
    attributeName,
    STRING,
    false, // mustUseProperty
    attributeName.toLowerCase(), // attributeName
    null, // attributeNamespace
    false
  );
}); // These attributes accept URLs. These must not allow javascript: URLS.
// These will also need to accept Trusted Types object in the future.

var xlinkHref = "xlinkHref";
properties[xlinkHref] = new PropertyInfoRecord(
  "xlinkHref",
  STRING,
  false, // mustUseProperty
  "xlink:href",
  "http://www.w3.org/1999/xlink",
  true
);
["src", "href", "action", "formAction"].forEach(function (attributeName) {
  properties[attributeName] = new PropertyInfoRecord(
    attributeName,
    STRING,
    false, // mustUseProperty
    attributeName.toLowerCase(), // attributeName
    null, // attributeNamespace
    true
  );
});

/*  */

// When adding attributes to the HTML or SVG whitelist, be sure to
// also add them to this module to ensure casing and incorrect name
// warnings.
var possibleStandardNames = {
  // HTML
  accept: "accept",
  acceptcharset: "acceptCharset",
  "accept-charset": "acceptCharset",
  accesskey: "accessKey",
  action: "action",
  allowfullscreen: "allowFullScreen",
  alt: "alt",
  as: "as",
  async: "async",
  autocapitalize: "autoCapitalize",
  autocomplete: "autoComplete",
  autocorrect: "autoCorrect",
  autofocus: "autoFocus",
  autoplay: "autoPlay",
  autosave: "autoSave",
  capture: "capture",
  cellpadding: "cellPadding",
  cellspacing: "cellSpacing",
  challenge: "challenge",
  charset: "charSet",
  checked: "checked",
  children: "children",
  cite: "cite",
  class: "className",
  classid: "classID",
  classname: "className",
  cols: "cols",
  colspan: "colSpan",
  content: "content",
  contenteditable: "contentEditable",
  contextmenu: "contextMenu",
  controls: "controls",
  controlslist: "controlsList",
  coords: "coords",
  crossorigin: "crossOrigin",
  dangerouslysetinnerhtml: "dangerouslySetInnerHTML",
  data: "data",
  datetime: "dateTime",
  default: "default",
  defaultchecked: "defaultChecked",
  defaultvalue: "defaultValue",
  defer: "defer",
  dir: "dir",
  disabled: "disabled",
  disablepictureinpicture: "disablePictureInPicture",
  download: "download",
  draggable: "draggable",
  enctype: "encType",
  for: "htmlFor",
  form: "form",
  formmethod: "formMethod",
  formaction: "formAction",
  formenctype: "formEncType",
  formnovalidate: "formNoValidate",
  formtarget: "formTarget",
  frameborder: "frameBorder",
  headers: "headers",
  height: "height",
  hidden: "hidden",
  high: "high",
  href: "href",
  hreflang: "hrefLang",
  htmlfor: "htmlFor",
  httpequiv: "httpEquiv",
  "http-equiv": "httpEquiv",
  icon: "icon",
  id: "id",
  innerhtml: "innerHTML",
  inputmode: "inputMode",
  integrity: "integrity",
  is: "is",
  itemid: "itemID",
  itemprop: "itemProp",
  itemref: "itemRef",
  itemscope: "itemScope",
  itemtype: "itemType",
  keyparams: "keyParams",
  keytype: "keyType",
  kind: "kind",
  label: "label",
  lang: "lang",
  list: "list",
  loop: "loop",
  low: "low",
  manifest: "manifest",
  marginwidth: "marginWidth",
  marginheight: "marginHeight",
  max: "max",
  maxlength: "maxLength",
  media: "media",
  mediagroup: "mediaGroup",
  method: "method",
  min: "min",
  minlength: "minLength",
  multiple: "multiple",
  muted: "muted",
  name: "name",
  nomodule: "noModule",
  nonce: "nonce",
  novalidate: "noValidate",
  open: "open",
  optimum: "optimum",
  pattern: "pattern",
  placeholder: "placeholder",
  playsinline: "playsInline",
  poster: "poster",
  preload: "preload",
  profile: "profile",
  radiogroup: "radioGroup",
  readonly: "readOnly",
  referrerpolicy: "referrerPolicy",
  rel: "rel",
  required: "required",
  reversed: "reversed",
  role: "role",
  rows: "rows",
  rowspan: "rowSpan",
  sandbox: "sandbox",
  scope: "scope",
  scoped: "scoped",
  scrolling: "scrolling",
  seamless: "seamless",
  selected: "selected",
  shape: "shape",
  size: "size",
  sizes: "sizes",
  span: "span",
  spellcheck: "spellCheck",
  src: "src",
  srcdoc: "srcDoc",
  srclang: "srcLang",
  srcset: "srcSet",
  start: "start",
  step: "step",
  style: "style",
  summary: "summary",
  tabindex: "tabIndex",
  target: "target",
  title: "title",
  type: "type",
  usemap: "useMap",
  value: "value",
  width: "width",
  wmode: "wmode",
  wrap: "wrap",
  // SVG
  about: "about",
  accentheight: "accentHeight",
  "accent-height": "accentHeight",
  accumulate: "accumulate",
  additive: "additive",
  alignmentbaseline: "alignmentBaseline",
  "alignment-baseline": "alignmentBaseline",
  allowreorder: "allowReorder",
  alphabetic: "alphabetic",
  amplitude: "amplitude",
  arabicform: "arabicForm",
  "arabic-form": "arabicForm",
  ascent: "ascent",
  attributename: "attributeName",
  attributetype: "attributeType",
  autoreverse: "autoReverse",
  azimuth: "azimuth",
  basefrequency: "baseFrequency",
  baselineshift: "baselineShift",
  "baseline-shift": "baselineShift",
  baseprofile: "baseProfile",
  bbox: "bbox",
  begin: "begin",
  bias: "bias",
  by: "by",
  calcmode: "calcMode",
  capheight: "capHeight",
  "cap-height": "capHeight",
  clip: "clip",
  clippath: "clipPath",
  "clip-path": "clipPath",
  clippathunits: "clipPathUnits",
  cliprule: "clipRule",
  "clip-rule": "clipRule",
  color: "color",
  colorinterpolation: "colorInterpolation",
  "color-interpolation": "colorInterpolation",
  colorinterpolationfilters: "colorInterpolationFilters",
  "color-interpolation-filters": "colorInterpolationFilters",
  colorprofile: "colorProfile",
  "color-profile": "colorProfile",
  colorrendering: "colorRendering",
  "color-rendering": "colorRendering",
  contentscripttype: "contentScriptType",
  contentstyletype: "contentStyleType",
  cursor: "cursor",
  cx: "cx",
  cy: "cy",
  d: "d",
  datatype: "datatype",
  decelerate: "decelerate",
  descent: "descent",
  diffuseconstant: "diffuseConstant",
  direction: "direction",
  display: "display",
  divisor: "divisor",
  dominantbaseline: "dominantBaseline",
  "dominant-baseline": "dominantBaseline",
  dur: "dur",
  dx: "dx",
  dy: "dy",
  edgemode: "edgeMode",
  elevation: "elevation",
  enablebackground: "enableBackground",
  "enable-background": "enableBackground",
  end: "end",
  exponent: "exponent",
  externalresourcesrequired: "externalResourcesRequired",
  fill: "fill",
  fillopacity: "fillOpacity",
  "fill-opacity": "fillOpacity",
  fillrule: "fillRule",
  "fill-rule": "fillRule",
  filter: "filter",
  filterres: "filterRes",
  filterunits: "filterUnits",
  floodopacity: "floodOpacity",
  "flood-opacity": "floodOpacity",
  floodcolor: "floodColor",
  "flood-color": "floodColor",
  focusable: "focusable",
  fontfamily: "fontFamily",
  "font-family": "fontFamily",
  fontsize: "fontSize",
  "font-size": "fontSize",
  fontsizeadjust: "fontSizeAdjust",
  "font-size-adjust": "fontSizeAdjust",
  fontstretch: "fontStretch",
  "font-stretch": "fontStretch",
  fontstyle: "fontStyle",
  "font-style": "fontStyle",
  fontvariant: "fontVariant",
  "font-variant": "fontVariant",
  fontweight: "fontWeight",
  "font-weight": "fontWeight",
  format: "format",
  from: "from",
  fx: "fx",
  fy: "fy",
  g1: "g1",
  g2: "g2",
  glyphname: "glyphName",
  "glyph-name": "glyphName",
  glyphorientationhorizontal: "glyphOrientationHorizontal",
  "glyph-orientation-horizontal": "glyphOrientationHorizontal",
  glyphorientationvertical: "glyphOrientationVertical",
  "glyph-orientation-vertical": "glyphOrientationVertical",
  glyphref: "glyphRef",
  gradienttransform: "gradientTransform",
  gradientunits: "gradientUnits",
  hanging: "hanging",
  horizadvx: "horizAdvX",
  "horiz-adv-x": "horizAdvX",
  horizoriginx: "horizOriginX",
  "horiz-origin-x": "horizOriginX",
  ideographic: "ideographic",
  imagerendering: "imageRendering",
  "image-rendering": "imageRendering",
  in2: "in2",
  in: "in",
  inlist: "inlist",
  intercept: "intercept",
  k1: "k1",
  k2: "k2",
  k3: "k3",
  k4: "k4",
  k: "k",
  kernelmatrix: "kernelMatrix",
  kernelunitlength: "kernelUnitLength",
  kerning: "kerning",
  keypoints: "keyPoints",
  keysplines: "keySplines",
  keytimes: "keyTimes",
  lengthadjust: "lengthAdjust",
  letterspacing: "letterSpacing",
  "letter-spacing": "letterSpacing",
  lightingcolor: "lightingColor",
  "lighting-color": "lightingColor",
  limitingconeangle: "limitingConeAngle",
  local: "local",
  markerend: "markerEnd",
  "marker-end": "markerEnd",
  markerheight: "markerHeight",
  markermid: "markerMid",
  "marker-mid": "markerMid",
  markerstart: "markerStart",
  "marker-start": "markerStart",
  markerunits: "markerUnits",
  markerwidth: "markerWidth",
  mask: "mask",
  maskcontentunits: "maskContentUnits",
  maskunits: "maskUnits",
  mathematical: "mathematical",
  mode: "mode",
  numoctaves: "numOctaves",
  offset: "offset",
  opacity: "opacity",
  operator: "operator",
  order: "order",
  orient: "orient",
  orientation: "orientation",
  origin: "origin",
  overflow: "overflow",
  overlineposition: "overlinePosition",
  "overline-position": "overlinePosition",
  overlinethickness: "overlineThickness",
  "overline-thickness": "overlineThickness",
  paintorder: "paintOrder",
  "paint-order": "paintOrder",
  panose1: "panose1",
  "panose-1": "panose1",
  pathlength: "pathLength",
  patterncontentunits: "patternContentUnits",
  patterntransform: "patternTransform",
  patternunits: "patternUnits",
  pointerevents: "pointerEvents",
  "pointer-events": "pointerEvents",
  points: "points",
  pointsatx: "pointsAtX",
  pointsaty: "pointsAtY",
  pointsatz: "pointsAtZ",
  prefix: "prefix",
  preservealpha: "preserveAlpha",
  preserveaspectratio: "preserveAspectRatio",
  primitiveunits: "primitiveUnits",
  property: "property",
  r: "r",
  radius: "radius",
  refx: "refX",
  refy: "refY",
  renderingintent: "renderingIntent",
  "rendering-intent": "renderingIntent",
  repeatcount: "repeatCount",
  repeatdur: "repeatDur",
  requiredextensions: "requiredExtensions",
  requiredfeatures: "requiredFeatures",
  resource: "resource",
  restart: "restart",
  result: "result",
  results: "results",
  rotate: "rotate",
  rx: "rx",
  ry: "ry",
  scale: "scale",
  security: "security",
  seed: "seed",
  shaperendering: "shapeRendering",
  "shape-rendering": "shapeRendering",
  slope: "slope",
  spacing: "spacing",
  specularconstant: "specularConstant",
  specularexponent: "specularExponent",
  speed: "speed",
  spreadmethod: "spreadMethod",
  startoffset: "startOffset",
  stddeviation: "stdDeviation",
  stemh: "stemh",
  stemv: "stemv",
  stitchtiles: "stitchTiles",
  stopcolor: "stopColor",
  "stop-color": "stopColor",
  stopopacity: "stopOpacity",
  "stop-opacity": "stopOpacity",
  strikethroughposition: "strikethroughPosition",
  "strikethrough-position": "strikethroughPosition",
  strikethroughthickness: "strikethroughThickness",
  "strikethrough-thickness": "strikethroughThickness",
  string: "string",
  stroke: "stroke",
  strokedasharray: "strokeDasharray",
  "stroke-dasharray": "strokeDasharray",
  strokedashoffset: "strokeDashoffset",
  "stroke-dashoffset": "strokeDashoffset",
  strokelinecap: "strokeLinecap",
  "stroke-linecap": "strokeLinecap",
  strokelinejoin: "strokeLinejoin",
  "stroke-linejoin": "strokeLinejoin",
  strokemiterlimit: "strokeMiterlimit",
  "stroke-miterlimit": "strokeMiterlimit",
  strokewidth: "strokeWidth",
  "stroke-width": "strokeWidth",
  strokeopacity: "strokeOpacity",
  "stroke-opacity": "strokeOpacity",
  suppresscontenteditablewarning: "suppressContentEditableWarning",
  suppresshydrationwarning: "suppressHydrationWarning",
  surfacescale: "surfaceScale",
  systemlanguage: "systemLanguage",
  tablevalues: "tableValues",
  targetx: "targetX",
  targety: "targetY",
  textanchor: "textAnchor",
  "text-anchor": "textAnchor",
  textdecoration: "textDecoration",
  "text-decoration": "textDecoration",
  textlength: "textLength",
  textrendering: "textRendering",
  "text-rendering": "textRendering",
  to: "to",
  transform: "transform",
  typeof: "typeof",
  u1: "u1",
  u2: "u2",
  underlineposition: "underlinePosition",
  "underline-position": "underlinePosition",
  underlinethickness: "underlineThickness",
  "underline-thickness": "underlineThickness",
  unicode: "unicode",
  unicodebidi: "unicodeBidi",
  "unicode-bidi": "unicodeBidi",
  unicoderange: "unicodeRange",
  "unicode-range": "unicodeRange",
  unitsperem: "unitsPerEm",
  "units-per-em": "unitsPerEm",
  unselectable: "unselectable",
  valphabetic: "vAlphabetic",
  "v-alphabetic": "vAlphabetic",
  values: "values",
  vectoreffect: "vectorEffect",
  "vector-effect": "vectorEffect",
  version: "version",
  vertadvy: "vertAdvY",
  "vert-adv-y": "vertAdvY",
  vertoriginx: "vertOriginX",
  "vert-origin-x": "vertOriginX",
  vertoriginy: "vertOriginY",
  "vert-origin-y": "vertOriginY",
  vhanging: "vHanging",
  "v-hanging": "vHanging",
  videographic: "vIdeographic",
  "v-ideographic": "vIdeographic",
  viewbox: "viewBox",
  viewtarget: "viewTarget",
  visibility: "visibility",
  vmathematical: "vMathematical",
  "v-mathematical": "vMathematical",
  vocab: "vocab",
  widths: "widths",
  wordspacing: "wordSpacing",
  "word-spacing": "wordSpacing",
  writingmode: "writingMode",
  "writing-mode": "writingMode",
  x1: "x1",
  x2: "x2",
  x: "x",
  xchannelselector: "xChannelSelector",
  xheight: "xHeight",
  "x-height": "xHeight",
  xlinkactuate: "xlinkActuate",
  "xlink:actuate": "xlinkActuate",
  xlinkarcrole: "xlinkArcrole",
  "xlink:arcrole": "xlinkArcrole",
  xlinkhref: "xlinkHref",
  "xlink:href": "xlinkHref",
  xlinkrole: "xlinkRole",
  "xlink:role": "xlinkRole",
  xlinkshow: "xlinkShow",
  "xlink:show": "xlinkShow",
  xlinktitle: "xlinkTitle",
  "xlink:title": "xlinkTitle",
  xlinktype: "xlinkType",
  "xlink:type": "xlinkType",
  xmlbase: "xmlBase",
  "xml:base": "xmlBase",
  xmllang: "xmlLang",
  "xml:lang": "xmlLang",
  xmlns: "xmlns",
  "xml:space": "xmlSpace",
  xmlnsxlink: "xmlnsXlink",
  "xmlns:xlink": "xmlnsXlink",
  xmlspace: "xmlSpace",
  y1: "y1",
  y2: "y2",
  y: "y",
  ychannelselector: "yChannelSelector",
  z: "z",
  zoomandpan: "zoomAndPan",
};

/*  */
