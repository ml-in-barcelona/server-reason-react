[@@@ocamlformat "disable"]

type attributeType =
  | Action
  | String
  | Int
  | Float
  | Bool
  | BooleanishString
  | Style
  | Ref
  | InnerHtml

type eventType =
  | Clipboard
  | Composition
  | Keyboard
  | Focus
  | Form
  | Mouse
  | Selection
  | Touch
  | UI
  | Wheel
  | Media
  | Image
  | Animation
  | Transition
  | Pointer
  | Inline
  | Drag

type attribute = {
  type_ : attributeType;
  name : string;
  jsxName : string;
  reasonJsxName : string;
}

type event = {
  type_ : eventType;
  jsxName : string;
}

type prop =
  | Attribute of attribute
  | Event of event

type element = {
  tag : string;
  attributes : prop list;
}

let attributeReferrerPolicy = String

let attributeAnchorTarget = String

let globalEventHandlers =
  [
    Event { jsxName = "onCopy"; type_ = Clipboard };
    Event { jsxName = "onCopyCapture"; type_ = Clipboard };
    Event { jsxName = "onCut"; type_ = Clipboard };
    Event { jsxName = "onCutCapture"; type_ = Clipboard };
    Event { jsxName = "onPaste"; type_ = Clipboard };
    Event { jsxName = "onPasteCapture"; type_ = Clipboard };
    Event { jsxName = "onCompositionEnd"; type_ = Composition };
    Event { jsxName = "onCompositionEndCapture"; type_ = Composition };
    Event { jsxName = "onCompositionStart"; type_ = Composition };
    Event { jsxName = "onCompositionStartCapture"; type_ = Composition };
    Event { jsxName = "onCompositionUpdate"; type_ = Composition };
    Event { jsxName = "onCompositionUpdateCapture"; type_ = Composition };
    Event { jsxName = "onFocus"; type_ = Focus };
    Event { jsxName = "onFocusCapture"; type_ = Focus };
    Event { jsxName = "onBlur"; type_ = Focus };
    Event { jsxName = "onBlurCapture"; type_ = Focus };
    Event { jsxName = "onChange"; type_ = Form };
    Event { jsxName = "onChangeCapture"; type_ = Form };
    Event { jsxName = "onBeforeInput"; type_ = Form };
    Event { jsxName = "onBeforeInputCapture"; type_ = Form };
    Event { jsxName = "onInput"; type_ = Form };
    Event { jsxName = "onInputCapture"; type_ = Form };
    Event { jsxName = "onReset"; type_ = Form };
    Event { jsxName = "onResetCapture"; type_ = Form };
    Event { jsxName = "onSubmit"; type_ = Form };
    Event { jsxName = "onSubmitCapture"; type_ = Form };
    Event { jsxName = "onInvalid"; type_ = Form };
    Event { jsxName = "onInvalidCapture"; type_ = Form };
    Event { jsxName = "onLoad"; type_ = Media };
    Event { jsxName = "onLoadCapture"; type_ = Media };
    Event { jsxName = "onError"; type_ = Media };
    Event { jsxName = "onErrorCapture"; type_ = Media };
    Event { jsxName = "onKeyDown"; type_ = Keyboard };
    Event { jsxName = "onKeyDownCapture"; type_ = Keyboard };
    Event { jsxName = "onKeyPress"; type_ = Keyboard };
    Event { jsxName = "onKeyPressCapture"; type_ = Keyboard };
    Event { jsxName = "onKeyUp"; type_ = Keyboard };
    Event { jsxName = "onKeyUpCapture"; type_ = Keyboard };
    Event { jsxName = "onAbort"; type_ = Media };
    Event { jsxName = "onAbortCapture"; type_ = Media };
    Event { jsxName = "onCanPlay"; type_ = Media };
    Event { jsxName = "onCanPlayCapture"; type_ = Media };
    Event { jsxName = "onCanPlayThrough"; type_ = Media };
    Event { jsxName = "onCanPlayThroughCapture"; type_ = Media };
    Event { jsxName = "onDurationChange"; type_ = Media };
    Event { jsxName = "onDurationChangeCapture"; type_ = Media };
    Event { jsxName = "onEmptied"; type_ = Media };
    Event { jsxName = "onEmptiedCapture"; type_ = Media };
    Event { jsxName = "onEncrypted"; type_ = Media };
    Event { jsxName = "onEncryptedCapture"; type_ = Media };
    Event { jsxName = "onEnded"; type_ = Media };
    Event { jsxName = "onEndedCapture"; type_ = Media };
    Event { jsxName = "onLoadedData"; type_ = Media };
    Event { jsxName = "onLoadedDataCapture"; type_ = Media };
    Event { jsxName = "onLoadedMetadata"; type_ = Media };
    Event { jsxName = "onLoadedMetadataCapture"; type_ = Media };
    Event { jsxName = "onLoadStart"; type_ = Media };
    Event { jsxName = "onLoadStartCapture"; type_ = Media };
    Event { jsxName = "onPause"; type_ = Media };
    Event { jsxName = "onPauseCapture"; type_ = Media };
    Event { jsxName = "onPlay"; type_ = Media };
    Event { jsxName = "onPlayCapture"; type_ = Media };
    Event { jsxName = "onPlaying"; type_ = Media };
    Event { jsxName = "onPlayingCapture"; type_ = Media };
    Event { jsxName = "onProgress"; type_ = Media };
    Event { jsxName = "onProgressCapture"; type_ = Media };
    Event { jsxName = "onRateChange"; type_ = Media };
    Event { jsxName = "onRateChangeCapture"; type_ = Media };
    Event { jsxName = "onSeeked"; type_ = Media };
    Event { jsxName = "onSeekedCapture"; type_ = Media };
    Event { jsxName = "onSeeking"; type_ = Media };
    Event { jsxName = "onSeekingCapture"; type_ = Media };
    Event { jsxName = "onStalled"; type_ = Media };
    Event { jsxName = "onStalledCapture"; type_ = Media };
    Event { jsxName = "onSuspend"; type_ = Media };
    Event { jsxName = "onSuspendCapture"; type_ = Media };
    Event { jsxName = "onTimeUpdate"; type_ = Media };
    Event { jsxName = "onTimeUpdateCapture"; type_ = Media };
    Event { jsxName = "onVolumeChange"; type_ = Media };
    Event { jsxName = "onVolumeChangeCapture"; type_ = Media };
    Event { jsxName = "onWaiting"; type_ = Media };
    Event { jsxName = "onWaitingCapture"; type_ = Media };
    Event { jsxName = "onAuxClick"; type_ = Mouse };
    Event { jsxName = "onAuxClickCapture"; type_ = Mouse };
    Event { jsxName = "onClick"; type_ = Mouse };
    Event { jsxName = "onClickCapture"; type_ = Mouse };
    Event { jsxName = "onContextMenu"; type_ = Mouse };
    Event { jsxName = "onContextMenuCapture"; type_ = Mouse };
    Event { jsxName = "onDoubleClick"; type_ = Mouse };
    Event { jsxName = "onDoubleClickCapture"; type_ = Mouse };
    Event { jsxName = "onDrag"; type_ = Drag };
    Event { jsxName = "onDragCapture"; type_ = Drag };
    Event { jsxName = "onDragEnd"; type_ = Drag };
    Event { jsxName = "onDragEndCapture"; type_ = Drag };
    Event { jsxName = "onDragEnter"; type_ = Drag };
    Event { jsxName = "onDragEnterCapture"; type_ = Drag };
    Event { jsxName = "onDragExit"; type_ = Drag };
    Event { jsxName = "onDragExitCapture"; type_ = Drag };
    Event { jsxName = "onDragLeave"; type_ = Drag };
    Event { jsxName = "onDragLeaveCapture"; type_ = Drag };
    Event { jsxName = "onDragOver"; type_ = Drag };
    Event { jsxName = "onDragOverCapture"; type_ = Drag };
    Event { jsxName = "onDragStart"; type_ = Drag };
    Event { jsxName = "onDragStartCapture"; type_ = Drag };
    Event { jsxName = "onDrop"; type_ = Drag };
    Event { jsxName = "onDropCapture"; type_ = Drag };
    Event { jsxName = "onMouseDown"; type_ = Mouse };
    Event { jsxName = "onMouseDownCapture"; type_ = Mouse };
    Event { jsxName = "onMouseEnter"; type_ = Mouse };
    Event { jsxName = "onMouseLeave"; type_ = Mouse };
    Event { jsxName = "onMouseMove"; type_ = Mouse };
    Event { jsxName = "onMouseMoveCapture"; type_ = Mouse };
    Event { jsxName = "onMouseOut"; type_ = Mouse };
    Event { jsxName = "onMouseOutCapture"; type_ = Mouse };
    Event { jsxName = "onMouseOver"; type_ = Mouse };
    Event { jsxName = "onMouseOverCapture"; type_ = Mouse };
    Event { jsxName = "onMouseUp"; type_ = Mouse };
    Event { jsxName = "onMouseUpCapture"; type_ = Mouse };
    Event { jsxName = "onSelect"; type_ = Selection };
    Event { jsxName = "onSelectCapture"; type_ = Selection };
    Event { jsxName = "onTouchCancel"; type_ = Touch };
    Event { jsxName = "onTouchCancelCapture"; type_ = Touch };
    Event { jsxName = "onTouchEnd"; type_ = Touch };
    Event { jsxName = "onTouchEndCapture"; type_ = Touch };
    Event { jsxName = "onTouchMove"; type_ = Touch };
    Event { jsxName = "onTouchMoveCapture"; type_ = Touch };
    Event { jsxName = "onTouchStart"; type_ = Touch };
    Event { jsxName = "onTouchStartCapture"; type_ = Touch };
    Event { jsxName = "onPointerDown"; type_ = Pointer };
    Event { jsxName = "onPointerDownCapture"; type_ = Pointer };
    Event { jsxName = "onPointerMove"; type_ = Pointer };
    Event { jsxName = "onPointerMoveCapture"; type_ = Pointer };
    Event { jsxName = "onPointerUp"; type_ = Pointer };
    Event { jsxName = "onPointerUpCapture"; type_ = Pointer };
    Event { jsxName = "onPointerCancel"; type_ = Pointer };
    Event { jsxName = "onPointerCancelCapture"; type_ = Pointer };
    Event { jsxName = "onPointerEnter"; type_ = Pointer };
    Event { jsxName = "onPointerEnterCapture"; type_ = Pointer };
    Event { jsxName = "onPointerLeave"; type_ = Pointer };
    Event { jsxName = "onPointerLeaveCapture"; type_ = Pointer };
    Event { jsxName = "onPointerOver"; type_ = Pointer };
    Event { jsxName = "onPointerOverCapture"; type_ = Pointer };
    Event { jsxName = "onPointerOut"; type_ = Pointer };
    Event { jsxName = "onPointerOutCapture"; type_ = Pointer };
    Event { jsxName = "onGotPointerCapture"; type_ = Pointer };
    Event { jsxName = "onGotPointerCaptureCapture"; type_ = Pointer };
    Event { jsxName = "onLostPointerCapture"; type_ = Pointer };
    Event { jsxName = "onLostPointerCaptureCapture"; type_ = Pointer };
    Event { jsxName = "onScroll"; type_ = UI };
    Event { jsxName = "onScrollCapture"; type_ = UI };
    Event { jsxName = "onWheel"; type_ = Wheel };
    Event { jsxName = "onWheelCapture"; type_ = Wheel };
    Event { jsxName = "onAnimationStart"; type_ = Animation };
    Event { jsxName = "onAnimationStartCapture"; type_ = Animation };
    Event { jsxName = "onAnimationEnd"; type_ = Animation };
    Event { jsxName = "onAnimationEndCapture"; type_ = Animation };
    Event { jsxName = "onAnimationIteration"; type_ = Animation };
    Event { jsxName = "onAnimationIterationCapture"; type_ = Animation };
    Event { jsxName = "onTransitionEnd"; type_ = Transition };
    Event { jsxName = "onTransitionEndCapture"; type_ = Transition };
  ]

