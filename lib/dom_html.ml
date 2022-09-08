module Prop = struct
  include Dom_dsl_core.Prop
  include Dom_aria_attributes

  (* List of props adapted from rescript-react:
   * https://github.com/rescript-lang/rescript-react/blob/16dcbd8d079c7c20f3bd48fd677dfe7d70d0d020/src/ReactDOM.res#L51
   *)

  (* react textarea/input *)

  let defaultChecked = bool "defaultChecked"
  let defaultValue = string "defaultValue"

  (* global html attributes *)

  let accessKey = string "accessKey"
  let className = string "className" (* substitute for "class" *)
  let classNames names = className (String.concat " " names)
  let contentEditable = bool "contentEditable"
  let contextMenu = string "contextMenu"
  let dir = string "dir" (* "ltr", "rtl" or "auto" *)
  let draggable = bool "draggable"
  let hidden = bool "hidden"
  let id = string "id"
  let lang = string "lang"
  let role = string "role" (* ARIA role *)
  let style = (any "style" : Dom.Style.t -> t)
  let spellCheck = bool "spellCheck"
  let tabIndex = int "tabIndex"
  let title = string "title"

  (* html5 microdata *)

  let itemID = string "itemID"
  let itemProp = string "itemProp"
  let itemRef = string "itemRef"
  let itemScope = bool "itemScope"
  let itemType = string "itemType" (* uri *)

  (* tag-specific html attributes *)

  let accept = string "accept"
  let acceptCharset = string "acceptCharset"
  let action = string "action" (* uri *)
  let allowFullScreen = bool "allowFullScreen"
  let alt = string "alt"
  let async = bool "async"
  let autoComplete = string "autoComplete"
  (* has a fixed, but large-ish, set of possible values *)

  let autoCapitalize = string "autoCapitalize" (* Mobile Safari specific *)
  let autoFocus = bool "autoFocus"
  let autoPlay = bool "autoPlay"
  let challenge = string "challenge"
  let charSet = string "charSet"
  let checked = bool "checked"
  let cite = string "cite" (* uri *)
  let crossOrigin = string "crossOrigin" (* anonymous, use-credentials *)
  let cols = int "cols"
  let colSpan = int "colSpan"
  let content = string "content"
  let controls = bool "controls"
  let coords = string "coords"
  (* set of values specifying the coordinates of a region *)

  let data = string "data" (* uri *)
  let dateTime = string "dateTime"
  (* "valid date string with optional time" *)

  let default = bool "default"
  let defer = bool "defer"
  let disabled = bool "disabled"
  let download = string "download"
  (* should really be either a boolean, signifying presence, or a string *)

  let encType = string "encType"
  (* "application/x-www-form-urlencoded", "multipart/form-data" or "text/plain" *)

  let form = string "form"
  let formAction = string "formAction" (* uri *)
  let formTarget = string "formTarget" (* "_blank", "_self", etc. *)
  let formMethod = string "formMethod" (* "post", "get", "put" *)
  let headers = string "headers"
  let height = string "height"
  (* in html5 this can only be a number, but in html4 it can ba a percentage as well *)

  let high = int "high"
  let href = string "href" (* uri *)
  let hrefLang = string "hrefLang"
  let htmlFor = string "htmlFor" (* substitute for "for" *)
  let httpEquiv = string "httpEquiv"
  (* has a fixed set of possible values *)

  let icon = string "icon" (* uri? *)
  let inputMode = string "inputMode"
  (* "verbatim", "latin", "numeric", etc. *)

  let integrity = string "integrity"
  let keyType = string "keyType"
  let kind = string "kind" (* has a fixed set of possible values *)
  let label = string "label"
  let list = string "list"
  let loop = bool "loop"
  let low = int "low"
  let manifest = string "manifest" (* uri *)
  let max = string "max" (* should be int or Js.Date.t *)
  let maxLength = int "maxLength"
  let media = string "media" (* a valid media query *)
  let mediaGroup = string "mediaGroup"
  let method_ = string "method" (* "post" or "get", reserved keyword *)
  let min = string "min"
  let minLength = int "minLength"
  let multiple = bool "multiple"
  let muted = bool "muted"
  let name = string "name"
  let nonce = string "nonce"
  let noValidate = bool "noValidate"
  let open_ = bool "open" (* reserved keyword *)
  let optimum = int "optimum"
  let pattern = string "pattern" (* valid Js RegExp *)
  let placeholder = string "placeholder"
  let playsInline = bool "playsInline"
  let poster = string "poster" (* uri *)
  let preload = string "preload"
  (* "none", "metadata" or "auto" (and "" as a synonym for "auto") *)

  let radioGroup = string "radioGroup"
  let readOnly = bool "readOnly"
  let rel = string "rel"
  (* a space- or comma-separated (depending on the element) list of a fixed set of "link types" *)

  let required = bool "required"
  let reversed = bool "reversed"
  let rows = int "rows"
  let rowSpan = int "rowSpan"
  let sandbox = string "sandbox" (* has a fixed set of possible values *)
  let scope = string "scope" (* has a fixed set of possible values *)
  let scoped = bool "scoped"
  let scrolling = string "scrolling"
  (* html4 only, "auto", "yes" or "no" *)

  let selected = bool "selected"
  let shape = string "shape"
  let size = int "size"
  let sizes = string "sizes"
  let span = int "span"
  let src = string "src" (* uri *)
  let srcDoc = string "srcDoc"
  let srcLang = string "srcLang"
  let srcSet = string "srcSet"
  let start = int "start"
  let step = float_ "step"
  let summary = string "summary" (* deprecated *)
  let target = string "target"
  let type_ = string "type"
  (* has a fixed but large-ish set of possible values, reserved keyword *)

  let useMap = string "useMap"
  let value = string "value"
  let width = string "width"
  (* in html5 this can only be a number, but in html4 it can ba a percentage as well *)

  let wrap = string "wrap" (* "hard" or "soft" *)

  (* Clipboard events *)

  let onCopy = (event "onCopy" : (Event.Clipboard.t -> unit) -> t)
  let onCut = (event "onCut" : (Event.Clipboard.t -> unit) -> t)
  let onPaste = (event "onPaste" : (Event.Clipboard.t -> unit) -> t)

  (* Composition events *)

  let onCompositionEnd =
    (event "onCompositionEnd" : (Event.Composition.t -> unit) -> t)

  let onCompositionStart =
    (event "onCompositionStart" : (Event.Composition.t -> unit) -> t)

  let onCompositionUpdate =
    (event "onCompositionUpdate" : (Event.Composition.t -> unit) -> t)

  (* Keyboard events *)

  let onKeyDown = (event "onKeyDown" : (Event.Keyboard.t -> unit) -> t)
  let onKeyPress = (event "onKeyPress" : (Event.Keyboard.t -> unit) -> t)
  let onKeyUp = (event "onKeyUp" : (Event.Keyboard.t -> unit) -> t)

  (* Focus events *)

  let onFocus = (event "onFocus" : (Event.Focus.t -> unit) -> t)
  let onBlur = (event "onBlur" : (Event.Focus.t -> unit) -> t)

  (* Form events *)

  let onChange = (event "onChange" : (Event.Form.t -> unit) -> t)
  let onInput = (event "onInput" : (Event.Form.t -> unit) -> t)
  let onSubmit = (event "onSubmit" : (Event.Form.t -> unit) -> t)
  let onInvalid = (event "onInvalid" : (Event.Form.t -> unit) -> t)

  (* Mouse events *)

  let onClick = (event "onClick" : (Event.Mouse.t -> unit) -> t)
  let onContextMenu = (event "onContextMenu" : (Event.Mouse.t -> unit) -> t)
  let onDoubleClick = (event "onDoubleClick" : (Event.Mouse.t -> unit) -> t)
  let onDrag = (event "onDrag" : (Event.Mouse.t -> unit) -> t)
  let onDragEnd = (event "onDragEnd" : (Event.Mouse.t -> unit) -> t)
  let onDragEnter = (event "onDragEnter" : (Event.Mouse.t -> unit) -> t)
  let onDragExit = (event "onDragExit" : (Event.Mouse.t -> unit) -> t)
  let onDragLeave = (event "onDragLeave" : (Event.Mouse.t -> unit) -> t)
  let onDragOver = (event "onDragOver" : (Event.Mouse.t -> unit) -> t)
  let onDragStart = (event "onDragStart" : (Event.Mouse.t -> unit) -> t)
  let onDrop = (event "onDrop" : (Event.Mouse.t -> unit) -> t)
  let onMouseDown = (event "onMouseDown" : (Event.Mouse.t -> unit) -> t)
  let onMouseEnter = (event "onMouseEnter" : (Event.Mouse.t -> unit) -> t)
  let onMouseLeave = (event "onMouseLeave" : (Event.Mouse.t -> unit) -> t)
  let onMouseMove = (event "onMouseMove" : (Event.Mouse.t -> unit) -> t)
  let onMouseOut = (event "onMouseOut" : (Event.Mouse.t -> unit) -> t)
  let onMouseOver = (event "onMouseOver" : (Event.Mouse.t -> unit) -> t)
  let onMouseUp = (event "onMouseUp" : (Event.Mouse.t -> unit) -> t)

  (* Selection events *)

  let onSelect = (event "onSelect" : (Event.Selection.t -> unit) -> t)

  (* Touch events *)

  let onTouchCancel = (event "onTouchCancel" : (Event.Touch.t -> unit) -> t)
  let onTouchEnd = (event "onTouchEnd" : (Event.Touch.t -> unit) -> t)
  let onTouchMove = (event "onTouchMove" : (Event.Touch.t -> unit) -> t)
  let onTouchStart = (event "onTouchStart" : (Event.Touch.t -> unit) -> t)

  (* Pointer events *)

  let onPointerOver = (event "onPointerOver" : (Event.Pointer.t -> unit) -> t)
  let onPointerEnter = (event "onPointerEnter" : (Event.Pointer.t -> unit) -> t)
  let onPointerDown = (event "onPointerDown" : (Event.Pointer.t -> unit) -> t)
  let onPointerMove = (event "onPointerMove" : (Event.Pointer.t -> unit) -> t)
  let onPointerUp = (event "onPointerUp" : (Event.Pointer.t -> unit) -> t)

  let onPointerCancel =
    (event "onPointerCancel" : (Event.Pointer.t -> unit) -> t)

  let onPointerOut = (event "onPointerOut" : (Event.Pointer.t -> unit) -> t)
  let onPointerLeave = (event "onPointerLeave" : (Event.Pointer.t -> unit) -> t)

  let onGotPointerCapture =
    (event "onGotPointerCapture" : (Event.Pointer.t -> unit) -> t)

  let onLostPointerCapture =
    (event "onLostPointerCapture" : (Event.Pointer.t -> unit) -> t)

  (* UI events *)

  let onScroll = (event "onScroll" : (Event.UI.t -> unit) -> t)

  (* Wheel events *)

  let onWheel = (event "onWheel" : (Event.Wheel.t -> unit) -> t)

  (* Media events *)

  let onAbort = (event "onAbort" : (Event.Media.t -> unit) -> t)
  let onCanPlay = (event "onCanPlay" : (Event.Media.t -> unit) -> t)

  let onCanPlayThrough =
    (event "onCanPlayThrough" : (Event.Media.t -> unit) -> t)

  let onDurationChange =
    (event "onDurationChange" : (Event.Media.t -> unit) -> t)

  let onEmptied = (event "onEmptied" : (Event.Media.t -> unit) -> t)
  let onEncrypted = (event "onEncrypted" : (Event.Media.t -> unit) -> t)
  let onEnded = (event "onEnded" : (Event.Media.t -> unit) -> t)
  let onError = (event "onError" : (Event.Media.t -> unit) -> t)
  let onLoadedData = (event "onLoadedData" : (Event.Media.t -> unit) -> t)

  let onLoadedMetadata =
    (event "onLoadedMetadata" : (Event.Media.t -> unit) -> t)

  let onLoadStart = (event "onLoadStart" : (Event.Media.t -> unit) -> t)
  let onPause = (event "onPause" : (Event.Media.t -> unit) -> t)
  let onPlay = (event "onPlay" : (Event.Media.t -> unit) -> t)
  let onPlaying = (event "onPlaying" : (Event.Media.t -> unit) -> t)
  let onProgress = (event "onProgress" : (Event.Media.t -> unit) -> t)
  let onRateChange = (event "onRateChange" : (Event.Media.t -> unit) -> t)
  let onSeeked = (event "onSeeked" : (Event.Media.t -> unit) -> t)
  let onSeeking = (event "onSeeking" : (Event.Media.t -> unit) -> t)
  let onStalled = (event "onStalled" : (Event.Media.t -> unit) -> t)
  let onSuspend = (event "onSuspend" : (Event.Media.t -> unit) -> t)
  let onTimeUpdate = (event "onTimeUpdate" : (Event.Media.t -> unit) -> t)
  let onVolumeChange = (event "onVolumeChange" : (Event.Media.t -> unit) -> t)
  let onWaiting = (event "onWaiting" : (Event.Media.t -> unit) -> t)

  (* Image events *)

  let onLoad = (event "onLoad" (* duplicate *) : (Event.Image.t -> unit) -> t)

  (* Animation events *)

  let onAnimationStart =
    (event "onAnimationStart" : (Event.Animation.t -> unit) -> t)

  let onAnimationEnd =
    (event "onAnimationEnd" : (Event.Animation.t -> unit) -> t)

  let onAnimationIteration =
    (event "onAnimationIteration" : (Event.Animation.t -> unit) -> t)

  (* Transition events *)

  let onTransitionEnd =
    (event "onTransitionEnd" : (Event.Transition.t -> unit) -> t)

  (* react-specific *)

  include
    [%js:
    type html_object

    val make_react_html_object : __html:string -> html_object
      [@@js.builder] [@@js.verbatim_names]]

  let dangerouslySetInnerHTML (str : Dom.SafeString.t) =
    any "dangerouslySetInnerHTML"
      (make_react_html_object ~__html:(Dom.SafeString.to_string str))

  let suppressContentEditableWarning = bool "suppressContentEditableWarning"