let ariaAttributes =
  [
    Attribute { name = "aria-activedescendant"; jsxName = "aria-activedescendant"; reasonJsxName = "ariaActivedescendant"; type_ = String };
    Attribute { name = "aria-atomic"; jsxName = "aria-atomic"; reasonJsxName = "ariaAtomic"; type_ = BooleanishString };
    Attribute { name = "aria-autocomplete"; jsxName = "aria-autocomplete"; reasonJsxName = "ariaAutocomplete"; type_ = String };
    Attribute { name = "aria-busy"; jsxName = "aria-busy"; reasonJsxName = "ariaBusy"; type_ = BooleanishString };
    Attribute { name = "aria-checked"; jsxName = "aria-checked"; reasonJsxName = "ariaChecked"; type_ = String };
    Attribute { name = "aria-colcount"; jsxName = "aria-colcount"; reasonJsxName = "ariaColcount"; type_ = Int };
    Attribute { name = "aria-colindex"; jsxName = "aria-colindex"; reasonJsxName = "ariaColindex"; type_ = Int };
    Attribute { name = "aria-colspan"; jsxName = "aria-colspan"; reasonJsxName = "ariaColspan"; type_ = Int };
    Attribute { name = "aria-controls"; jsxName = "aria-controls"; reasonJsxName = "ariaControls"; type_ = String };
    Attribute { name = "aria-current"; jsxName = "aria-current"; reasonJsxName = "ariaCurrent"; type_ = String };
    Attribute { name = "aria-describedby"; jsxName = "aria-describedby"; reasonJsxName = "ariaDescribedby"; type_ = String };
    Attribute { name = "aria-details"; jsxName = "aria-details"; reasonJsxName = "ariaDetails"; type_ = String };
    Attribute { name = "aria-disabled"; jsxName = "aria-disabled"; reasonJsxName = "ariaDisabled"; type_ = BooleanishString };
    Attribute { name = "aria-errormessage"; jsxName = "aria-errormessage"; reasonJsxName = "ariaErrormessage"; type_ = String };
    Attribute { name = "aria-expanded"; jsxName = "aria-expanded"; reasonJsxName = "ariaExpanded"; type_ = BooleanishString };
    Attribute { name = "aria-flowto"; jsxName = "aria-flowto"; reasonJsxName = "ariaFlowto"; type_ = String };
    Attribute { name = "aria-haspopup"; jsxName = "aria-haspopup"; reasonJsxName = "ariaHaspopup"; type_ = String };
    Attribute { name = "aria-hidden"; jsxName = "aria-hidden"; reasonJsxName = "ariaHidden"; type_ = BooleanishString };
    Attribute { name = "aria-invalid"; jsxName = "aria-invalid"; reasonJsxName = "ariaInvalid"; type_ = String };
    Attribute { name = "aria-keyshortcuts"; jsxName = "aria-keyshortcuts"; reasonJsxName = "ariaKeyshortcuts"; type_ = String };
    Attribute { name = "aria-label"; jsxName = "aria-label"; reasonJsxName = "ariaLabel"; type_ = String };
    Attribute { name = "aria-labelledby"; jsxName = "aria-labelledby"; reasonJsxName = "ariaLabelledby"; type_ = String };
    Attribute { name = "aria-level"; jsxName = "aria-level"; reasonJsxName = "ariaLevel"; type_ = Int };
    Attribute { name = "aria-live"; jsxName = "aria-live"; reasonJsxName = "ariaLive"; type_ = String };
    Attribute { name = "aria-modal"; jsxName = "aria-modal"; reasonJsxName = "ariaModal"; type_ = BooleanishString };
    Attribute { name = "aria-multiline"; jsxName = "aria-multiline"; reasonJsxName = "ariaMultiline"; type_ = BooleanishString };
    Attribute { name = "aria-multiselectable"; jsxName = "aria-multiselectable"; reasonJsxName = "ariaMultiselectable"; type_ = BooleanishString };
    Attribute { name = "aria-orientation"; jsxName = "aria-orientation"; reasonJsxName = "ariaOrientation"; type_ = String };
    Attribute { name = "aria-owns"; jsxName = "aria-owns"; reasonJsxName = "ariaOwns"; type_ = String };
    Attribute { name = "aria-placeholder"; jsxName = "aria-placeholder"; reasonJsxName = "ariaPlaceholder"; type_ = String };
    Attribute { name = "aria-posinset"; jsxName = "aria-posinset"; reasonJsxName = "ariaPosinset"; type_ = Int };
    Attribute { name = "aria-pressed"; jsxName = "aria-pressed"; reasonJsxName = "ariaPressed"; type_ = String };
    Attribute { name = "aria-readonly"; jsxName = "aria-readonly"; reasonJsxName = "ariaReadonly"; type_ = BooleanishString };
    Attribute { name = "aria-relevant"; jsxName = "aria-relevant"; reasonJsxName = "ariaRelevant"; type_ = String };
    Attribute { name = "aria-required"; jsxName = "aria-required"; reasonJsxName = "ariaRequired"; type_ = BooleanishString };
    Attribute { name = "aria-roledescription"; jsxName = "aria-roledescription"; reasonJsxName = "ariaRoledescription"; type_ = String };
    Attribute { name = "aria-rowcount"; jsxName = "aria-rowcount"; reasonJsxName = "ariaRowcount"; type_ = Int };
    Attribute { name = "aria-rowindex"; jsxName = "aria-rowindex"; reasonJsxName = "ariaRowindex"; type_ = Int };
    Attribute { name = "aria-rowindextext"; jsxName = "aria-rowindextext"; reasonJsxName = "ariaRowindextext"; type_ = String };
    Attribute { name = "aria-rowspan"; jsxName = "aria-rowspan"; reasonJsxName = "ariaRowspan"; type_ = Int };
    Attribute { name = "aria-selected"; jsxName = "aria-selected"; reasonJsxName = "ariaSelected"; type_ = BooleanishString };
    Attribute { name = "aria-setsize"; jsxName = "aria-setsize"; reasonJsxName = "ariaSetsize"; type_ = Int };
    Attribute { name = "aria-sort"; jsxName = "aria-sort"; reasonJsxName = "ariaSort"; type_ = String };
    Attribute { name = "aria-valuemax"; jsxName = "aria-valuemax"; reasonJsxName = "ariaValuemax"; type_ = Float };
    Attribute { name = "aria-valuemin"; jsxName = "aria-valuemin"; reasonJsxName = "ariaValuemin"; type_ = Float };
    Attribute { name = "aria-valuenow"; jsxName = "aria-valuenow"; reasonJsxName = "ariaValuenow"; type_ = Float };
    Attribute { name = "aria-valuetext"; jsxName = "aria-valuetext"; reasonJsxName = "ariaValuetext"; type_ = String };
  ]

let ariaRole = String

let reactAttributes =
  [
    Attribute { name = "class"; jsxName = "className"; reasonJsxName = "className"; type_ = String };
    Attribute { name = "checked"; jsxName = "defaultChecked"; reasonJsxName = "defaultChecked"; type_ = Bool };
    Attribute { name = "value"; jsxName = "defaultValue"; reasonJsxName = "defaultValue"; type_ = String };
    Attribute { name = "dangerouslySetInnerHTML"; jsxName = "dangerouslySetInnerHTML"; reasonJsxName = "dangerouslySetInnerHTML"; type_ = InnerHtml };
    Attribute { name = "ref"; jsxName = "ref"; reasonJsxName = "ref"; type_ = Ref };
    Attribute { name = "key"; jsxName = "key"; reasonJsxName = "key"; type_ = String };
    Attribute { name = "suppressContentEditableWarning"; jsxName = "suppressContentEditableWarning"; reasonJsxName = "suppressContentEditableWarning"; type_ = Bool };
    Attribute { name = "suppressHydrationWarning"; jsxName = "suppressHydrationWarning"; reasonJsxName = "suppressHydrationWarning"; type_ = Bool };
  ]

let globalAttributes =
  [
    Attribute { name = "accesskey"; jsxName = "accessKey"; reasonJsxName = "accessKey"; type_ = String };
    Attribute { name = "autocapitalize"; jsxName = "autoCapitalize"; reasonJsxName = "autoCapitalize"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "contextmenu"; jsxName = "contextMenu"; reasonJsxName = "contextMenu"; type_ = String };
    Attribute { name = "contenteditable"; jsxName = "contentEditable"; reasonJsxName = "contentEditable"; type_ = BooleanishString };
    Attribute { name = "dir"; jsxName = "dir"; reasonJsxName = "dir"; type_ = String };
    Attribute { name = "draggable"; jsxName = "draggable"; reasonJsxName = "draggable"; type_ = BooleanishString };
    Attribute { name = "hidden"; jsxName = "hidden"; reasonJsxName = "hidden"; type_ = Bool };
    Attribute { name = "id"; jsxName = "id"; reasonJsxName = "id"; type_ = String };
    Attribute { name = "itemprop"; jsxName = "itemProp"; reasonJsxName = "itemProp"; type_ = String };
    Attribute { name = "itemscope"; jsxName = "itemScope"; reasonJsxName = "itemScope"; type_ = Bool };
    Attribute { name = "itemtype"; jsxName = "itemType"; reasonJsxName = "itemType"; type_ = String };
    Attribute { name = "itemid"; jsxName = "itemID"; reasonJsxName = "itemID"; type_ = String };
    Attribute { name = "itemref"; jsxName = "itemRef"; reasonJsxName = "itemRef"; type_ = String };
    Attribute { name = "lang"; jsxName = "lang"; reasonJsxName = "lang"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; reasonJsxName = "placeholder"; type_ = String };
    Attribute { name = "part"; jsxName = "part"; reasonJsxName = "part"; type_ = String };
    Attribute { name = "nonce"; jsxName = "nonce"; reasonJsxName = "nonce"; type_ = String };
    Attribute { name = "slot"; jsxName = "slot"; reasonJsxName = "slot"; type_ = String };
    Attribute { name = "spellcheck"; jsxName = "spellCheck"; reasonJsxName = "spellCheck"; type_ = BooleanishString };
    Attribute { name = "style"; jsxName = "style"; reasonJsxName = "style"; type_ = Style };
    Attribute { name = "tabindex"; jsxName = "tabIndex"; reasonJsxName = "tabIndex"; type_ = Int };
    Attribute { name = "enterkeyhint"; jsxName = "enterKeyHint"; reasonJsxName = "enterKeyHint"; type_ = Int };
    Attribute { name = "title"; jsxName = "title"; reasonJsxName = "title"; type_ = String };
    Attribute { name = "translate"; jsxName = "translate"; reasonJsxName = "translate"; type_ = String };

    Attribute { name = "inputmode"; jsxName = "inputMode"; reasonJsxName = "inputMode"; type_ = String };

    Attribute { name = "is"; jsxName = "is"; reasonJsxName = "is"; type_ = String };
  ]

let elementAttributes =
  [
    Attribute { name = "role"; jsxName = "role"; reasonJsxName = "role"; type_ = ariaRole };

    Attribute { name = "about"; jsxName = "about"; reasonJsxName = "about"; type_ = String };
    Attribute { name = "inlist"; jsxName = "inlist"; reasonJsxName = "inlist"; type_ = String };
    Attribute { name = "prefix"; jsxName = "prefix"; reasonJsxName = "prefix"; type_ = String };
    Attribute { name = "property"; jsxName = "property"; reasonJsxName = "property"; type_ = String };
    Attribute { name = "resource"; jsxName = "resource"; reasonJsxName = "resource"; type_ = String };
    Attribute { name = "typeof"; jsxName = "typeof"; reasonJsxName = "typeof"; type_ = String };
    Attribute { name = "vocab"; jsxName = "vocab"; reasonJsxName = "vocab"; type_ = String };

    Attribute { name = "autocorrect"; jsxName = "autoCorrect"; reasonJsxName = "autoCorrect"; type_ = String };
    Attribute { name = "autosave"; jsxName = "autoSave"; reasonJsxName = "autoSave"; type_ = String };
    Attribute { name = "color"; jsxName = "color"; reasonJsxName = "color"; type_ = String };
    Attribute { name = "results"; jsxName = "results"; reasonJsxName = "results"; type_ = Int };
    Attribute { name = "security"; jsxName = "security"; reasonJsxName = "security"; type_ = String };
  ]

let anchorHTMLAttributes =
  [
    Attribute { name = "download"; jsxName = "download"; reasonJsxName = "download"; type_ = String };
    Attribute { name = "href"; jsxName = "href"; reasonJsxName = "href"; type_ = String };
    Attribute { name = "hrefLang"; jsxName = "hrefLang"; reasonJsxName = "hrefLang"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
    Attribute { name = "ping"; jsxName = "ping"; reasonJsxName = "ping"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; reasonJsxName = "rel"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; reasonJsxName = "target"; type_ = attributeAnchorTarget };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; reasonJsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
  ]

let areaHTMLAttributes =
  [
    Attribute { name = "alt"; jsxName = "alt"; reasonJsxName = "alt"; type_ = String };
    Attribute { name = "coords"; jsxName = "coords"; reasonJsxName = "coords"; type_ = String };
    Attribute { name = "download"; jsxName = "download"; reasonJsxName = "download"; type_ = String };
    Attribute { name = "href"; jsxName = "href"; reasonJsxName = "href"; type_ = String };
    Attribute { name = "hreflang"; jsxName = "hrefLang"; reasonJsxName = "hrefLang"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; reasonJsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
    Attribute { name = "rel"; jsxName = "rel"; reasonJsxName = "rel"; type_ = String };
    Attribute { name = "shape"; jsxName = "shape"; reasonJsxName = "shape"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; reasonJsxName = "target"; type_ = String };
  ]

let baseHTMLAttributes =
  [
    Attribute { name = "href"; jsxName = "href"; reasonJsxName = "href"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; reasonJsxName = "target"; type_ = String };
  ]

let blockquoteHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; reasonJsxName = "cite"; type_ = String };
  ]

let buttonHTMLAttributes =
  [
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; reasonJsxName = "autoComplete"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "formaction"; jsxName = "formAction"; reasonJsxName = "formAction"; type_ = Action };
    Attribute { name = "formenctype"; jsxName = "formEncType"; reasonJsxName = "formEncType"; type_ = String };
    Attribute { name = "formmethod"; jsxName = "formMethod"; reasonJsxName = "formMethod"; type_ = String };
    Attribute { name = "formnovalidate"; jsxName = "formNoValidate"; reasonJsxName = "formNoValidate"; type_ = Bool };
    Attribute { name = "formtarget"; jsxName = "formTarget"; reasonJsxName = "formTarget"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "popovertarget"; jsxName = "popoverTarget"; reasonJsxName = "popoverTarget"; type_ = String };
    Attribute { name = "popovertargetaction"; jsxName = "popoverTargetAction"; reasonJsxName = "popoverTargetAction"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
  ]

let canvasHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String }
  ]

let colHTMLAttributes =
  [
    Attribute { name = "span"; jsxName = "span"; reasonJsxName = "span"; type_ = Int };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String }
  ]

let colgroupHTMLAttributes =
  [
    Attribute { name = "span"; jsxName = "span"; reasonJsxName = "span"; type_ = Int }
  ]

let dataHTMLAttributes =
  [
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String }
  ]

let detailsHTMLAttributes =
  [
    Attribute { name = "open"; jsxName = "open"; reasonJsxName = "open_"; type_ = Bool }; Event { jsxName = "onToggle"; type_ = Media }
  ]

let delHTMLAttributes =
  [
    Attribute { name = "cite"; type_ = String; jsxName = "cite"; reasonJsxName = "cite" };
    Attribute { name = "datetime"; type_ = String; jsxName = "dateTime"; reasonJsxName = "dateTime" };
  ]

let dialogHTMLAttributes =
  [
    Attribute { name = "open"; jsxName = "open"; reasonJsxName = "open_"; type_ = Bool }
  ]

let embedHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String; };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String; };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String; };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String; };
  ]

let fieldsetHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
  ]

let formHTMLAttributes =
  [
    Attribute { name = "accept"; jsxName = "accept"; reasonJsxName = "accept"; type_ = String };
    Attribute { name = "accept-charset"; jsxName = "acceptCharset"; reasonJsxName = "acceptCharset"; type_ = String };
    Attribute { name = "autocapitalize"; jsxName = "autoCapitalize"; reasonJsxName = "autoCapitalize"; type_ = String };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; reasonJsxName = "autoComplete"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; reasonJsxName = "rel"; type_ = String };
    Attribute { name = "enctype"; jsxName = "encType"; reasonJsxName = "encType"; type_ = String };
    Attribute { name = "action"; jsxName = "action"; reasonJsxName = "action"; type_ = Action };
    Attribute { name = "method"; jsxName = "method"; reasonJsxName = "method_"; type_ = String };
    Attribute { name = "novalidate"; jsxName = "noValidate"; reasonJsxName = "noValidate"; type_ = Bool };
    Attribute { name = "target"; jsxName = "target"; reasonJsxName = "target"; type_ = String };
  ]

let htmlHTMLAttributes =
  [
    Attribute { name = "manifest"; jsxName = "manifest"; reasonJsxName = "manifest"; type_ = String };
  ]

let iframeHTMLAttributes =
  [
    Attribute { name = "allow"; jsxName = "allow"; reasonJsxName = "allow"; type_ = String };
    Attribute { name = "allowfullscreen"; jsxName = "allowFullScreen"; reasonJsxName = "allowFullScreen"; type_ = Bool };
    Attribute { name = "allowtransparency"; jsxName = "allowTransparency"; reasonJsxName = "allowTransparency"; type_ = Bool };
    Attribute { name = "csp"; jsxName = "csp"; reasonJsxName = "csp"; type_ = String };
    Attribute { name = "credentialless"; jsxName = "credentialLess"; reasonJsxName = "credentialLess"; type_ = String };
    Attribute { name = "loading"; jsxName = "loading"; reasonJsxName = "loading"; type_ = String };
    Attribute { name = "sandbox"; jsxName = "sandbox"; reasonJsxName = "sandbox"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "seamless"; jsxName = "seamless"; reasonJsxName = "seamless"; type_ = Bool };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "srcdoc"; jsxName = "srcDoc"; reasonJsxName = "srcDoc"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "align"; jsxName = "align"; reasonJsxName = "align"; type_ = String };
    Attribute { name = "longdesc"; jsxName = "longDesc"; reasonJsxName = "longDesc"; type_ = String };
    Attribute { name = "frameborder"; jsxName = "frameBorder"; reasonJsxName = "frameBorder"; type_ = String };
    Attribute { name = "marginheight"; jsxName = "marginHeight"; reasonJsxName = "marginHeight"; type_ = Int };
    Attribute { name = "marginwidth"; jsxName = "marginWidth"; reasonJsxName = "marginWidth"; type_ = Int };
    Attribute { name = "scrolling"; jsxName = "scrolling"; reasonJsxName = "scrolling"; type_ = String };
  ]

let imgHTMLAttributes =
  [
    Attribute { name = "alt"; jsxName = "alt"; reasonJsxName = "alt"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "elementtiming"; jsxName = "elementTiming"; reasonJsxName = "elementTiming"; type_ = String };
    Attribute { name = "fetchpriority"; jsxName = "fetchPriority"; reasonJsxName = "fetchPriority"; type_ = String };
    Attribute { name = "loading"; jsxName = "loading"; reasonJsxName = "loading"; type_ = String };
    Attribute { name = "ismap"; jsxName = "isMap"; reasonJsxName = "isMap"; type_ = Bool };
    Attribute { name = "decoding"; jsxName = "decoding"; reasonJsxName = "decoding"; type_ = String };
    Attribute { name = "sizes"; jsxName = "sizes"; reasonJsxName = "sizes"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "srcset"; jsxName = "srcset"; reasonJsxName = "srcset"; type_ = String };
    Attribute { name = "usemap"; jsxName = "usemap"; reasonJsxName = "usemap"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
  ]

let insHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; reasonJsxName = "cite"; type_ = String };
    Attribute { name = "datetime"; jsxName = "datetime"; reasonJsxName = "datetime"; type_ = String };
  ]

let inputTypeAttribute = String

let inputHTMLAttributes =
  [
    Attribute { name = "accept"; jsxName = "accept"; reasonJsxName = "accept"; type_ = String };
    Attribute { name = "alt"; jsxName = "alt"; reasonJsxName = "alt"; type_ = String };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; reasonJsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "capture"; jsxName = "capture"; reasonJsxName = "capture"; type_ = String };
    Attribute { name = "checked"; jsxName = "checked"; reasonJsxName = "checked"; type_ = Bool };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "dirname"; jsxName = "dirname"; reasonJsxName = "dirname"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "formaction"; jsxName = "formAction"; reasonJsxName = "formAction"; type_ = String };
    Attribute { name = "formenctype"; jsxName = "formEncType"; reasonJsxName = "formEncType"; type_ = String };
    Attribute { name = "formmethod"; jsxName = "formMethod"; reasonJsxName = "formMethod"; type_ = String };
    Attribute { name = "formnovalidate"; jsxName = "formNoValidate"; reasonJsxName = "formNoValidate"; type_ = Bool };
    Attribute { name = "formtarget"; jsxName = "formTarget"; reasonJsxName = "formTarget"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "list"; jsxName = "list"; reasonJsxName = "list"; type_ = String };
    Attribute { name = "max"; jsxName = "max"; reasonJsxName = "max"; type_ = String };
    Attribute { name = "maxlength"; jsxName = "maxLength"; reasonJsxName = "maxLength"; type_ = Int };
    Attribute { name = "min"; jsxName = "min"; reasonJsxName = "min"; type_ = String };
    Attribute { name = "minlength"; jsxName = "minLength"; reasonJsxName = "minLength"; type_ = Int };
    Attribute { name = "multiple"; jsxName = "multiple"; reasonJsxName = "multiple"; type_ = Bool };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "pattern"; jsxName = "pattern"; reasonJsxName = "pattern"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; reasonJsxName = "placeholder"; type_ = String };
    Attribute { name = "readonly"; jsxName = "readOnly"; reasonJsxName = "readOnly"; type_ = Bool };
    Attribute { name = "required"; jsxName = "required"; reasonJsxName = "required"; type_ = Bool };
    Attribute { name = "size"; jsxName = "size"; reasonJsxName = "size"; type_ = Int };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "step"; jsxName = "step"; reasonJsxName = "step"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = inputTypeAttribute };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
    Event { jsxName = "onChange"; type_ = Form };
  ]

let keygenHTMLAttributes =
  [
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "challenge"; jsxName = "challenge"; reasonJsxName = "challenge"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "keytype"; jsxName = "keyType"; reasonJsxName = "keyType"; type_ = String };
    Attribute { name = "keyparams"; jsxName = "keyParams"; reasonJsxName = "keyParams"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
  ]

let labelHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "for"; jsxName = "htmlFor"; reasonJsxName = "htmlFor"; type_ = String };
  ]

let liHTMLAttributes =
  [
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String }
  ]

let linkHTMLAttributes =
  [
    Attribute { name = "as"; jsxName = "as"; reasonJsxName = "as_"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "blocking"; jsxName = "blocking"; reasonJsxName = "blocking"; type_ = Bool };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "fetchpriority"; jsxName = "fetchPriority"; reasonJsxName = "fetchPriority"; type_ = String };
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; reasonJsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
    Attribute { name = "href"; jsxName = "href"; reasonJsxName = "href"; type_ = String };
    Attribute { name = "hreflang"; jsxName = "hrefLang"; reasonJsxName = "hrefLang"; type_ = String };
    Attribute { name = "integrity"; jsxName = "integrity"; reasonJsxName = "integrity"; type_ = String };
    Attribute { name = "imagesizes"; jsxName = "imageSizes"; reasonJsxName = "imageSizes"; type_ = String };
    Attribute { name = "imagesrcset"; jsxName = "imageSrcSet"; reasonJsxName = "imageSrcSet"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; reasonJsxName = "rel"; type_ = String };
    Attribute { name = "title"; jsxName = "title"; reasonJsxName = "title"; type_ = String };
    Attribute { name = "sizes"; jsxName = "sizes"; reasonJsxName = "sizes"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
    Attribute { name = "charset"; jsxName = "charSet"; reasonJsxName = "charSet"; type_ = String };
  ]

let mapHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
  ]

let menuHTMLAttributes =
  [
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
  ]

let mediaHTMLAttributes =
  [
    Attribute { name = "autoplay"; jsxName = "autoPlay"; reasonJsxName = "autoPlay"; type_ = Bool };
    Attribute { name = "controls"; jsxName = "controls"; reasonJsxName = "controls"; type_ = Bool };
    Attribute { name = "controlslist"; jsxName = "controlsList"; reasonJsxName = "controlsList"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "loop"; jsxName = "loop"; reasonJsxName = "loop"; type_ = Bool };
    Attribute { name = "mediagroup"; jsxName = "mediaGroup"; reasonJsxName = "mediaGroup"; type_ = String };
    Attribute { name = "muted"; jsxName = "muted"; reasonJsxName = "muted"; type_ = Bool };
    Attribute { name = "playsinline"; jsxName = "playsInline"; reasonJsxName = "playsInline"; type_ = Bool };
    Attribute { name = "preload"; jsxName = "preload"; reasonJsxName = "preload"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
  ]

let metaHTMLAttributes =
  [
    Attribute { name = "charset"; jsxName = "charSet"; reasonJsxName = "charSet"; type_ = String };
    Attribute { name = "content"; jsxName = "content"; reasonJsxName = "content"; type_ = String };
    Attribute { name = "http-equiv"; jsxName = "httpEquiv"; reasonJsxName = "httpEquiv"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
  ]

let meterHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "high"; jsxName = "high"; reasonJsxName = "high"; type_ = Int };
    Attribute { name = "low"; jsxName = "low"; reasonJsxName = "low"; type_ = Int };
    Attribute { name = "max"; jsxName = "max"; reasonJsxName = "max"; type_ = String };
    Attribute { name = "min"; jsxName = "min"; reasonJsxName = "min"; type_ = String };
    Attribute { name = "optimum"; jsxName = "optimum"; reasonJsxName = "optimum"; type_ = Int };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
  ]

let quoteHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; reasonJsxName = "cite"; type_ = String };
  ]

let objectHTMLAttributes =
  [
    Attribute { name = "classid"; jsxName = "classID"; reasonJsxName = "classID"; type_ = String };
    Attribute { name = "data"; jsxName = "data"; reasonJsxName = "data"; type_ = String };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
    Attribute { name = "usemap"; jsxName = "useMap"; reasonJsxName = "useMap"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
    Attribute { name = "wmode"; jsxName = "wmode"; reasonJsxName = "wmode"; type_ = String };
  ]

let olHTMLAttributes =
  [
    Attribute { name = "reversed"; jsxName = "reversed"; reasonJsxName = "reversed"; type_ = Bool };
    Attribute { name = "start"; jsxName = "start"; reasonJsxName = "start"; type_ = Int };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
  ]

let optgroupHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "label"; jsxName = "label"; reasonJsxName = "label"; type_ = String };
  ]

let optionHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "label"; jsxName = "label"; reasonJsxName = "label"; type_ = String };
    Attribute { name = "selected"; jsxName = "selected"; reasonJsxName = "selected"; type_ = Bool };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
  ]

let outputHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "for"; jsxName = "htmlFor"; reasonJsxName = "htmlFor"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
  ]

let paramHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
  ]

let progressHTMLAttributes =
  [
    Attribute { name = "max"; jsxName = "max"; reasonJsxName = "max"; type_ = String };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
  ]

let slotHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
  ]

let scriptHTMLAttributes =
  [
    Attribute { name = "async"; jsxName = "async"; reasonJsxName = "async"; type_ = Bool };
    Attribute { name = "charset"; jsxName = "charSet"; reasonJsxName = "charSet"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "defer"; jsxName = "defer"; reasonJsxName = "defer"; type_ = Bool };
    Attribute { name = "integrity"; jsxName = "integrity"; reasonJsxName = "integrity"; type_ = String };
    Attribute { name = "nomodule"; jsxName = "noModule"; reasonJsxName = "noModule"; type_ = Bool };
    Attribute { name = "nonce"; jsxName = "nonce"; reasonJsxName = "nonce"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
  ]

let selectHTMLAttributes =
  [
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; reasonJsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "multiple"; jsxName = "multiple"; reasonJsxName = "multiple"; type_ = Bool };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "required"; jsxName = "required"; reasonJsxName = "required"; type_ = Bool };
    Attribute { name = "size"; jsxName = "size"; reasonJsxName = "size"; type_ = Int };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
    Event { jsxName = "onChange"; type_ = Form };
  ]

let sourceHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
    Attribute { name = "sizes"; jsxName = "sizes"; reasonJsxName = "sizes"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "srcset"; jsxName = "srcSet"; reasonJsxName = "srcSet"; type_ = String };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
  ]

let styleHTMLAttributes =
  [
    Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
    Attribute { name = "nonce"; jsxName = "nonce"; reasonJsxName = "nonce"; type_ = String };
    Attribute { name = "scoped"; jsxName = "scoped"; reasonJsxName = "scoped"; type_ = Bool };
    Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String }
  ]

let tableHTMLAttributes =
  [
    Attribute { name = "cellpadding"; jsxName = "cellPadding"; reasonJsxName = "cellPadding"; type_ = String };
    Attribute { name = "cellspacing"; jsxName = "cellSpacing"; reasonJsxName = "cellSpacing"; type_ = String };
    Attribute { name = "summary"; jsxName = "summary"; reasonJsxName = "summary"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
  ]

let textareaHTMLAttributes =
  [
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; reasonJsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "cols"; jsxName = "cols"; reasonJsxName = "cols"; type_ = Int };
    Attribute { name = "dirName"; jsxName = "dirName"; reasonJsxName = "dirName"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; reasonJsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; reasonJsxName = "form"; type_ = String };
    Attribute { name = "maxlength"; jsxName = "maxLength"; reasonJsxName = "maxLength"; type_ = Int };
    Attribute { name = "minlength"; jsxName = "minLength"; reasonJsxName = "minLength"; type_ = Int };
    Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; reasonJsxName = "placeholder"; type_ = String };
    Attribute { name = "readonly"; jsxName = "readOnly"; reasonJsxName = "readOnly"; type_ = Bool };
    Attribute { name = "required"; jsxName = "required"; reasonJsxName = "required"; type_ = Bool };
    Attribute { name = "rows"; jsxName = "rows"; reasonJsxName = "rows"; type_ = Int };
    Attribute { name = "value"; jsxName = "value"; reasonJsxName = "value"; type_ = String };
    Attribute { name = "wrap"; jsxName = "wrap"; reasonJsxName = "wrap"; type_ = String };
    Event { jsxName = "onChange"; type_ = Form };
  ]