end

include Prop
include Dom_dsl_core.Element
include Dom_dsl_core.Common

(* Elements *)

let a = h "a"
let abbr = h "abbr"
let address = h "address"
let area = h "area"
let article = h "article"
let aside = h "aside"
let audio = h "audio"
let b = h "b"
let base = h "base"
let bdi = h "bdi"
let bdo = h "bdo"
let big = h "big"
let blockquote = h "blockquote"
let body = h "body"
let br = h "br"
let button = h "button"
let canvas = h "canvas"
let caption = h "caption"
let cite = h "cite"
let code = h "code"
let col = h "col"
let colgroup = h "colgroup"
let data = h "data"
let datalist = h "datalist"
let dd = h "dd"
let del = h "del"
let details = h "details"
let dfn = h "dfn"
let dialog = h "dialog"
let div = h "div"
let dl = h "dl"
let dt = h "dt"
let em = h "em"
let embed = h "embed"
let fieldset = h "fieldset"
let figcaption = h "figcaption"
let figure = h "figure"
let footer = h "footer"
let form = h "form"
let h1 = h "h1"
let h2 = h "h2"
let h3 = h "h3"
let h4 = h "h4"
let h5 = h "h5"
let h6 = h "h6"
let head = h "head"
let header = h "header"
let hr = h "hr"
let html = h "html"
let i = h "i"
let iframe = h "iframe"
let img = h "img"
let input = h "input"
let ins = h "ins"
let kbd = h "kbd"
let keygen = h "keygen"
let label = h "label"
let legend = h "legend"
let li = h "li"
let link = h "link"
let main = h "main"
let map = h "map"
let mark = h "mark"
let menu = h "menu"
let menuitem = h "menuitem"
let meta = h "meta"
let meter = h "meter"
let nav = h "nav"
let noscript = h "noscript"
let object_ = h "object" (* reserved keyword *)
let ol = h "ol"
let optgroup = h "optgroup"
let option = h "option"
let output = h "output"
let p = h "p"
let param = h "param"
let picture = h "picture"
let pre = h "pre"
let progress = h "progress"
let q = h "q"
let rp = h "rp"
let rt = h "rt"
let ruby = h "ruby"
let s = h "s"
let samp = h "samp"
let script = h "script"
let section = h "section"
let select = h "select"
let small = h "small"
let source = h "source"
let span = h "span"
let strong = h "strong"
let style = h "style"
let sub = h "sub"
let summary = h "summary"
let sup = h "sup"
let table = h "table"
let tbody = h "tbody"
let td = h "td"
let textarea = h "textarea"
let tfoot = h "tfoot"
let th = h "th"
let thead = h "thead"
let time = h "time"
let title = h "title"
let tr = h "tr"
let track = h "track"
let u = h "u"
let ul = h "ul"
let var = h "var"
let video = h "video"
let wbr = h "wbr"