let tdHTMLAttributes =
  [
    Attribute { name = "align"; jsxName = "align"; reasonJsxName = "align"; type_ = String };
    Attribute { name = "colspan"; jsxName = "colSpan"; reasonJsxName = "colSpan"; type_ = Int };
    Attribute { name = "headers"; jsxName = "headers"; reasonJsxName = "headers"; type_ = String };
    Attribute { name = "rowspan"; jsxName = "rowspan"; reasonJsxName = "rowspan"; type_ = Int };
    Attribute { name = "scope"; jsxName = "scope"; reasonJsxName = "scope"; type_ = String };
    Attribute { name = "abbr"; jsxName = "abbr"; reasonJsxName = "abbr"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
    Attribute { name = "valign"; jsxName = "valign"; reasonJsxName = "valign"; type_ = String };
  ]

let thHTMLAttributes =
  [
    Attribute { name = "align"; jsxName = "align"; reasonJsxName = "align"; type_ = String };
    Attribute { name = "colspan"; jsxName = "colSpan"; reasonJsxName = "colSpan"; type_ = Int };
    Attribute { name = "headers"; jsxName = "headers"; reasonJsxName = "headers"; type_ = String };
    Attribute { name = "rowspan"; jsxName = "rowSpan"; reasonJsxName = "rowSpan"; type_ = Int };
    Attribute { name = "scope"; jsxName = "scope"; reasonJsxName = "scope"; type_ = String };
    Attribute { name = "abbr"; jsxName = "abbr"; reasonJsxName = "abbr"; type_ = String };
  ]

let timeHTMLAttributes =
  [
    Attribute { name = "datetime"; jsxName = "datetime"; reasonJsxName = "datetime"; type_ = String };
  ]

let trackHTMLAttributes =
  [
    Attribute { name = "default"; jsxName = "default"; reasonJsxName = "default"; type_ = Bool };
    Attribute { name = "kind"; jsxName = "kind"; reasonJsxName = "kind"; type_ = String };
    Attribute { name = "label"; jsxName = "label"; reasonJsxName = "label"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "srclang"; jsxName = "srclang"; reasonJsxName = "srclang"; type_ = String };
  ]

let videoHTMLAttributes =
  [
    Attribute { name = "autoplay"; jsxName = "autoPlay"; reasonJsxName = "autoPlay"; type_ = Bool };
    Attribute { name = "controls"; jsxName = "controls"; reasonJsxName = "controls"; type_ = Bool };
    Attribute { name = "controlslist"; jsxName = "controlsList"; reasonJsxName = "controlsList"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };
    Attribute { name = "disablepictureinpicture"; jsxName = "disablePictureInPicture"; reasonJsxName = "disablePictureInPicture"; type_ = Bool };
    Attribute { name = "disableremoteplayback"; jsxName = "disableRemotePlayback"; reasonJsxName = "disableRemotePlayback"; type_ = Bool };
    Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
    Attribute { name = "loop"; jsxName = "loop"; reasonJsxName = "loop"; type_ = Bool };
    Attribute { name = "muted"; jsxName = "muted"; reasonJsxName = "muted"; type_ = Bool };
    Attribute { name = "playsinline"; jsxName = "playsInline"; reasonJsxName = "playsInline"; type_ = Bool };
    Attribute { name = "poster"; jsxName = "poster"; reasonJsxName = "poster"; type_ = String };
    Attribute { name = "preload"; jsxName = "preload"; reasonJsxName = "preload"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
  ]

module SVG = struct
  let coreAttributes =
    [
      Attribute { name = "id"; jsxName = "id"; reasonJsxName = "id"; type_ = String };
      Attribute { name = "lang"; jsxName = "lang"; reasonJsxName = "lang"; type_ = String };
      Attribute { name = "tabindex"; jsxName = "tabIndex"; reasonJsxName = "tabIndex"; type_ = Int };
      Attribute { name = "xml:base"; jsxName = "xmlBase"; reasonJsxName = "xmlBase"; type_ = String };
      Attribute { name = "xml:lang"; jsxName = "xmlLang"; reasonJsxName = "xmlLang"; type_ = String };
      Attribute { name = "xml:space"; jsxName = "xmlSpace"; reasonJsxName = "xmlSpace"; type_ = String };
    ]

  let stylingAttributes =
    [
      Attribute { name = "class"; jsxName = "className"; reasonJsxName = "className"; type_ = String };
      Attribute { name = "style"; jsxName = "style"; reasonJsxName = "style"; type_ = Style }
    ]

  let presentationAttributes =
    [
      Attribute { name = "alignment-baseline"; jsxName = "alignmentBaseline"; reasonJsxName = "alignmentBaseline"; type_ = String };
      Attribute { name = "baseline-shift"; jsxName = "baselineShift"; reasonJsxName = "baselineShift"; type_ = String };
      Attribute { name = "clip"; jsxName = "clip"; reasonJsxName = "clip"; type_ = String };
      Attribute { name = "clip-path"; jsxName = "clipPath"; reasonJsxName = "clipPath"; type_ = String };
      Attribute { name = "clip-rule"; jsxName = "clipRule"; reasonJsxName = "clipRule"; type_ = String };
      Attribute { name = "color"; jsxName = "color"; reasonJsxName = "color"; type_ = String };
      Attribute { name = "color-interpolation"; jsxName = "colorInterpolation"; reasonJsxName = "colorInterpolation"; type_ = String };
      Attribute { name = "color-interpolation-filters"; jsxName = "colorInterpolationFilters"; reasonJsxName = "colorInterpolationFilters"; type_ = String };
      Attribute { name = "color-profile"; jsxName = "colorProfile"; reasonJsxName = "colorProfile"; type_ = String };
      Attribute { name = "color-rendering"; jsxName = "colorRendering"; reasonJsxName = "colorRendering"; type_ = String };
      Attribute { name = "cursor"; jsxName = "cursor"; reasonJsxName = "cursor"; type_ = String };
      Attribute { name = "direction"; jsxName = "direction"; reasonJsxName = "direction"; type_ = String };
      Attribute { name = "display"; jsxName = "display"; reasonJsxName = "display"; type_ = String };
      Attribute { name = "divisor"; jsxName = "divisor"; reasonJsxName = "divisor"; type_ = String };
      Attribute { name = "dominant-baseline"; jsxName = "dominantBaseline"; reasonJsxName = "dominantBaseline"; type_ = String };
      Attribute { name = "enable-background"; jsxName = "enableBackground"; reasonJsxName = "enableBackground"; type_ = String };
      Attribute { name = "fill"; jsxName = "fill"; reasonJsxName = "fill"; type_ = String };
      Attribute { name = "fill-opacity"; jsxName = "fillOpacity"; reasonJsxName = "fillOpacity"; type_ = String };
      Attribute { name = "fill-rule"; jsxName = "fillRule"; reasonJsxName = "fillRule"; type_ = String };
      Attribute { name = "filter"; jsxName = "filter"; reasonJsxName = "filter"; type_ = String };
      Attribute { name = "flood-color"; jsxName = "floodColor"; reasonJsxName = "floodColor"; type_ = String };
      Attribute { name = "flood-opacity"; jsxName = "floodOpacity"; reasonJsxName = "floodOpacity"; type_ = String };
      Attribute { name = "font-family"; jsxName = "fontFamily"; reasonJsxName = "fontFamily"; type_ = String };
      Attribute { name = "font-size"; jsxName = "fontSize"; reasonJsxName = "fontSize"; type_ = String };
      Attribute { name = "font-size-adjust"; jsxName = "fontSizeAdjust"; reasonJsxName = "fontSizeAdjust"; type_ = String };
      Attribute { name = "font-stretch"; jsxName = "fontStretch"; reasonJsxName = "fontStretch"; type_ = String };
      Attribute { name = "font-style"; jsxName = "fontStyle"; reasonJsxName = "fontStyle"; type_ = String };
      Attribute { name = "font-variant"; jsxName = "fontVariant"; reasonJsxName = "fontVariant"; type_ = String };
      Attribute { name = "font-weight"; jsxName = "fontWeight"; reasonJsxName = "fontWeight"; type_ = String };
      Attribute { name = "glyph-orientation-horizontal"; jsxName = "glyphOrientationHorizontal"; reasonJsxName = "glyphOrientationHorizontal"; type_ = String };
      Attribute { name = "glyph-orientation-vertical"; jsxName = "glyphOrientationVertical"; reasonJsxName = "glyphOrientationVertical"; type_ = String };
      Attribute { name = "image-rendering"; jsxName = "imageRendering"; reasonJsxName = "imageRendering"; type_ = String };
      Attribute { name = "kerning"; jsxName = "kerning"; reasonJsxName = "kerning"; type_ = String };
      Attribute { name = "letter-spacing"; jsxName = "letterSpacing"; reasonJsxName = "letterSpacing"; type_ = String };
      Attribute { name = "lighting-color"; jsxName = "lightingColor"; reasonJsxName = "lightingColor"; type_ = String };
      Attribute { name = "marker-end"; jsxName = "markerEnd"; reasonJsxName = "markerEnd"; type_ = String };
      Attribute { name = "marker-mid"; jsxName = "markerMid"; reasonJsxName = "markerMid"; type_ = String };
      Attribute { name = "marker-start"; jsxName = "markerStart"; reasonJsxName = "markerStart"; type_ = String };
      Attribute { name = "mask"; jsxName = "mask"; reasonJsxName = "mask"; type_ = String };
      Attribute { name = "opacity"; jsxName = "opacity"; reasonJsxName = "opacity"; type_ = String };
      Attribute { name = "operator"; jsxName = "operator"; reasonJsxName = "operator"; type_ = String };
      Attribute { name = "overflow"; jsxName = "overflow"; reasonJsxName = "overflow"; type_ = String };
      Attribute { name = "pointer-events"; jsxName = "pointerEvents"; reasonJsxName = "pointerEvents"; type_ = String };
      Attribute { name = "shape-rendering"; jsxName = "shapeRendering"; reasonJsxName = "shapeRendering"; type_ = String };
      Attribute { name = "specularConstant"; jsxName = "specularConstant"; reasonJsxName = "specularConstant"; type_ = String };
      Attribute { name = "specularExponent"; jsxName = "specularExponent"; reasonJsxName = "specularExponent"; type_ = String };
      Attribute { name = "solid-color"; jsxName = "solidColor"; reasonJsxName = "solidColor"; type_ = String };
      Attribute { name = "solid-opacity"; jsxName = "solidOpacity"; reasonJsxName = "solidOpacity"; type_ = String };
      Attribute { name = "stop-color"; jsxName = "stopColor"; reasonJsxName = "stopColor"; type_ = String };
      Attribute { name = "stop-opacity"; jsxName = "stopOpacity"; reasonJsxName = "stopOpacity"; type_ = String };
      Attribute { name = "stroke"; jsxName = "stroke"; reasonJsxName = "stroke"; type_ = String };
      Attribute { name = "stroke-dasharray"; jsxName = "strokeDasharray"; reasonJsxName = "strokeDasharray"; type_ = String };
      Attribute { name = "stroke-opacity"; jsxName = "strokeOpacity"; reasonJsxName = "strokeOpacity"; type_ = String };
      Attribute { name = "stroke-miterlimit"; jsxName = "strokeMiterlimit"; reasonJsxName = "strokeMiterlimit"; type_ = String };
      Attribute { name = "stroke-dashoffset"; jsxName = "strokeDashoffset"; reasonJsxName = "strokeDashoffset"; type_ = String };
      Attribute { name = "stroke-linecap"; jsxName = "strokeLinecap"; reasonJsxName = "strokeLinecap"; type_ = String };
      Attribute { name = "stroke-linejoin"; jsxName = "strokeLinejoin"; reasonJsxName = "strokeLinejoin"; type_ = String };
      Attribute { name = "text-anchor"; jsxName = "textAnchor"; reasonJsxName = "textAnchor"; type_ = String };
      Attribute { name = "text-decoration"; jsxName = "textDecoration"; reasonJsxName = "textDecoration"; type_ = String };
      Attribute { name = "text-rendering"; jsxName = "textRendering"; reasonJsxName = "textRendering"; type_ = String };
      Attribute { name = "transform"; jsxName = "transform"; reasonJsxName = "transform"; type_ = String };
      Attribute { name = "transform-origin"; jsxName = "transformOrigin"; reasonJsxName = "transformOrigin"; type_ = String };
      Attribute { name = "unicode-bidi"; jsxName = "unicodeBidi"; reasonJsxName = "unicodeBidi"; type_ = String };
      Attribute { name = "vector-effect"; jsxName = "vectorEffect"; reasonJsxName = "vectorEffect"; type_ = String };
      Attribute { name = "word-spacing"; jsxName = "wordSpacing"; reasonJsxName = "wordSpacing"; type_ = String };
      Attribute { name = "writing-mode"; jsxName = "writingMode"; reasonJsxName = "writingMode"; type_ = String };
    ]

  let filtersAttributes =
    [
      Attribute { name = "height"; jsxName = "height"; reasonJsxName = "height"; type_ = String };
      Attribute { name = "width"; jsxName = "width"; reasonJsxName = "width"; type_ = String };
      Attribute { name = "result"; jsxName = "result"; reasonJsxName = "result"; type_ = String };
      Attribute { name = "x"; jsxName = "x"; reasonJsxName = "x"; type_ = String };
      Attribute { name = "y"; jsxName = "y"; reasonJsxName = "y"; type_ = String };
      Attribute { name = "type"; jsxName = "type"; reasonJsxName = "type_"; type_ = String };
      Attribute { name = "exponent"; jsxName = "exponent"; reasonJsxName = "exponent"; type_ = String };
      Attribute { name = "slope"; jsxName = "slope"; reasonJsxName = "slope"; type_ = String };
      Attribute { name = "amplitude"; jsxName = "amplitude"; reasonJsxName = "amplitude"; type_ = String };
      Attribute { name = "intercept"; jsxName = "intercept"; reasonJsxName = "intercept"; type_ = String };
      Attribute { name = "tableValues"; jsxName = "tableValues"; reasonJsxName = "tableValues"; type_ = String };

      Attribute { name = "href"; jsxName = "href"; reasonJsxName = "href"; type_ = String };

      Attribute { name = "attributeName"; jsxName = "attributeName"; reasonJsxName = "attributeName"; type_ = String };
      Attribute { name = "attributeType"; jsxName = "attributeType"; reasonJsxName = "attributeType"; type_ = String };

      Attribute { name = "begin"; jsxName = "begin"; reasonJsxName = "begin_"; type_ = String };
      Attribute { name = "dur"; jsxName = "dur"; reasonJsxName = "dur"; type_ = String };
      Attribute { name = "end"; jsxName = "end"; reasonJsxName = "end_"; type_ = String };
      Attribute { name = "max"; jsxName = "max"; reasonJsxName = "max"; type_ = String };
      Attribute { name = "min"; jsxName = "min"; reasonJsxName = "min"; type_ = String };
      Attribute { name = "repeatCount"; jsxName = "repeatCount"; reasonJsxName = "repeatCount"; type_ = String };
      Attribute { name = "restart"; jsxName = "restart"; reasonJsxName = "restart"; type_ = String };
      Attribute { name = "repeatDur"; jsxName = "repeatDur"; reasonJsxName = "repeatDur"; type_ = String };
      Attribute { name = "fill"; jsxName = "fill"; reasonJsxName = "fill"; type_ = String };

      Attribute { name = "calcMode"; jsxName = "calcMode"; reasonJsxName = "calcMode"; type_ = String };
      Attribute { name = "values"; jsxName = "values"; reasonJsxName = "values"; type_ = String };
      Attribute { name = "keySplines"; jsxName = "keySplines"; reasonJsxName = "keySplines"; type_ = String };
      Attribute { name = "keyTimes"; jsxName = "keyTimes"; reasonJsxName = "keyTimes"; type_ = String };
      Attribute { name = "from"; jsxName = "from"; reasonJsxName = "from"; type_ = String };
      Attribute { name = "to"; jsxName = "to"; reasonJsxName = "to_"; type_ = String };
      Attribute { name = "by"; jsxName = "by"; reasonJsxName = "by"; type_ = String };

      Attribute { name = "accumulate"; jsxName = "accumulate"; reasonJsxName = "accumulate"; type_ = String };
      Attribute { name = "additive"; jsxName = "additive"; reasonJsxName = "additive"; type_ = String };
    ]

  let htmlAttributes =
    [
      Attribute { name = "color"; jsxName = "color"; reasonJsxName = "color"; type_ = String };
      Attribute { name = "id"; jsxName = "id"; reasonJsxName = "id"; type_ = String };
      Attribute { name = "lang"; jsxName = "lang"; reasonJsxName = "lang"; type_ = String };
      Attribute { name = "media"; jsxName = "media"; reasonJsxName = "media"; type_ = String };
      Attribute { name = "method"; jsxName = "method"; reasonJsxName = "method_"; type_ = String };
      Attribute { name = "name"; jsxName = "name"; reasonJsxName = "name"; type_ = String };
      Attribute { name = "style"; jsxName = "style"; reasonJsxName = "style"; type_ = Style };
      Attribute { name = "target"; jsxName = "target"; reasonJsxName = "target"; type_ = String };

      Attribute { name = "role"; jsxName = "role"; reasonJsxName = "role"; type_ = ariaRole };
      Attribute { name = "tabindex"; jsxName = "tabIndex"; reasonJsxName = "tabIndex"; type_ = Int };
      Attribute { name = "crossorigin"; jsxName = "crossOrigin"; reasonJsxName = "crossOrigin"; type_ = String };

      Attribute { name = "accent-height"; jsxName = "accentHeight"; reasonJsxName = "accentHeight"; type_ = String };
      Attribute { name = "alphabetic"; jsxName = "alphabetic"; reasonJsxName = "alphabetic"; type_ = String };
      Attribute { name = "arabic-form"; jsxName = "arabicForm"; reasonJsxName = "arabicForm"; type_ = String };
      Attribute { name = "ascent"; jsxName = "ascent"; reasonJsxName = "ascent"; type_ = String };
      Attribute { name = "azimuth"; jsxName = "azimuth"; reasonJsxName = "azimuth"; type_ = String };
      Attribute { name = "baseProfile"; jsxName = "baseProfile"; reasonJsxName = "baseProfile"; type_ = String };
      Attribute { name = "baseFrequency"; jsxName = "baseFrequency"; reasonJsxName = "baseFrequency"; type_ = String };
      Attribute { name = "bbox"; jsxName = "bbox"; reasonJsxName = "bbox"; type_ = String };
      Attribute { name = "bias"; jsxName = "bias"; reasonJsxName = "bias"; type_ = String };
      Attribute { name = "cap-height"; jsxName = "capHeight"; reasonJsxName = "capHeight"; type_ = String };
      Attribute { name = "cx"; jsxName = "cx"; reasonJsxName = "cx"; type_ = String };
      Attribute { name = "cy"; jsxName = "cy"; reasonJsxName = "cy"; type_ = String };
      Attribute { name = "d"; jsxName = "d"; reasonJsxName = "d"; type_ = String };
      Attribute { name = "decelerate"; jsxName = "decelerate"; reasonJsxName = "decelerate"; type_ = String };
      Attribute { name = "descent"; jsxName = "descent"; reasonJsxName = "descent"; type_ = String };
      Attribute { name = "dx"; jsxName = "dx"; reasonJsxName = "dx"; type_ = String };
      Attribute { name = "dy"; jsxName = "dy"; reasonJsxName = "dy"; type_ = String };
      Attribute { name = "edgeMode"; jsxName = "edgeMode"; reasonJsxName = "edgeMode"; type_ = String };
      Attribute { name = "elevation"; jsxName = "elevation"; reasonJsxName = "elevation"; type_ = String };
      Attribute { name = "filterRes"; jsxName = "filterRes"; reasonJsxName = "filterRes"; type_ = String };
      Attribute { name = "filterUnits"; jsxName = "filterUnits"; reasonJsxName = "filterUnits"; type_ = String };
      Attribute { name = "format"; jsxName = "format"; reasonJsxName = "format"; type_ = String };
      Attribute { name = "fr"; jsxName = "fr"; reasonJsxName = "fr"; type_ = String };
      Attribute { name = "fx"; jsxName = "fx"; reasonJsxName = "fx"; type_ = String };
      Attribute { name = "fy"; jsxName = "fy"; reasonJsxName = "fy"; type_ = String };
      Attribute { name = "g1"; jsxName = "g1"; reasonJsxName = "g1"; type_ = String };
      Attribute { name = "g2"; jsxName = "g2"; reasonJsxName = "g2"; type_ = String };
      Attribute { name = "glyph-name"; jsxName = "glyphName"; reasonJsxName = "glyphName"; type_ = String };
      Attribute { name = "glyphRef"; jsxName = "glyphRef"; reasonJsxName = "glyphRef"; type_ = String };
      Attribute { name = "gradientTransform"; jsxName = "gradientTransform"; reasonJsxName = "gradientTransform"; type_ = String };
      Attribute { name = "gradientUnits"; jsxName = "gradientUnits"; reasonJsxName = "gradientUnits"; type_ = String };
      Attribute { name = "hanging"; jsxName = "hanging"; reasonJsxName = "hanging"; type_ = String };
      Attribute { name = "horiz-adv-x"; jsxName = "horizAdvX"; reasonJsxName = "horizAdvX"; type_ = String };
      Attribute { name = "horiz-origin-x"; jsxName = "horizOriginX"; reasonJsxName = "horizOriginX"; type_ = String };
      Attribute { name = "horiz-origin-y"; jsxName = "horizOriginY"; reasonJsxName = "horizOriginY"; type_ = String };
      Attribute { name = "ideographic"; jsxName = "ideographic"; reasonJsxName = "ideographic"; type_ = String };
      Attribute { name = "in2"; jsxName = "in2"; reasonJsxName = "in2"; type_ = String };
      Attribute { name = "in"; jsxName = "in"; reasonJsxName = "in_"; type_ = String };
      Attribute { name = "k1"; jsxName = "k1"; reasonJsxName = "k1"; type_ = String };
      Attribute { name = "k2"; jsxName = "k2"; reasonJsxName = "k2"; type_ = String };
      Attribute { name = "k3"; jsxName = "k3"; reasonJsxName = "k3"; type_ = String };
      Attribute { name = "k4"; jsxName = "k4"; reasonJsxName = "k4"; type_ = String };
      Attribute { name = "k"; jsxName = "k"; reasonJsxName = "k"; type_ = String };
      Attribute { name = "kernelMatrix"; jsxName = "kernelMatrix"; reasonJsxName = "kernelMatrix"; type_ = String };
      Attribute { name = "limitingConeAngle"; jsxName = "limitingConeAngle"; reasonJsxName = "limitingConeAngle"; type_ = String };
      Attribute { name = "lengthAdjust"; jsxName = "lengthAdjust"; reasonJsxName = "lengthAdjust"; type_ = String };
      Attribute { name = "local"; jsxName = "local"; reasonJsxName = "local"; type_ = String };
      Attribute { name = "marker-mid"; jsxName = "markerMid"; reasonJsxName = "markerMid"; type_ = String };
      Attribute { name = "marker-start"; jsxName = "markerStart"; reasonJsxName = "markerStart"; type_ = String };
      Attribute { name = "marker-units"; jsxName = "markerUnits"; reasonJsxName = "markerUnits"; type_ = String };
      Attribute { name = "markerWidth"; jsxName = "markerWidth"; reasonJsxName = "markerWidth"; type_ = String };
      Attribute { name = "markerHeight"; jsxName = "markerHeight"; reasonJsxName = "markerHeight"; type_ = String };
      Attribute { name = "maskUnits"; jsxName = "maskUnits"; reasonJsxName = "maskUnits"; type_ = String };
      Attribute { name = "maskContentUnits"; jsxName = "maskContentUnits"; reasonJsxName = "maskContentUnits"; type_ = String };
      Attribute { name = "mathematical"; jsxName = "mathematical"; reasonJsxName = "mathematical"; type_ = String };
      Attribute { name = "mode"; jsxName = "mode"; reasonJsxName = "mode"; type_ = String };
      Attribute { name = "numOctaves"; jsxName = "numOctaves"; reasonJsxName = "numOctaves"; type_ = String };
      Attribute { name = "offset"; jsxName = "offset"; reasonJsxName = "offset"; type_ = String };
      Attribute { name = "order"; jsxName = "order"; reasonJsxName = "order"; type_ = String };
      Attribute { name = "orient"; jsxName = "orient"; reasonJsxName = "orient"; type_ = String };
      Attribute { name = "orientation"; jsxName = "orientation"; reasonJsxName = "orientation"; type_ = String };
      Attribute { name = "origin"; jsxName = "origin"; reasonJsxName = "origin"; type_ = String };
      Attribute { name = "overline-thickness"; jsxName = "overlineThickness"; reasonJsxName = "overlineThickness"; type_ = String };
      Attribute { name = "overline-position"; jsxName = "overlinePosition"; reasonJsxName = "overlinePosition"; type_ = String };
      Attribute { name = "paint-order"; jsxName = "paintOrder"; reasonJsxName = "paintOrder"; type_ = String };
      Attribute { name = "panose1"; jsxName = "panose1"; reasonJsxName = "panose1"; type_ = String };
      Attribute { name = "path"; jsxName = "path"; reasonJsxName = "path"; type_ = String };
      Attribute { name = "pathLength"; jsxName = "pathLength"; reasonJsxName = "pathLength"; type_ = String };
      Attribute { name = "patternContentUnits"; jsxName = "patternContentUnits"; reasonJsxName = "patternContentUnits"; type_ = String };
      Attribute { name = "patternUnits"; jsxName = "patternUnits"; reasonJsxName = "patternUnits"; type_ = String };
      Attribute { name = "points"; jsxName = "points"; reasonJsxName = "points"; type_ = String };
      Attribute { name = "pointsAtX"; jsxName = "pointsAtX"; reasonJsxName = "pointsAtX"; type_ = String };
      Attribute { name = "pointsAtY"; jsxName = "pointsAtY"; reasonJsxName = "pointsAtY"; type_ = String };
      Attribute { name = "pointsAtZ"; jsxName = "pointsAtZ"; reasonJsxName = "pointsAtZ"; type_ = String };
      Attribute { name = "preserveAspectRatio"; jsxName = "preserveAspectRatio"; reasonJsxName = "preserveAspectRatio"; type_ = String };
      Attribute { name = "r"; jsxName = "r"; reasonJsxName = "r"; type_ = String };
      Attribute { name = "radius"; jsxName = "radius"; reasonJsxName = "radius"; type_ = String };
      Attribute { name = "requiredFeatures"; jsxName = "requiredFeatures"; reasonJsxName = "requiredFeatures"; type_ = String };
      Attribute { name = "refX"; jsxName = "refX"; reasonJsxName = "refX"; type_ = String };
      Attribute { name = "refY"; jsxName = "refY"; reasonJsxName = "refY"; type_ = String };
      Attribute { name = "rotate"; jsxName = "rotate"; reasonJsxName = "rotate"; type_ = String };
      Attribute { name = "rx"; jsxName = "rx"; reasonJsxName = "rx"; type_ = String };
      Attribute { name = "ry"; jsxName = "ry"; reasonJsxName = "ry"; type_ = String };
      Attribute { name = "scale"; jsxName = "scale"; reasonJsxName = "scale"; type_ = String };
      Attribute { name = "seed"; jsxName = "seed"; reasonJsxName = "seed"; type_ = String };
      Attribute { name = "spacing"; jsxName = "spacing"; reasonJsxName = "spacing"; type_ = String };
      Attribute { name = "speed"; jsxName = "speed"; reasonJsxName = "speed"; type_ = String };
      Attribute { name = "spreadMethod"; jsxName = "spreadMethod"; reasonJsxName = "spreadMethod"; type_ = String };
      Attribute { name = "startOffset"; jsxName = "startOffset"; reasonJsxName = "startOffset"; type_ = String };
      Attribute { name = "stdDeviation"; jsxName = "stdDeviation"; reasonJsxName = "stdDeviation"; type_ = String };
      Attribute { name = "stemh"; jsxName = "stemh"; reasonJsxName = "stemh"; type_ = String };
      Attribute { name = "stemv"; jsxName = "stemv"; reasonJsxName = "stemv"; type_ = String };
      Attribute { name = "stitchTiles"; jsxName = "stitchTiles"; reasonJsxName = "stitchTiles"; type_ = String };
      Attribute { name = "strikethrough-position"; jsxName = "strikethroughPosition"; reasonJsxName = "strikethroughPosition"; type_ = String };
      Attribute { name = "strikethrough-thickness"; jsxName = "strikethroughThickness"; reasonJsxName = "strikethroughThickness"; type_ = String };
      Attribute { name = "stroke-width"; jsxName = "strokeWidth"; reasonJsxName = "strokeWidth"; type_ = String };
      Attribute { name = "surfaceScale"; jsxName = "surfaceScale"; reasonJsxName = "surfaceScale"; type_ = String };
      Attribute { name = "systemLanguage"; jsxName = "systemLanguage"; reasonJsxName = "systemLanguage"; type_ = String };
      Attribute { name = "targetX"; jsxName = "targetX"; reasonJsxName = "targetX"; type_ = String };
      Attribute { name = "targetY"; jsxName = "targetY"; reasonJsxName = "targetY"; type_ = String };
      Attribute { name = "textLength"; jsxName = "textLength"; reasonJsxName = "textLength"; type_ = String };
      Attribute { name = "u1"; jsxName = "u1"; reasonJsxName = "u1"; type_ = String };
      Attribute { name = "u2"; jsxName = "u2"; reasonJsxName = "u2"; type_ = String };
      Attribute { name = "unicode"; jsxName = "unicode"; reasonJsxName = "unicode"; type_ = String };
      Attribute { name = "unicode-range"; jsxName = "unicodeRange"; reasonJsxName = "unicodeRange"; type_ = String };
      Attribute { name = "units-per-em"; jsxName = "unitsPerEm"; reasonJsxName = "unitsPerEm"; type_ = String };
      Attribute { name = "v-alphabetic"; jsxName = "vAlphabetic"; reasonJsxName = "vAlphabetic"; type_ = String };
      Attribute { name = "version"; jsxName = "version"; reasonJsxName = "version"; type_ = String };
      Attribute { name = "vert-adv-y"; jsxName = "vertAdvY"; reasonJsxName = "vertAdvY"; type_ = String };
      Attribute { name = "vert-origin-x"; jsxName = "vertOriginX"; reasonJsxName = "vertOriginX"; type_ = String };
      Attribute { name = "vert-origin-y"; jsxName = "vertOriginY"; reasonJsxName = "vertOriginY"; type_ = String };
      Attribute { name = "v-hanging"; jsxName = "vHanging"; reasonJsxName = "vHanging"; type_ = String };
      Attribute { name = "v-ideographic"; jsxName = "vIdeographic"; reasonJsxName = "vIdeographic"; type_ = String };
      Attribute { name = "viewBox"; jsxName = "viewBox"; reasonJsxName = "viewBox"; type_ = String };
      Attribute { name = "viewTarget"; jsxName = "viewTarget"; reasonJsxName = "viewTarget"; type_ = String };
      Attribute { name = "visibility"; jsxName = "visibility"; reasonJsxName = "visibility"; type_ = String };
      Attribute { name = "widths"; jsxName = "widths"; reasonJsxName = "widths"; type_ = String };
      Attribute { name = "x1"; jsxName = "x1"; reasonJsxName = "x1"; type_ = String };
      Attribute { name = "x2"; jsxName = "x2"; reasonJsxName = "x2"; type_ = String };
      Attribute { name = "xChannelSelector"; jsxName = "xChannelSelector"; reasonJsxName = "xChannelSelector"; type_ = String };
      Attribute { name = "xHeight"; jsxName = "xHeight"; reasonJsxName = "xHeight"; type_ = String };
      Attribute { name = "xlink:actuate"; jsxName = "xlinkActuate"; reasonJsxName = "xlinkActuate"; type_ = String };
      Attribute { name = "xlink:arcrole"; jsxName = "xlinkArcrole"; reasonJsxName = "xlinkArcrole"; type_ = String };
      Attribute { name = "xlink:href"; jsxName = "xlinkHref"; reasonJsxName = "xlinkHref"; type_ = String };
      Attribute { name = "xlink:role"; jsxName = "xlinkRole"; reasonJsxName = "xlinkRole"; type_ = String };
      Attribute { name = "xlink:show"; jsxName = "xlinkShow"; reasonJsxName = "xlinkShow"; type_ = String };
      Attribute { name = "xlink:title"; jsxName = "xlinkTitle"; reasonJsxName = "xlinkTitle"; type_ = String };
      Attribute { name = "xlink:type"; jsxName = "xlinkType"; reasonJsxName = "xlinkType"; type_ = String };
      Attribute { name = "xml:base"; jsxName = "xmlBase"; reasonJsxName = "xmlBase"; type_ = String };
      Attribute { name = "xml:lang"; jsxName = "xmlLang"; reasonJsxName = "xmlLang"; type_ = String };
      Attribute { name = "xmlns"; jsxName = "xmlns"; reasonJsxName = "xmlns"; type_ = String };
      Attribute { name = "xmlns:xlink"; jsxName = "xmlnsXlink"; reasonJsxName = "xmlnsXlink"; type_ = String };
      Attribute { name = "xml:space"; jsxName = "xmlSpace"; reasonJsxName = "xmlSpace"; type_ = String };
      Attribute { name = "y1"; jsxName = "y1"; reasonJsxName = "y1"; type_ = String };
      Attribute { name = "y2"; jsxName = "y2"; reasonJsxName = "y2"; type_ = String };
      Attribute { name = "yChannelSelector"; jsxName = "yChannelSelector"; reasonJsxName = "yChannelSelector"; type_ = String };
      Attribute { name = "z"; jsxName = "z"; reasonJsxName = "z"; type_ = String };
      Attribute { name = "zoomAndPan"; jsxName = "zoomAndPan"; reasonJsxName = "zoomAndPan"; type_ = String };
    ]

  let attributes = htmlAttributes @ filtersAttributes @ presentationAttributes @ stylingAttributes @ coreAttributes
end

let webViewHTMLAttributes =
  [
    Attribute { name = "allowfullscreen"; jsxName = "allowFullScreen"; reasonJsxName = "allowFullScreen"; type_ = Bool };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; reasonJsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "autoSize"; jsxName = "autoSize"; reasonJsxName = "autoSize"; type_ = Bool };
    Attribute { name = "blinkFeatures"; jsxName = "blinkFeatures"; reasonJsxName = "blinkFeatures"; type_ = String };
    Attribute { name = "disableBlinkFeatures"; jsxName = "disableBlinkFeatures"; reasonJsxName = "disableBlinkFeatures"; type_ = String };
    Attribute { name = "disableGuestResize"; jsxName = "disableGuestResize"; reasonJsxName = "disableGuestResize"; type_ = Bool };
    Attribute { name = "disableWebSecurity"; jsxName = "disableWebSecurity"; reasonJsxName = "disableWebSecurity"; type_ = Bool };
    Attribute { name = "guestInstance"; jsxName = "guestInstance"; reasonJsxName = "guestInstance"; type_ = String };
    Attribute { name = "httpReferrer"; jsxName = "httpReferrer"; reasonJsxName = "httpReferrer"; type_ = String };
    Attribute { name = "nodeIntegration"; jsxName = "nodeIntegration"; reasonJsxName = "nodeIntegration"; type_ = Bool };
    Attribute { name = "partition"; jsxName = "partition"; reasonJsxName = "partition"; type_ = String };
    Attribute { name = "plugins"; jsxName = "plugins"; reasonJsxName = "plugins"; type_ = Bool };
    Attribute { name = "preload"; jsxName = "preload"; reasonJsxName = "preload"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; reasonJsxName = "src"; type_ = String };
    Attribute { name = "userAgent"; jsxName = "userAgent"; reasonJsxName = "userAgent"; type_ = String };
    Attribute { name = "webPreferences"; jsxName = "webPreferences"; reasonJsxName = "webPreferences"; type_ = String };
  ]

let commonHtmlAttributes = elementAttributes @ reactAttributes @ globalAttributes @ globalEventHandlers @ ariaAttributes

let htmlElements =
  [
    { tag = "a"; attributes = commonHtmlAttributes @ anchorHTMLAttributes };
    { tag = "abbr"; attributes = commonHtmlAttributes };
    { tag = "address"; attributes = commonHtmlAttributes };
    { tag = "area"; attributes = commonHtmlAttributes @ areaHTMLAttributes };
    { tag = "article"; attributes = commonHtmlAttributes };
    { tag = "aside"; attributes = commonHtmlAttributes };
    { tag = "audio"; attributes = commonHtmlAttributes @ mediaHTMLAttributes };
    { tag = "b"; attributes = commonHtmlAttributes };
    { tag = "base"; attributes = commonHtmlAttributes @ baseHTMLAttributes };
    { tag = "bdi"; attributes = commonHtmlAttributes };
    { tag = "bdo"; attributes = commonHtmlAttributes };
    { tag = "big"; attributes = commonHtmlAttributes };
    { tag = "blockquote"; attributes = commonHtmlAttributes @ blockquoteHTMLAttributes };
    { tag = "body"; attributes = commonHtmlAttributes };
    { tag = "br"; attributes = commonHtmlAttributes };
    { tag = "button"; attributes = commonHtmlAttributes @ buttonHTMLAttributes };
    { tag = "canvas"; attributes = commonHtmlAttributes @ canvasHTMLAttributes };
    { tag = "caption"; attributes = commonHtmlAttributes };
    { tag = "cite"; attributes = commonHtmlAttributes };
    { tag = "code"; attributes = commonHtmlAttributes };
    { tag = "col"; attributes = commonHtmlAttributes @ colHTMLAttributes };
    { tag = "colgroup"; attributes = commonHtmlAttributes @ colgroupHTMLAttributes };
    { tag = "data"; attributes = commonHtmlAttributes @ dataHTMLAttributes };
    { tag = "datalist"; attributes = commonHtmlAttributes };
    { tag = "dd"; attributes = commonHtmlAttributes };
    { tag = "del"; attributes = commonHtmlAttributes @ delHTMLAttributes };
    { tag = "details"; attributes = commonHtmlAttributes @ detailsHTMLAttributes };
    { tag = "dfn"; attributes = commonHtmlAttributes };
    { tag = "dialog"; attributes = commonHtmlAttributes @ dialogHTMLAttributes };
    { tag = "div"; attributes = commonHtmlAttributes };
    { tag = "dl"; attributes = commonHtmlAttributes };
    { tag = "dt"; attributes = commonHtmlAttributes };
    { tag = "em"; attributes = commonHtmlAttributes };
    { tag = "embed"; attributes = commonHtmlAttributes @ embedHTMLAttributes };
    { tag = "fieldset"; attributes = commonHtmlAttributes @ fieldsetHTMLAttributes };
    { tag = "figcaption"; attributes = commonHtmlAttributes };
    { tag = "figure"; attributes = commonHtmlAttributes };
    { tag = "footer"; attributes = commonHtmlAttributes };
    { tag = "form"; attributes = commonHtmlAttributes @ formHTMLAttributes };
    { tag = "h1"; attributes = commonHtmlAttributes };
    { tag = "h2"; attributes = commonHtmlAttributes };
    { tag = "h3"; attributes = commonHtmlAttributes };
    { tag = "h4"; attributes = commonHtmlAttributes };
    { tag = "h5"; attributes = commonHtmlAttributes };
    { tag = "h6"; attributes = commonHtmlAttributes };
    { tag = "head"; attributes = commonHtmlAttributes };
    { tag = "header"; attributes = commonHtmlAttributes };
    { tag = "hgroup"; attributes = commonHtmlAttributes };
    { tag = "hr"; attributes = commonHtmlAttributes };
    { tag = "html"; attributes = commonHtmlAttributes @ htmlHTMLAttributes };
    { tag = "i"; attributes = commonHtmlAttributes };
    { tag = "iframe"; attributes = commonHtmlAttributes @ iframeHTMLAttributes };
    { tag = "img"; attributes = commonHtmlAttributes @ imgHTMLAttributes };
    { tag = "input"; attributes = commonHtmlAttributes @ inputHTMLAttributes };
    { tag = "ins"; attributes = commonHtmlAttributes @ insHTMLAttributes };
    { tag = "kbd"; attributes = commonHtmlAttributes };
    { tag = "keygen"; attributes = commonHtmlAttributes @ keygenHTMLAttributes };
    { tag = "label"; attributes = commonHtmlAttributes @ labelHTMLAttributes };
    { tag = "legend"; attributes = commonHtmlAttributes };
    { tag = "li"; attributes = commonHtmlAttributes @ liHTMLAttributes };
    { tag = "link"; attributes = commonHtmlAttributes @ linkHTMLAttributes };
    { tag = "main"; attributes = commonHtmlAttributes };
      { tag = "map"; attributes = commonHtmlAttributes @ mapHTMLAttributes };
    { tag = "mark"; attributes = commonHtmlAttributes };
    { tag = "menu"; attributes = commonHtmlAttributes @ menuHTMLAttributes };
    { tag = "menuitem"; attributes = commonHtmlAttributes };
    { tag = "meta"; attributes = commonHtmlAttributes @ metaHTMLAttributes };
    { tag = "meter"; attributes = commonHtmlAttributes @ meterHTMLAttributes };
    { tag = "nav"; attributes = commonHtmlAttributes };
    { tag = "noindex"; attributes = commonHtmlAttributes };
    { tag = "noscript"; attributes = commonHtmlAttributes };
    { tag = "object"; attributes = commonHtmlAttributes @ objectHTMLAttributes };
    { tag = "ol"; attributes = commonHtmlAttributes @ olHTMLAttributes };
    { tag = "optgroup"; attributes = commonHtmlAttributes @ optgroupHTMLAttributes };
    { tag = "option"; attributes = commonHtmlAttributes @ optionHTMLAttributes };
    { tag = "output"; attributes = commonHtmlAttributes @ outputHTMLAttributes };
    { tag = "p"; attributes = commonHtmlAttributes };
    { tag = "param"; attributes = commonHtmlAttributes @ paramHTMLAttributes };
    { tag = "picture"; attributes = commonHtmlAttributes };
    { tag = "pre"; attributes = commonHtmlAttributes };
    { tag = "progress"; attributes = commonHtmlAttributes @ progressHTMLAttributes };
    { tag = "q"; attributes = commonHtmlAttributes @ quoteHTMLAttributes };
    { tag = "rp"; attributes = commonHtmlAttributes };
    { tag = "rt"; attributes = commonHtmlAttributes };
    { tag = "ruby"; attributes = commonHtmlAttributes };
    { tag = "s"; attributes = commonHtmlAttributes };
    { tag = "samp"; attributes = commonHtmlAttributes };
    { tag = "script"; attributes = commonHtmlAttributes @ scriptHTMLAttributes };
    { tag = "section"; attributes = commonHtmlAttributes };
    { tag = "select"; attributes = commonHtmlAttributes @ selectHTMLAttributes };
    { tag = "slot"; attributes = commonHtmlAttributes @ slotHTMLAttributes };
    { tag = "small"; attributes = commonHtmlAttributes };
    { tag = "source"; attributes = commonHtmlAttributes @ sourceHTMLAttributes };
    { tag = "span"; attributes = commonHtmlAttributes };
    { tag = "strong"; attributes = commonHtmlAttributes };
    { tag = "style"; attributes = commonHtmlAttributes @ styleHTMLAttributes };
    { tag = "sub"; attributes = commonHtmlAttributes };
    { tag = "summary"; attributes = commonHtmlAttributes };
    { tag = "sup"; attributes = commonHtmlAttributes };
    { tag = "table"; attributes = commonHtmlAttributes @ tableHTMLAttributes };
    { tag = "tbody"; attributes = commonHtmlAttributes };
    { tag = "td"; attributes = commonHtmlAttributes @ tdHTMLAttributes };
    { tag = "template"; attributes = commonHtmlAttributes };
    { tag = "textarea"; attributes = commonHtmlAttributes @ textareaHTMLAttributes };
    { tag = "tfoot"; attributes = commonHtmlAttributes };
    { tag = "th"; attributes = commonHtmlAttributes @ thHTMLAttributes };
    { tag = "thead"; attributes = commonHtmlAttributes };
    { tag = "time"; attributes = commonHtmlAttributes @ timeHTMLAttributes };
    { tag = "title"; attributes = commonHtmlAttributes };
    { tag = "tr"; attributes = commonHtmlAttributes };
    { tag = "track"; attributes = commonHtmlAttributes @ trackHTMLAttributes };
    { tag = "u"; attributes = commonHtmlAttributes };
    { tag = "ul"; attributes = commonHtmlAttributes };
    { tag = "var"; attributes = commonHtmlAttributes };
    { tag = "video"; attributes = commonHtmlAttributes @ videoHTMLAttributes };
    { tag = "wbr"; attributes = commonHtmlAttributes };
    { tag = "webview"; attributes = commonHtmlAttributes @ webViewHTMLAttributes };
  ]

let commonSvgAttributes = SVG.attributes @ reactAttributes @ globalEventHandlers @ ariaAttributes

let feConvolveMatrixAttributes = [ Attribute { name = "preserveAlpha"; jsxName = "preserveAlpha"; reasonJsxName = "preserveAlpha"; type_ = BooleanishString } ]

let svgElements =
  [
    { tag = "svg"; attributes = commonSvgAttributes };
    { tag = "animate"; attributes = commonSvgAttributes };
    { tag = "animateMotion"; attributes = commonSvgAttributes };
    { tag = "animateTransform"; attributes = commonSvgAttributes };
    { tag = "circle"; attributes = commonSvgAttributes };
    { tag = "clipPath"; attributes = commonSvgAttributes };
    { tag = "defs"; attributes = commonSvgAttributes };
    { tag = "desc"; attributes = commonSvgAttributes };
    { tag = "ellipse"; attributes = commonSvgAttributes };
    { tag = "feBlend"; attributes = commonSvgAttributes };
    { tag = "feColorMatrix"; attributes = commonSvgAttributes };
    { tag = "feComponentTransfer"; attributes = commonSvgAttributes };
    { tag = "feComposite"; attributes = commonSvgAttributes };
    { tag = "feConvolveMatrix"; attributes = commonSvgAttributes @ feConvolveMatrixAttributes };
    { tag = "feDiffuseLighting"; attributes = commonSvgAttributes };
    { tag = "feDisplacementMap"; attributes = commonSvgAttributes };
    { tag = "feDistantLight"; attributes = commonSvgAttributes };
    { tag = "feDropShadow"; attributes = commonSvgAttributes };
    { tag = "feFlood"; attributes = commonSvgAttributes };
    { tag = "feFuncA"; attributes = commonSvgAttributes };
    { tag = "feFuncB"; attributes = commonSvgAttributes };
    { tag = "feFuncG"; attributes = commonSvgAttributes };
    { tag = "feFuncR"; attributes = commonSvgAttributes };
    { tag = "feGaussianBlur"; attributes = commonSvgAttributes };
    { tag = "feImage"; attributes = commonSvgAttributes };
    { tag = "feMerge"; attributes = commonSvgAttributes };
    { tag = "feMergeNode"; attributes = commonSvgAttributes };
    { tag = "feMorphology"; attributes = commonSvgAttributes };
    { tag = "feOffset"; attributes = commonSvgAttributes };
    { tag = "fePointLight"; attributes = commonSvgAttributes };
    { tag = "feSpecularLighting"; attributes = commonSvgAttributes };
    { tag = "feSpotLight"; attributes = commonSvgAttributes };
    { tag = "feTile"; attributes = commonSvgAttributes };
    { tag = "feTurbulence"; attributes = commonSvgAttributes };
    { tag = "filter"; attributes = commonSvgAttributes };
    { tag = "foreignObject"; attributes = commonSvgAttributes };
    { tag = "g"; attributes = commonSvgAttributes };
    { tag = "image"; attributes = commonSvgAttributes };
    { tag = "line"; attributes = commonSvgAttributes };
    { tag = "linearGradient"; attributes = commonSvgAttributes };
    { tag = "marker"; attributes = commonSvgAttributes };
    { tag = "mask"; attributes = commonSvgAttributes };
    { tag = "metadata"; attributes = commonSvgAttributes };
    { tag = "mpath"; attributes = commonSvgAttributes };
    { tag = "path"; attributes = commonSvgAttributes };
    { tag = "pattern"; attributes = commonSvgAttributes };
    { tag = "polygon"; attributes = commonSvgAttributes };
    { tag = "polyline"; attributes = commonSvgAttributes };
    { tag = "radialGradient"; attributes = commonSvgAttributes };
    { tag = "rect"; attributes = commonSvgAttributes };
    { tag = "stop"; attributes = commonSvgAttributes };
    { tag = "switch"; attributes = commonSvgAttributes };
    { tag = "symbol"; attributes = commonSvgAttributes };
    { tag = "text"; attributes = commonSvgAttributes };
    { tag = "textPath"; attributes = commonSvgAttributes };
    { tag = "tspan"; attributes = commonSvgAttributes };
    { tag = "use"; attributes = commonSvgAttributes };
    { tag = "view"; attributes = commonSvgAttributes };
  ]
[@@@ocamlformat "enable"]

let domAttributes = commonSvgAttributes @ commonHtmlAttributes
let elements = svgElements @ htmlElements
let getReasonJSXName = function Attribute { reasonJsxName; _ } -> reasonJsxName | Event { jsxName; _ } -> jsxName
let getJSXName = function Attribute { jsxName; _ } -> jsxName | Event { jsxName; _ } -> jsxName
let domPropNames = List.map getJSXName domAttributes

type errors = [ `ElementNotFound | `AttributeNotFound ]

let getAttributes tag =
  List.find_opt (fun element -> element.tag = tag) elements |> Option.to_result ~none:`ElementNotFound

let isDataAttribute = String.starts_with ~prefix:"data"

let camelcaseToKebabcase str =
  let len = String.length str in
  let is_upper c = c >= 'A' && c <= 'Z' in
  let is_lower c = c >= 'a' && c <= 'z' in
  let buf = Buffer.create (len + 4) in
  String.iteri
    (fun i c ->
      if c = '_' then Buffer.add_char buf '_'
      else if is_upper c then (
        let prev = if i > 0 then Some str.[i - 1] else None in
        let next_is_lower = i + 1 < len && is_lower str.[i + 1] in
        let starts_word = match prev with None | Some '_' -> false | Some p -> (not (is_upper p)) || next_is_lower in
        if starts_word then Buffer.add_char buf '-';
        Buffer.add_char buf (Char.lowercase_ascii c))
      else Buffer.add_char buf c)
    str;
  Buffer.contents buf

let findByJsxName ~tag name =
  let jsxName = name in
  let byReasonName p = getReasonJSXName p = jsxName in
  if isDataAttribute jsxName then
    let name = camelcaseToKebabcase jsxName in
    Ok (Attribute { name; jsxName = name; reasonJsxName = jsxName; type_ = String })
  else if jsxName = "styles" then Ok (Attribute { name; jsxName; reasonJsxName = jsxName; type_ = String })
  else
    match getAttributes tag with
    | Ok { attributes; _ } -> (
        match List.find_opt byReasonName attributes with Some p -> Ok p | None -> Error `AttributeNotFound)
    | Error err -> Error err

module Levenshtein = struct
  let minimum a b c = min a (min b c)

  let distance s t =
    let first = String.length s and second = String.length t in
    let matrix = Array.make_matrix (first + 1) (second + 1) 0 in
    for i = 0 to first do
      matrix.(i).(0) <- i
    done;
    for j = 0 to second do
      matrix.(0).(j) <- j
    done;
    for j = 1 to second do
      for i = 1 to first do
        if s.[i - 1] = t.[j - 1] then matrix.(i).(j) <- matrix.(i - 1).(j - 1)
        else matrix.(i).(j) <- minimum (matrix.(i - 1).(j) + 1) (matrix.(i).(j - 1) + 1) (matrix.(i - 1).(j - 1) + 1)
      done
    done;
    matrix.(first).(second)
end

let findClosestName invalid =
  let accumulate_distance name (bestName, bestDistance) =
    let distance = Levenshtein.distance invalid name in
    match distance < bestDistance with true -> (name, distance) | false -> (bestName, bestDistance)
  in
  let name, distance = List.fold_right accumulate_distance domPropNames ("", max_int) in
  if distance > 2 then None else Some name
