[@@@ocamlformat "disable"]
(* This file is more like a spreadsheet, prefer to keep it with margin=300.
   Since @@@ocamlformat "margin=300" isn't possible, we disable it *)

let ( & ) = List.append

type attributeType =
  | String
  | Int
  | Bool
  | BooleanishString (* `Booleanish_string` are JSX attributes represented as boolean values but rendered as strings on HTML https://github.com/facebook/react/blob/a17467e7e2cd8947c595d1834889b5d184459f12/packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js#L1165-L1176 *)
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
(* _onclick *)

type attribute = {
  type_ : attributeType;
  name : string;
  jsxName : string;
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
(* | Empty | NoReferrer | NoReferrerWhenDowngrade | Origin |
   OriginWhenCrossOrigin | SameOrigin | StrictOrigin |
   StrictOriginWhenCrossOrigin | UnsafeUrl *)

let attributeAnchorTarget = String
(* | Self | Blank | Parent | Top | Custom of String *)

let globalEventHandlers =
  (* https://developer.mozilla.org/en-US/docs/Web/Events/Event_handlers *)
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

(* All the WAI-ARIA 1.1 attributes from https://www.w3.org/TR/wai-aria-1.1/ *)
let ariaAttributes =
  [
    (* Identifies the currently active element when DOM focus is on a composite
       widget, textbox, group, or application. *)
    Attribute { name = "aria-activedescendant"; jsxName = "ariaActivedescendant"; type_ = String };

    (* Indicates whether assistive technologies will present all, or only parts
       of, the changed region based on the change notifications defined by the
       aria-relevant attribute. *)
    Attribute { name = "aria-atomic"; jsxName = "ariaAtomic"; type_ = BooleanishString };

    (* Indicates whether inputting text could trigger display of one or more predictions of the user's intended value for an input and specifies how predictions would be
     * presented if they are made.
     *)
    Attribute { name = "aria-autocomplete"; jsxName = "ariaAutocomplete"; type_ = String (* 'none' | 'inline' | 'list' | 'both' *) };

    (* Indicates an element is being modified and that assistive technologies
       MAY want to wait until the modifications are complete before exposing
       them to the user. *)
    Attribute { name = "aria-busy"; jsxName = "ariaBusy"; type_ = BooleanishString };

    (* Indicates the current "checked" state of checkboxes, radio buttons, and other
    widgets.
    * @see aria-pressed @see aria-selected.
    *)
    Attribute { name = "aria-checked"; jsxName = "ariaChecked"; type_ = String (* Bool | 'false' | 'mixed' | 'true' *) };

    (* Defines the total number of columns in a table, grid, or treegrid.
    * @see aria-colindex.
    *)
    Attribute { name = "aria-colcount"; jsxName = "ariaColcount"; type_ = Int };

    (* Defines an element's column index or position with respect to the total number of columns within a table,
    grid, or treegrid.
    * @see aria-colcount @see aria-colspan.
    *)
    Attribute { name = "aria-colindex"; jsxName = "ariaColindex"; type_ = Int };

    (* Defines the number of columns spanned by a cell or gridcell within a table, grid, or treegrid.
    * @see aria-colindex @see aria-rowspan.
    *)
    Attribute { name = "aria-colspan"; jsxName = "ariaColspan"; type_ = Int };

    (* Identifies the element (or elements) whose contents or presence are controlled by the current element.
    * @see aria-owns.
    *)
    Attribute { name = "aria-controls"; jsxName = "ariaControls"; type_ = String };

    (* Indicates the element that represents the current item within a container
       or set of related elements. *)
    Attribute { name = "aria-current"; jsxName = "ariaCurrent"; type_ = String (* Bool | 'false' | 'true' | 'page' | 'step' | 'location' | 'date' | 'time' *) };

    (* Identifies the element (or elements) that describes the object.
     * @see aria-labelledby
     *)
    Attribute { name = "aria-describedby"; jsxName = "ariaDescribedby"; type_ = String };

    (* Identifies the element that provides a detailed, extended description for
       the object. * @see aria-describedby. *)
    Attribute { name = "aria-details"; jsxName = "ariaDetails"; type_ = String };

    (* Indicates that the element is perceivable but disabled, so it is not editable or otherwise operable.
    * @see aria-hidden @see aria-readonly.
    *)
    Attribute { name = "aria-disabled"; jsxName = "ariaDisabled"; type_ = BooleanishString };

    (* Identifies the element that provides an error message for the object.
    * @see aria-invalid @see aria-describedby.
    *)
    Attribute { name = "aria-errormessage"; jsxName = "ariaErrormessage"; type_ = String };

    (* Indicates whether the element, or another grouping element it controls,
       is currently expanded or collapsed. *)
    Attribute { name = "aria-expanded"; jsxName = "ariaExpanded"; type_ = BooleanishString };

    (* Identifies the next element (or elements) in an alternate reading order of content which, at the user's discretion,
     * allows assistive technology to override the general default of reading in document source order.
     *)
    Attribute { name = "aria-flowto"; jsxName = "ariaFlowto"; type_ = String };

    (* Indicates the availability and type of interactive popup element, such as
       menu or dialog, that can be triggered by an element. *)
    Attribute { name = "aria-haspopup"; jsxName = "ariaHaspopup"; type_ = String (* Bool | 'false' | 'true' | 'menu' | 'listbox' | 'tree' | 'grid' | 'dialog'; *)};

    (* Indicates whether the element is exposed to an accessibility API.
     * @see aria-disabled.
     *)
    Attribute { name = "aria-hidden"; jsxName = "ariaHidden"; type_ = BooleanishString };

    (* Indicates the entered value does not conform to the format expected by the
    application.
    * @see aria-errormessage.
    *)
    Attribute { name = "aria-invalid"; jsxName = "ariaInvalid"; type_ = String (* Bool | 'false' | 'true' | 'grammar' | 'spelling'; *) };

    (* Indicates keyboard shortcuts that an author has implemented to activate
       or give focus to an element. *)
    Attribute { name = "aria-keyshortcuts"; jsxName = "ariaKeyshortcuts"; type_ = String };

    (* Defines a String value that labels the current element.
    * @see aria-labelledby.
    *)
    Attribute { name = "aria-label"; jsxName = "ariaLabel"; type_ = String };

    (* Identifies the element (or elements) that labels the current element.
    * @see aria-describedby.
    *)
    Attribute { name = "aria-labelledby"; jsxName = "ariaLabelledby"; type_ = String };

    (* Defines the hierarchical level of an element within a structure. *)
    Attribute { name = "aria-level"; jsxName = "ariaLevel"; type_ = Int };

    (* Indicates that an element will be updated, and describes the types of
       updates the user agents, assistive technologies, and user can expect ;rom
       the live region. *)
    Attribute { name = "aria-live"; jsxName = "ariaLive"; type_ = String (* 'off' | 'assertive' | 'polite' *) };

    (* Indicates whether an element is modal when displayed. *)

    Attribute { name = "aria-modal"; jsxName = "ariaModal"; type_ = BooleanishString };

    (* Indicates whether a text box accepts multiple lines of input or only a
       single line. *)
    Attribute { name = "aria-multiline"; jsxName = "ariaMultiline"; type_ = BooleanishString };

    (* Indicates that the user may select more than one item from the current
       selectable descendants. *)
    Attribute { name = "aria-multiselectable"; jsxName = "ariaMultiselectable"; type_ = BooleanishString };

    (* Indicates whether the element's orientation is horizontal, vertical, or
       unknown/ambiguous. *)
    Attribute { name = "aria-orientation"; jsxName = "ariaOrientation"; type_ = String (* 'horizontal' | 'vertical' *) };

    (* Identifies an element (or elements) in order to define a visual, functional, or contextual parent/child relationship
     * between DOM elements where the DOM hierarchy cannot be used to represent the relationship.
     * @see aria-controls.
     *)
    Attribute { name = "aria-owns"; jsxName = "ariaOwns"; type_ = String };

    (* Defines a short hint (a word or short phrase) intended to aid the user with data entry when the control has no
    value.
    * A hint could be a sample value or a brief description of the expected format.
    *)
    Attribute { name = "aria-placeholder"; jsxName = "ariaPlaceholder"; type_ = String };

    (* Defines an element's number or position in the current set of listitems
       or treeitems. Not required if all elements in the set are present in the
       DOM. * @see aria-setsize. *)
    Attribute { name = "aria-posinset"; jsxName = "ariaPosinset"; type_ = Int };

    (* Indicates the current "pressed" state of toggle buttons.
    * @see aria-checked @see aria-selected.
    *)
    Attribute { name = "aria-pressed"; jsxName = "ariaPressed"; type_ = String (* Bool | 'false' | 'mixed' | 'true' *) };

    (* Indicates that the element is not editable, but is otherwise
    operable.
    * @see aria-disabled.
    *)
    Attribute { name = "aria-readonly"; jsxName = "ariaReadonly"; type_ = BooleanishString };

    (* Indicates what notifications the user agent will trigger when the
    accessibility tree within a live region is modified.
    * @see aria-atomic.
    *)
    Attribute { name = "aria-relevant"; jsxName = "ariaRelevant"; type_ = String (* 'additions' | 'additions removals' | 'additions text' | 'all' | 'removals' | 'removals additions' | 'removals text' | 'text' | 'text additions' | 'text removals' *) };

    (* Indicates that user input is required on the element before a form may be
       submitted. *)
    Attribute { name = "aria-required"; jsxName = "ariaRequired"; type_ = BooleanishString };

    (* Defines a human-readable, author-localized description for the role of an
       element. *)
    Attribute { name = "aria-roledescription"; jsxName = "ariaRoledescription"; type_ = String };

    (* Defines the total number of rows in a table, grid, or treegrid.
    * @see aria-rowindex.
    *)
    Attribute { name = "aria-rowcount"; jsxName = "ariaRowcount"; type_ = Int };

    (* Defines an element's row index or position with respect to the total number of rows within a table, grid, or
    treegrid.
    * @see aria-rowcount @see aria-rowspan.
    *)
    Attribute { name = "aria-rowindex"; jsxName = "ariaRowindex"; type_ = Int };

    (* *)

    Attribute { name = "aria-rowindextext"; jsxName = "ariaRowindextext"; type_ = String };

    (* Defines the number of rows spanned by a cell or gridcell within a table, grid, or treegrid.
    * @see aria-rowindex @see aria-colspan.
    *)
    Attribute { name = "aria-rowspan"; jsxName = "ariaRowspan"; type_ = Int };

    (* Indicates the current "selected" state of various widgets.
    * @see aria-checked @see aria-pressed.
    *)
    Attribute { name = "aria-selected"; jsxName = "ariaSelected"; type_ = BooleanishString };

    (* Defines the number of items in the current set of listitems or treeitems.
    Not required if all elements in the set are present in the DOM.
    * @see aria-posinset.
    *)
    Attribute { name = "aria-setsize"; jsxName = "ariaSetsize"; type_ = Int };

    (* Indicates if items in a table or grid are sorted in ascending or
       descending order. *)
    Attribute { name = "aria-sort"; jsxName = "ariaSort"; type_ = String (* 'none' | 'ascending' | 'descending' | 'other' *) };

    (* Defines the maximum allowed value for a range widget. *)

    Attribute { name = "aria-valuemax"; jsxName = "ariaValuemax"; type_ = Int };

    (* Defines the minimum allowed value for a range widget. *)

    Attribute { name = "aria-valuemin"; jsxName = "ariaValuemin"; type_ = Int };

    (* Defines the current value for a range widget.
    * @see aria-valuetext.
    *)
    Attribute { name = "aria-valuenow"; jsxName = "ariaValuenow"; type_ = Int };

    (* Defines the human readable text alternative of aria-valuenow for a range
       widget. *)
    Attribute { name = "aria-valuetext"; jsxName = "ariaValuetext"; type_ = String };

  ]

(* All the WAI-ARIA 1.1 role attribute values from
   https://www.w3.org/TR/wai-aria-1.1/#role_definitions *)
let ariaRole = String
(* | Alert | Alertdialog | Application | Article | Banner | Button | Cell |
   Checkbox | Columnheader | Combobox | Complementary | Contentinfo | Definition
   | Dialog | Directory | Document | Feed | Figure | Form | Grid | Gridcell |
   Group | Heading | Img | Link | List | Listbox | Listitem | Log | Main |
   Marquee | Math | Menu | Menubar | Menuitem | Menuitemcheckbox | Menuitemradio
   | Navigation | None | Note | Option | Presentation | Progressbar | Radio |
   Radiogroup | Region | Row | Rowgroup | Rowheader | Scrollbar | Search |
   Searchbox | Separator | Slider | Spinbutton | Status | Switch | Tab | Table |
   Tablist | Tabpanel | Term | Textbox | Timer | Toolbar | Tooltip | Tree |
   Treegrid | Treeitem | Custom of String *)

let reactValidHtml =
  [
    Attribute { name = "class"; jsxName = "className"; type_ = String };
    Attribute { name = "checked"; jsxName = "defaultChecked"; type_ = Bool };
    Attribute { name = "selected"; jsxName = "defaultSelected"; type_ = Bool };
    Attribute { name = "value"; jsxName = "defaultValue"; type_ = String (* | number | ReadonlyArray<String> *) };
  ]

let reactAttributes =
  [
    (* https://reactjs.org/docs/dom-elements.html *)
    Attribute { name = "dangerouslySetInnerHTML"; jsxName = "dangerouslySetInnerHTML"; type_ = InnerHtml };
    Attribute { name = "ref"; jsxName = "ref"; type_ = Ref };
    Attribute { name = "key"; jsxName = "key"; type_ = String };
    Attribute { name = "suppressContentEditableWarning"; jsxName = "suppressContentEditableWarning"; type_ = Bool };
    Attribute { name = "suppressHydrationWarning"; jsxName = "suppressHydrationWarning"; type_ = Bool };
  ]
  & reactValidHtml

let globalAttributes =
  [
    (* https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes *)
    (* Standard HTML Attributes *)
    Attribute { name = "accesskey"; jsxName = "accessKey"; type_ = String };
    Attribute { name = "autocapitalize"; jsxName = "autoCapitalize"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = String };
    Attribute { name = "contextmenu"; jsxName = "contextMenu"; type_ = String };
    Attribute { name = "contenteditable"; jsxName = "contentEditable"; type_ = BooleanishString };
    Attribute { name = "dir"; jsxName = "dir"; type_ = String };
    Attribute { name = "draggable"; jsxName = "draggable"; type_ = BooleanishString };
    Attribute { name = "hidden"; jsxName = "hidden"; type_ = Bool };
    Attribute { name = "id"; jsxName = "id"; type_ = String };
    Attribute { name = "itemprop"; jsxName = "itemProp"; type_ = String };
    Attribute { name = "itemscope"; jsxName = "itemScope"; type_ = Bool };
    Attribute { name = "itemtype"; jsxName = "itemType"; type_ = String };
    Attribute { name = "itemid"; jsxName = "itemID"; type_ = String };
    Attribute { name = "itemref"; jsxName = "itemRef"; type_ = String };
    Attribute { name = "lang"; jsxName = "lang"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String };
    Attribute { name = "part"; jsxName = "part"; type_ = String };
    Attribute { name = "nonce"; jsxName = "nonce"; type_ = String };
    Attribute { name = "slot"; jsxName = "slot"; type_ = String };
    Attribute { name = "spellcheck"; jsxName = "spellCheck"; type_ = BooleanishString };
    Attribute { name = "style"; jsxName = "style"; type_ = Style };
    Attribute { name = "tabindex"; jsxName = "tabIndex"; type_ = Int };
    Attribute { name = "enterkeyhint"; jsxName = "enterKeyHint"; type_ = Int };
    (* data-* attributes are globaly available *)
    (* Experimental ; Attribute {name= "exportParts"; jsxName= "exportParts";
       type_= Int} *)
    Attribute { name = "title"; jsxName = "title"; type_ = String };
    Attribute { name = "translate"; jsxName = "translate"; type_ = String (* 'yes' | 'no' *) };

    (* Living Standard * Hints at the type of data that might be entered by the
       user while editing the element or its contents * @see
       https://html.spec.whatwg.org/multipage/interaction.html#input-modalities:-the-inputmode-attribute *)
    Attribute { name = "inputmode"; jsxName = "inputMode"; type_ = String (* 'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search' *) };

    (* Specify that a standard HTML element should behave like a defined custom
       built-in element * @see
       https://html.spec.whatwg.org/multipage/custom-elements.html#attr-is *)
    Attribute { name = "is"; jsxName = "is"; type_ = String };
  ]

let elementAttributes =
  [
    (* Attribute { name = "radioGroup"; jsxName = "radioGroup"; type_ = String }; Does it exist? *)

    (* WAI-ARIA *)
    Attribute { name = "role"; jsxName = "role"; type_ = ariaRole };

    (* RDFa Attributes *)
    Attribute { name = "about"; jsxName = "about"; type_ = String };
    (* Attribute { name = "dataType"; jsxName = "dataType"; type_ = String }; *)
    Attribute { name = "inlist"; jsxName = "inlist"; type_ = String (* any *) };
    Attribute { name = "prefix"; jsxName = "prefix"; type_ = String };
    Attribute { name = "property"; jsxName = "property"; type_ = String };
    Attribute { name = "resource"; jsxName = "resource"; type_ = String };
    Attribute { name = "typeof"; jsxName = "typeof"; type_ = String };
    Attribute { name = "vocab"; jsxName = "vocab"; type_ = String };

    (* Non-standard Attributes *)
    (* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input#autocorrect *)
    Attribute { name = "autocorrect"; jsxName = "autoCorrect"; type_ = String };
    (* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input#attr-autosave *)
    Attribute { name = "autosave"; jsxName = "autoSave"; type_ = String };
    Attribute { name = "color"; jsxName = "color"; type_ = String };
    Attribute { name = "results"; jsxName = "results"; type_ = Int };
    Attribute { name = "security"; jsxName = "security"; type_ = String };
  ]

let anchorHTMLAttributes =
  [
    Attribute { name = "download"; jsxName = "download"; type_ = String (* any *) };
    Attribute { name = "href"; jsxName = "href"; type_ = String };
    Attribute { name = "hrefLang"; jsxName = "hrefLang"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; type_ = String };
    Attribute { name = "ping"; jsxName = "ping"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; type_ = attributeAnchorTarget };
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
  ]

let areaHTMLAttributes =
  [
    Attribute { name = "alt"; jsxName = "alt"; type_ = String };
    Attribute { name = "coords"; jsxName = "coords"; type_ = String };
    Attribute { name = "download"; jsxName = "download"; type_ = String (* any *) };
    Attribute { name = "href"; jsxName = "href"; type_ = String };
    Attribute { name = "hreflang"; jsxName = "hrefLang"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; type_ = String };
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
    Attribute { name = "rel"; jsxName = "rel"; type_ = String };
    Attribute { name = "shape"; jsxName = "shape"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; type_ = String };
  ]

let baseHTMLAttributes =
  [
    Attribute { name = "href"; jsxName = "href"; type_ = String };
    Attribute { name = "target"; jsxName = "target"; type_ = String };
  ]

let blockquoteHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button *)
let buttonHTMLAttributes =
  [
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; type_ = Bool };
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "formaction"; jsxName = "formAction"; type_ = String };
    Attribute { name = "formenctype"; jsxName = "formEncType"; type_ = String };
    (* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#method *)
    Attribute { name = "formmethod"; jsxName = "formMethod"; type_ = String };
    Attribute { name = "formnovalidate"; jsxName = "formNoValidate"; type_ = Bool };
    Attribute { name = "formtarget"; jsxName = "formTarget"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "popovertarget"; jsxName = "popoverTarget"; type_ = String };
    Attribute { name = "popovertargetaction"; jsxName = "popoverTargetAction"; type_ = String };
    Attribute { name = "type"; jsxName = "type_"; type_ = String (* 'submit' | 'reset' | 'button' *) };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
  ]

let canvasHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) }
  ]

let colHTMLAttributes =
  [
    Attribute { name = "span"; jsxName = "span"; type_ = Int (* number *) };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) }
  ]

let colgroupHTMLAttributes =
  [
    Attribute { name = "span"; jsxName = "span"; type_ = Int (* number *) }
  ]

let dataHTMLAttributes =
  [
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details *)
let detailsHTMLAttributes =
  [
    Attribute { name = "open"; jsxName = "open"; type_ = Bool }; Event { jsxName = "onToggle"; type_ = Media }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/del *)
let delHTMLAttributes =
  [
    Attribute { name = "cite"; type_ = String; jsxName = "cite" };
    Attribute { name = "datetime"; type_ = String; jsxName = "dateTime" }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog *)
let dialogHTMLAttributes =
  [
    Attribute { name = "open"; jsxName = "open"; type_ = Bool }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/embed *)
let embedHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *); };
    Attribute { name = "src"; jsxName = "src"; type_ = String; };
    Attribute { name = "type"; jsxName = "type"; type_ = String; };
    Attribute { name = "width"; type_ = String (* number | *); jsxName = "width" };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fieldset *)
let fieldsetHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form *)
let formHTMLAttributes =
  [
    Attribute { name = "accept"; jsxName = "accept"; type_ = String };
    Attribute { name = "accept-charset"; jsxName = "acceptCharset"; type_ = String };
    Attribute { name = "autocapitalize"; jsxName = "autoCapitalize"; type_ = String };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; type_ = String };
    Attribute { name = "enctype"; jsxName = "encType"; type_ = String };
    Attribute { name = "action"; jsxName = "action"; type_ = String };
    Attribute { name = "method"; jsxName = "method_"; type_ = String };
    Attribute { name = "novalidate"; jsxName = "noValidate"; type_ = Bool };
    Attribute { name = "target"; jsxName = "target"; type_ = String };
  ]

let htmlHTMLAttributes =
  [
    Attribute { name = "manifest"; jsxName = "manifest"; type_ = String };
  ]

let iframeHTMLAttributes =
  [
    Attribute { name = "allow"; jsxName = "allow"; type_ = String };
    Attribute { name = "allowfullscreen"; jsxName = "allowFullScreen"; type_ = Bool };
    Attribute { name = "allowtransparency"; jsxName = "allowTransparency"; type_ = Bool };
    Attribute { name = "csp"; jsxName = "csp"; type_ = String };
    Attribute { name = "credentialless"; jsxName = "credentialLess"; type_ = String };
    Attribute { name = "loading"; jsxName = "loading"; type_ = String };
    Attribute { name = "sandbox"; jsxName = "sandbox"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "sandbox"; jsxName = "sandbox"; type_ = String };
    Attribute { name = "seamless"; jsxName = "seamless"; type_ = Bool };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "srcdoc"; jsxName = "srcDoc"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    (* Deprecated attributes *)
    Attribute { name = "align"; jsxName = "align"; type_ = String };
    Attribute { name = "longdesc"; jsxName = "longDesc"; type_ = String };
    Attribute { name = "frameborder"; jsxName = "frameBorder"; type_ = String (* number | *) };
    Attribute { name = "marginheight"; jsxName = "marginHeight"; type_ = Int (* number *) };
    Attribute { name = "marginwidth"; jsxName = "marginWidth"; type_ = Int (* number *) };
    Attribute { name = "scrolling"; jsxName = "scrolling"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img *)
let imgHTMLAttributes =
  [
    Attribute { name = "alt"; jsxName = "alt"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String (* "anonymous" | "use-credentials" | "" *) };
    Attribute { name = "elementtiming"; jsxName = "elementTiming"; type_ = String };
    Attribute { name = "fetchpriority"; jsxName = "fetchPriority"; type_ = String };
    Attribute { name = "loading"; jsxName = "loading"; type_ = String };
    Attribute { name = "ismap"; jsxName = "isMap"; type_ = Bool };
    Attribute { name = "decoding"; jsxName = "decoding"; type_ = String (* "async" | "auto" | "sync" *) };
    Attribute { name = "sizes"; jsxName = "sizes"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "srcset"; jsxName = "srcset"; type_ = String };
    Attribute { name = "usemap"; jsxName = "usemap"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    (* Deprecated *)
    (* align, border, hspace, longdesc, name, vspace *)
  ]

let insHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; type_ = String };
    Attribute { name = "datetime"; jsxName = "datetime"; type_ = String };
  ]

let inputTypeAttribute = String
(* | 'button' | 'checkbox' | 'color' | 'date' | 'datetime-local' | 'email' |
   'file' | 'hidden' | 'image' | 'month' | 'number' | 'password' | 'radio' |
   'range' | 'reset' | 'search' | 'submit' | 'tel' | 'text' | 'time' | 'url' |
   'week' | (String & {}); *)

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input *)
let inputHTMLAttributes =
  [
    Attribute { name = "accept"; jsxName = "accept"; type_ = String };
    Attribute { name = "alt"; jsxName = "alt"; type_ = String };
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "capture"; jsxName = "capture"; type_ = String (* Bool | *) (* https://www.w3.org/TR/html-media-capture/ *) };
    Attribute { name = "checked"; jsxName = "checked"; type_ = Bool };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String };
    Attribute { name = "dirname"; jsxName = "dirname"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "formaction"; jsxName = "formAction"; type_ = String };
    Attribute { name = "formenctype"; jsxName = "formEncType"; type_ = String };
    Attribute { name = "method"; jsxName = "formMethod"; type_ = String };
    Attribute { name = "novalidate"; jsxName = "formNoValidate"; type_ = Bool };
    Attribute { name = "target"; jsxName = "formTarget"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "list"; jsxName = "list"; type_ = String };
    Attribute { name = "max"; jsxName = "max"; type_ = String (* number | *) };
    Attribute { name = "maxlength"; jsxName = "maxLength"; type_ = Int (* number *) };
    Attribute { name = "min"; jsxName = "min"; type_ = String (* number | *) };
    Attribute { name = "minlength"; jsxName = "minLength"; type_ = Int (* number *) };
    Attribute { name = "multiple"; jsxName = "multiple"; type_ = Bool };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "pattern"; jsxName = "pattern"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String };
    Attribute { name = "readonly"; jsxName = "readOnly"; type_ = Bool };
    Attribute { name = "required"; jsxName = "required"; type_ = Bool };
    Attribute { name = "size"; jsxName = "size"; type_ = Int (* number *) };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "step"; jsxName = "step"; type_ = String (* number | *) };
    Attribute { name = "type"; jsxName = "type_"; type_ = inputTypeAttribute };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    (* Added by React, oninput is the HTML *)
    Event { jsxName = "onChange"; type_ = Form };
  ]

let keygenHTMLAttributes =
  [
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "challenge"; jsxName = "challenge"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "keytype"; jsxName = "keyType"; type_ = String };
    Attribute { name = "keyparams"; jsxName = "keyParams"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
  ]

let labelHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "for"; jsxName = "htmlFor"; type_ = String };
  ]

let liHTMLAttributes =
  [
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link *)
let linkHTMLAttributes =
  [
    Attribute { name = "as"; jsxName = "as_"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String };
    Attribute { name = "blocking"; jsxName = "blocking"; type_ = Bool }; (* Experimental *)
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }; (* Deprecated *)
    Attribute { name = "fetchpriority"; jsxName = "fetchPriority"; type_ = String }; (* Experimental *)
    Attribute { name = "referrerpolicy"; jsxName = "referrerPolicy"; type_ = attributeReferrerPolicy };
    Attribute { name = "href"; jsxName = "href"; type_ = String };
    Attribute { name = "hreflang"; jsxName = "hrefLang"; type_ = String };
    Attribute { name = "integrity"; jsxName = "integrity"; type_ = String };
    Attribute { name = "imagesizes"; jsxName = "imageSizes"; type_ = String };
    Attribute { name = "imagesrcset"; jsxName = "imageSrcSet"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; type_ = String };
    Attribute { name = "rel"; jsxName = "rel"; type_ = String };
    Attribute { name = "title"; jsxName = "title"; type_ = String };
    Attribute { name = "sizes"; jsxName = "sizes"; type_ = String };
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
    Attribute { name = "charset"; jsxName = "charSet"; type_ = String }; (* non standard *)
  ]

let mapHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; type_ = String };
  ]

let menuHTMLAttributes =
  [
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
  ]

(* isn't validated with mdn *)
let mediaHTMLAttributes =
  [
    Attribute { name = "autoplay"; jsxName = "autoPlay"; type_ = Bool };
    Attribute { name = "controls"; jsxName = "controls"; type_ = Bool };
    Attribute { name = "controlslist"; jsxName = "controlsList"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String };
    Attribute { name = "loop"; jsxName = "loop"; type_ = Bool };
    (* deprecated *)
    Attribute { name = "mediagroup"; jsxName = "mediaGroup"; type_ = String };
    Attribute { name = "muted"; jsxName = "muted"; type_ = Bool };
    Attribute { name = "playsinline"; jsxName = "playsInline"; type_ = Bool };
    Attribute { name = "preload"; jsxName = "preload"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta *)
let metaHTMLAttributes =
  [
    Attribute { name = "charset"; jsxName = "charSet"; type_ = String };
    Attribute { name = "content"; jsxName = "content"; type_ = String };
    Attribute { name = "http-eequiv"; jsxName = "httpEquiv"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "media"; jsxName = "media"; type_ = String };
  ]

let meterHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "high"; jsxName = "high"; type_ = Int (* number *) };
    Attribute { name = "low"; jsxName = "low"; type_ = Int (* number *) };
    Attribute { name = "max"; jsxName = "max"; type_ = String (* number | *) };
    Attribute { name = "min"; jsxName = "min"; type_ = String (* number | *) };
    Attribute { name = "optimum"; jsxName = "optimum"; type_ = Int (* number *) };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
  ]

let quoteHTMLAttributes =
  [
    Attribute { name = "cite"; jsxName = "cite"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object *)
(* TODO: lacks a few *)
let objectHTMLAttributes =
  [
    Attribute { name = "classid"; jsxName = "classID"; type_ = String };
    Attribute { name = "data"; jsxName = "data"; type_ = String };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
    Attribute { name = "usemap"; jsxName = "useMap"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    Attribute { name = "wmode"; jsxName = "wmode"; type_ = String };
  ]

let olHTMLAttributes =
  [
    Attribute { name = "reversed"; jsxName = "reversed"; type_ = Bool };
    Attribute { name = "start"; jsxName = "start"; type_ = Int (* number *) };
    Attribute { name = "type"; jsxName = "type_"; type_ = String (* '1' | 'a' | 'A' | 'i' | 'I' *) };
  ]

let optgroupHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "label"; jsxName = "label"; type_ = String };
  ]

let optionHTMLAttributes =
  [
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "label"; jsxName = "label"; type_ = String };
    Attribute { name = "selected"; jsxName = "selected"; type_ = Bool };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
  ]

let outputHTMLAttributes =
  [
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "for"; jsxName = "htmlFor"; type_ = String };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
  ]

let paramHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
  ]

let progressHTMLAttributes =
  [
    Attribute { name = "max"; jsxName = "max"; type_ = String (* number | *) };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
  ]

let slotHTMLAttributes =
  [
    Attribute { name = "name"; jsxName = "name"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script *)
let scriptHTMLAttributes =
  [
    Attribute { name = "async"; jsxName = "async"; type_ = Bool };
    Attribute { name = "charset"; jsxName = "charSet"; type_ = String };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String };
    Attribute { name = "defer"; jsxName = "defer"; type_ = Bool };
    Attribute { name = "integrity"; jsxName = "integrity"; type_ = String };
    Attribute { name = "nomodule"; jsxName = "noModule"; type_ = Bool };
    Attribute { name = "nonce"; jsxName = "nonce"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
  ]

let selectHTMLAttributes =
  [
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "multiple"; jsxName = "multiple"; type_ = Bool };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "required"; jsxName = "required"; type_ = Bool };
    Attribute { name = "size"; jsxName = "size"; type_ = Int (* number *) };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
    Event { jsxName = "onChange"; type_ = Form };
  ]

let sourceHTMLAttributes =
  [
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "media"; jsxName = "media"; type_ = String };
    Attribute { name = "sizes"; jsxName = "sizes"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "srcset"; jsxName = "srcSet"; type_ = String };
    Attribute { name = "type"; jsxName = "type_"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
  ]

let styleHTMLAttributes =
  [
    Attribute { name = "media"; jsxName = "media"; type_ = String };
    Attribute { name = "nonce"; jsxName = "nonce"; type_ = String };
    Attribute { name = "scoped"; jsxName = "scoped"; type_ = Bool };
    Attribute { name = "type"; jsxName = "type_"; type_ = String }
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/table *)
(* All attributes are deprecated *)
let tableHTMLAttributes =
  [
    Attribute { name = "cellpadding"; jsxName = "cellPadding"; type_ = String (* number | *) };
    Attribute { name = "cellspacing"; jsxName = "cellSpacing"; type_ = String (* number | *) };
    Attribute { name = "summary"; jsxName = "summary"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea *)
let textareaHTMLAttributes =
  [
    Attribute { name = "autocomplete"; jsxName = "autoComplete"; type_ = String };
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = String };
    Attribute { name = "cols"; jsxName = "cols"; type_ = Int (* number *) };
    Attribute { name = "dirName"; jsxName = "dirName"; type_ = String };
    Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool };
    Attribute { name = "form"; jsxName = "form"; type_ = String };
    Attribute { name = "maxlength"; jsxName = "maxLength"; type_ = Int (* number *) };
    Attribute { name = "minlength"; jsxName = "minLength"; type_ = Int (* number *) };
    Attribute { name = "name"; jsxName = "name"; type_ = String };
    Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String };
    Attribute { name = "readonly"; jsxName = "readOnly"; type_ = Bool };
    Attribute { name = "required"; jsxName = "required"; type_ = Bool };
    Attribute { name = "rows"; jsxName = "rows"; type_ = Int (* number *) };
    Attribute { name = "value"; jsxName = "value"; type_ = String (* | ReadonlyArray<String> | number *) };
    Attribute { name = "wrap"; jsxName = "wrap"; type_ = String };
    Event { jsxName = "onChange"; type_ = Form };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/td *)
(* TODO: Add a few deprecated attrs *)
let tdHTMLAttributes =
  [
    Attribute { name = "align"; jsxName = "align"; type_ = String (* type_= "left" | "center" | "right" | "justify" | "char" *) };
    Attribute { name = "colspan"; jsxName = "colSpan"; type_ = Int (* number *) };
    Attribute { name = "headers"; jsxName = "headers"; type_ = String };
    Attribute { name = "rowspan"; jsxName = "rowspan"; type_ = Int (* number *) };
    Attribute { name = "scope"; jsxName = "scope"; type_ = String };
    Attribute { name = "abbr"; jsxName = "abbr"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    Attribute { name = "valign"; jsxName = "valign"; type_ = String (* "top" | "middle" | "bottom" | "baseline" *) };
  ]

let thHTMLAttributes =
  [
    Attribute { name = "align"; jsxName = "align"; type_ = String (* "left" | "center" | "right" | "justify" | "char" *) };
    Attribute { name = "colspan"; jsxName = "colSpan"; type_ = Int (* number *) };
    Attribute { name = "headers"; jsxName = "headers"; type_ = String };
    Attribute { name = "rowspan"; jsxName = "rowSpan"; type_ = Int (* number *) };
    Attribute { name = "scope"; jsxName = "scope"; type_ = String };
    Attribute { name = "abbr"; jsxName = "abbr"; type_ = String };
  ]

let timeHTMLAttributes =
  [
    Attribute { name = "datetime"; jsxName = "datetime"; type_ = String };
  ]

let trackHTMLAttributes =
  [
    Attribute { name = "default"; jsxName = "default"; type_ = Bool };
    Attribute { name = "kind"; jsxName = "kind"; type_ = String };
    Attribute { name = "label"; jsxName = "label"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "srclang"; jsxName = "srclang"; type_ = String };
  ]

(* https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video *)
let videoHTMLAttributes =
  [
    Attribute { name = "autoplay"; jsxName = "autoPlay"; type_ = Bool };
    Attribute { name = "controls"; jsxName = "controls"; type_ = Bool };
    Attribute { name = "crossorigin"; jsxName = "crossOrigin"; type_ = String };
    Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
    Attribute { name = "playsinline"; jsxName = "playsInline"; type_ = Bool };

    Attribute { name = "loop"; jsxName = "loop"; type_ = Bool };
    Attribute { name = "poster"; jsxName = "poster"; type_ = String };
    Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
    Attribute { name = "disablepictureinpicture"; jsxName = "disablePictureInPicture"; type_ = Bool };
    Attribute { name = "disableremoteplayback"; jsxName = "disableRemotePlayback"; type_ = Bool };
  ]

module SVG = struct
  (* "https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/" *)

  let coreAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Core *)
    [
      Attribute { name = "id"; jsxName = "id"; type_ = String };
      Attribute { name = "lang"; jsxName = "lang"; type_ = String };
      Attribute { name = "tabindex"; jsxName = "tabIndex"; type_ = String };
      Attribute { name = "xml:base"; jsxName = "xmlBase"; type_ = String };
      Attribute { name = "xml:lang"; jsxName = "xmlLang"; type_ = String };
      Attribute { name = "xml:space"; jsxName = "xmlSpace"; type_ = String };
    ]

  let stylingAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Styling *)
    [
      Attribute { name = "class"; jsxName = "className"; type_ = String };
      Attribute { name = "style"; jsxName = "style"; type_ = Style }
    ]

  let presentationAttributes =
    (* Presentation attributes *)
    [
      Attribute { name = "alignment-baseline"; jsxName = "alignmentBaseline"; type_ = String (* "auto" | "baseline" | "before-edge" | "text-before-edge" | "middle" | "central" | "after-edge" "text-after-edge" | "ideographic" | "alphabetic" | "hanging" | "mathematical" | "inherit" *) };
      Attribute { name = "baseline-shift"; jsxName = "baselineShift"; type_ = String (* "auto" | "baseline" | "before-edge" | "text-before-edge" | "middle" | "central" | "after-edge" "text-after-edge" | "ideographic" | "alphabetic" | "hanging" | "mathematical" | "inherit" *) };
      Attribute { name = "clip"; jsxName = "clip"; type_ = String (* number | *) };
      Attribute { name = "clip-path"; jsxName = "clipPath"; type_ = (* none|<FuncIRI>|inherit *) String };
      Attribute { name = "clip-rule"; jsxName = "clipRule"; type_ = (* number | "linearRGB" | "inherit" *) String };
      Attribute { name = "color"; jsxName = "color"; type_ = String (* number | *) };
      Attribute { name = "color-interpolation"; jsxName = "colorInterpolation"; type_ = String };
      Attribute { name = "color-interpolation-filters"; jsxName = "colorInterpolationFilters"; type_ = String };
      Attribute { name = "color-profile"; jsxName = "colorProfile"; type_ = String (* number | *) };
      Attribute { name = "color-rendering"; jsxName = "colorRendering"; type_ = String (* number | *) };
      Attribute { name = "cursor"; jsxName = "cursor"; type_ = String (* number | *) };
      Attribute { name = "direction"; jsxName = "direction"; type_ = String (* number | *) };
      Attribute { name = "display"; jsxName = "display"; type_ = String (* number | *) };
      Attribute { name = "divisor"; jsxName = "divisor"; type_ = String (* number | *) };
      Attribute { name = "dominant-baseline"; jsxName = "dominantBaseline"; type_ = String };
      Attribute { name = "enable-background"; jsxName = "enableBackground"; type_ = String };
      Attribute { name = "fill"; jsxName = "fill"; type_ = String };
      Attribute { name = "fill-opacity"; jsxName = "fillOpacity"; type_ = String (* number | *) };
      Attribute { name = "fill-rule"; jsxName = "fillRule"; type_ = String (* type_= "nonzero" | "evenodd" | "inherit" *) };
      Attribute { name = "filter"; jsxName = "filter"; type_ = String };
      Attribute { name = "flood-color"; jsxName = "floodColor"; type_ = String (* number | *) };
      Attribute { name = "flood-opacity"; jsxName = "floodOpacity"; type_ = String (* number | *) };
      Attribute { name = "font-family"; jsxName = "fontFamily"; type_ = String };
      Attribute { name = "font-size"; jsxName = "fontSize"; type_ = String (* number | *) };
      Attribute { name = "font-size-adjust"; jsxName = "fontSizeAdjust"; type_ = String };
      Attribute { name = "font-stretch"; jsxName = "fontStretch"; type_ = String (* number | *) };
      Attribute { name = "font-style"; jsxName = "fontStyle"; type_ = String (* number | *) };
      Attribute { name = "font-variant"; jsxName = "fontVariant"; type_ = String (* number | *) };
      Attribute { name = "font-weight"; jsxName = "fontWeight"; type_ = String (* number | *) };
      Attribute { name = "glyph-orientation-horizontal"; jsxName = "glyphOrientationHorizontal"; type_ = String (* number | *) };
      Attribute { name = "glyph-orientation-vertical"; jsxName = "glyphOrientationVertical"; type_ = String (* number | *) };
      Attribute { name = "image-rendering"; jsxName = "imageRendering"; type_ = String };
      Attribute { name = "kerning"; jsxName = "kerning"; type_ = String (* number | *) };
      Attribute { name = "letter-spacing"; jsxName = "letterSpacing"; type_ = String };
      Attribute { name = "lighting-color"; jsxName = "lightingColor"; type_ = String };
      Attribute { name = "marker-end"; jsxName = "markerEnd"; type_ = String };
      Attribute { name = "marker-mid"; jsxName = "markerMid"; type_ = String };
      Attribute { name = "marker-start"; jsxName = "markerStart"; type_ = String };
      Attribute { name = "mask"; jsxName = "mask"; type_ = String };
      Attribute { name = "opacity"; jsxName = "opacity"; type_ = String (* number | *) };
      Attribute { name = "operator"; jsxName = "operator"; type_ = String (* number | *) };
      Attribute { name = "overflow"; jsxName = "overflow"; type_ = String (* number | *) };
      Attribute { name = "pointer-events"; jsxName = "pointerEvents"; type_ = String };
      Attribute { name = "shape-rendering"; jsxName = "shapeRendering"; type_ = String };
      Attribute { name = "specularConstant"; jsxName = "specularConstant"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/specularConstant *)
      Attribute { name = "specularExponent"; jsxName = "specularExponent"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/specularExponent *)
      Attribute { name = "solid-color"; jsxName = "solidColor"; type_ = String };
      Attribute { name = "solid-opacity"; jsxName = "solidOpacity"; type_ = String };
      Attribute { name = "stop-color"; jsxName = "stopColor"; type_ = String };
      Attribute { name = "stop-opacity"; jsxName = "stopOpacity"; type_ = String (* number | *) };
      Attribute { name = "stroke"; jsxName = "stroke"; type_ = String };
      Attribute { name = "stroke-dasharray"; jsxName = "strokeDasharray"; type_ = String };
      Attribute { name = "stroke-opacity"; jsxName = "strokeOpacity"; type_ = String };
      Attribute { name = "stroke-miterlimit"; jsxName = "strokeMiterlimit"; type_ = String };
      Attribute { name = "stroke-dashoffset"; jsxName = "strokeDashoffset"; type_ = String };
      Attribute { name = "stroke-linecap"; jsxName = "strokeLinecap"; type_ = String (* type_= "butt" | "round" | "square" | "inherit" *) };
      Attribute { name = "stroke-linejoin"; jsxName = "strokeLinejoin"; type_ = String (* type_= "arcs" | "bevel" | "miter" | "miter-clip" | "round" *) };
      Attribute { name = "text-anchor"; jsxName = "textAnchor"; type_ = String };
      Attribute { name = "text-decoration"; jsxName = "textDecoration"; type_ = String };
      Attribute { name = "text-rendering"; jsxName = "textRendering"; type_ = String };
      Attribute { name = "transform"; jsxName = "transform"; type_ = String };
      Attribute { name = "transform-origin"; jsxName = "transformOrigin"; type_ = String }; (* Does it exist? *)
      Attribute { name = "unicode-bidi"; jsxName = "unicodeBidi"; type_ = String (* number | *) };
      Attribute { name = "vector-effect"; jsxName = "vectorEffect"; type_ = String (* number | *) };
      Attribute { name = "word-spacing"; jsxName = "wordSpacing"; type_ = String (* number | *) };
      Attribute { name = "writing-mode"; jsxName = "writingMode"; type_ = String (* number | *) };
    ]

  let filtersAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute#filters_attributes *)
    [
      (* Filter primitive attributes *)
      Attribute { name = "height"; jsxName = "height"; type_ = String (* number | *) };
      Attribute { name = "width"; jsxName = "width"; type_ = String (* number | *) };
      Attribute { name = "result"; jsxName = "result"; type_ = String };
      Attribute { name = "x"; jsxName = "x"; type_ = String (* number | *) };
      Attribute { name = "y"; jsxName = "y"; type_ = String (* number | *) };
      (* Transfer function attributes type, tableValues, slope, intercept,
         amplitude, exponent, offset *)
      Attribute { name = "type"; jsxName = "type_"; type_ = String };
      Attribute { name = "exponent"; jsxName = "exponent"; type_ = String (* number | *) };
      Attribute { name = "slope"; jsxName = "slope"; type_ = String (* number | *) };
      Attribute { name = "amplitude"; jsxName = "amplitude"; type_ = String (* number | *) };
      Attribute { name = "intercept"; jsxName = "intercept"; type_ = String (* number | *) };
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/tableValues *)
      Attribute { name = "tableValues"; jsxName = "tableValues"; type_ = String (* number | *) };

      (* Animation target element attributes *)
      Attribute { name = "href"; jsxName = "href"; type_ = String };

      (* Animation attribute target attributes*)
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/attributeName *)
      Attribute { name = "attributeName"; jsxName = "attributeName"; type_ = String };
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/attributeType *)
      Attribute { name = "attributeType"; jsxName = "attributeType"; type_ = String };

      (* Animation timing attributes begin, dur, end, min, max, restart,
         repeatCount, repeatDur, fill *)
      Attribute { name = "begin"; jsxName = "begin"; type_ = String (* number | *) };
      Attribute { name = "dur"; jsxName = "dur"; type_ = String (* number | *) };
      Attribute { name = "end"; jsxName = "end"; type_ = String (* number | *) };
      Attribute { name = "max"; jsxName = "max"; type_ = String (* number | *) };
      Attribute { name = "min"; jsxName = "min"; type_ = String (* number | *) };
      Attribute { name = "repeatCount"; jsxName = "repeatCount"; type_ = String (* number | *) };
      Attribute { name = "restart"; jsxName = "restart"; type_ = String (* number | *) };
      Attribute { name = "repeatDur"; jsxName = "repeatDur"; type_ = String (* number | *) };
      Attribute { name = "fill"; jsxName = "fill"; type_ = String };

      (* Animation value attributes *)
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/calcMode *)
      Attribute { name = "calcMode"; jsxName = "calcMode"; type_ = String (* number | *) };
      Attribute { name = "values"; jsxName = "values"; type_ = String };
      Attribute { name = "keySplines"; jsxName = "keySplines"; type_ = String (* number | *) };
      Attribute { name = "keyTimes"; jsxName = "keyTimes"; type_ = String (* number | *) };
      Attribute { name = "from"; jsxName = "from"; type_ = String (* number | *) };
      Attribute { name = "to"; jsxName = "to"; type_ = String (* number | *) };
      Attribute { name = "by"; jsxName = "by"; type_ = String (* number | *) };

      (* Animation addition attributes *)
      Attribute { name = "accumulate"; jsxName = "accumulate"; type_ = String (* type_= "none" | "sum" *) };
      Attribute { name = "additive"; jsxName = "additive"; type_ = String (* type_= "replace" | "sum" *) };
    ]

  let htmlAttributes =
    (* These are valid SVG attributes which are HTML Attributes as well *)
    [
      Attribute { name = "color"; jsxName = "color"; type_ = String };
      Attribute { name = "id"; jsxName = "id"; type_ = String };
      Attribute { name = "lang"; jsxName = "lang"; type_ = String };
      Attribute { name = "media"; jsxName = "media"; type_ = String };
      Attribute { name = "method"; jsxName = "method_"; type_ = String };
      Attribute { name = "name"; jsxName = "name"; type_ = String };
      Attribute { name = "style"; jsxName = "style"; type_ = Style };
      Attribute { name = "target"; jsxName = "target"; type_ = String };

      (* Other HTML properties supported by SVG elements in browsers *)
      Attribute { name = "role"; jsxName = "role"; type_ = ariaRole };
      Attribute { name = "tabindex"; jsxName = "tabIndex"; type_ = Int (* number *) };
      Attribute { name = "cross-origin"; jsxName = "crossOrigin"; type_ = String (* "anonymous" | "use-credentials" | "" *) };

      (* SVG Specific attributes *)
      Attribute { name = "accent-height"; jsxName = "accentHeight"; type_ = String (* number | *) };
      (* Attribute { name = "allowReorder"; jsxName = "allowReorder"; type_ = String (* type_= "no" | "yes" *) }; Does it exist? *)
      Attribute { name = "alphabetic"; jsxName = "alphabetic"; type_ = String (* number | *) };
      Attribute { name = "arabic-form"; jsxName = "arabicForm"; type_ = String (* type_= "initial" | "medial" | "terminal" | "isolated" *) };
      Attribute { name = "ascent"; jsxName = "ascent"; type_ = String (* number | *) };
      (* Attribute { name = "autoReverse"; jsxName = "autoReverse"; type_ = BooleanishString }; Does it exists? *)
      Attribute { name = "azimuth"; jsxName = "azimuth"; type_ = String (* number | *) };
      Attribute { name = "baseProfile"; jsxName = "baseProfile"; type_ = String (* number | *) };
      Attribute { name = "baseFrequency"; jsxName = "baseFrequency"; type_ = String (* number | *) };
      Attribute { name = "bbox"; jsxName = "bbox"; type_ = String (* number | *) };
      Attribute { name = "bias"; jsxName = "bias"; type_ = String (* number | *) };
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/cap-height *)
      Attribute { name = "cap-height"; jsxName = "capHeight"; type_ = String (* number | *) };
      Attribute { name = "cx"; jsxName = "cx"; type_ = String (* number | *) };
      Attribute { name = "cy"; jsxName = "cy"; type_ = String (* number | *) };
      Attribute { name = "d"; jsxName = "d"; type_ = String };
      Attribute { name = "decelerate"; jsxName = "decelerate"; type_ = String (* number | *) };
      Attribute { name = "descent"; jsxName = "descent"; type_ = String (* number | *) };
      Attribute { name = "dx"; jsxName = "dx"; type_ = String (* number | *) };
      Attribute { name = "dy"; jsxName = "dy"; type_ = String (* number | *) };
      Attribute { name = "edgeMode"; jsxName = "edgeMode"; type_ = String (* number | *) };
      Attribute { name = "elevation"; jsxName = "elevation"; type_ = String (* number | *) };
      (* Attribute { name = "externalResourcesRequired"; jsxName = "externalResourcesRequired"; type_ = BooleanishString }; Does it exists? *)
      Attribute { name = "filterRes"; jsxName = "filterRes"; type_ = String (* number | *) };
      Attribute { name = "filterUnits"; jsxName = "filterUnits"; type_ = String (* number | *) };
      Attribute { name = "format"; jsxName = "format"; type_ = String (* number | *) };
      Attribute { name = "fr"; jsxName = "fr"; type_ = String (* number | *) };
      Attribute { name = "fx"; jsxName = "fx"; type_ = String (* number | *) };
      Attribute { name = "fy"; jsxName = "fy"; type_ = String (* number | *) };
      Attribute { name = "g1"; jsxName = "g1"; type_ = String (* number | *) };
      Attribute { name = "g2"; jsxName = "g2"; type_ = String (* number | *) };
      Attribute { name = "glyph-name"; jsxName = "glyphName"; type_ = String (* number | *) }; (* Deprecated *)
      Attribute { name = "glyphRef"; jsxName = "glyphRef"; type_ = String (* number | *) }; (* Deprecated *)
      Attribute { name = "gradientTransform"; jsxName = "gradientTransform"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/gradientTransform *)
      Attribute { name = "gradientUnits"; jsxName = "gradientUnits"; type_ = String };
      Attribute { name = "hanging"; jsxName = "hanging"; type_ = String (* number | *) };
      Attribute { name = "horiz-adv-x"; jsxName = "horizAdvX"; type_ = String (* number | *) };
      Attribute { name = "horiz-origin-x"; jsxName = "horizOriginX"; type_ = String (* number | *) };
      Attribute { name = "horiz-origin-y"; jsxName = "horizOriginY"; type_ = String (* number | *) };
      Attribute { name = "ideographic"; jsxName = "ideographic"; type_ = String (* number | *) };
      Attribute { name = "in2"; jsxName = "in2"; type_ = String (* number | *) };
      Attribute { name = "in"; jsxName = "in_"; type_ = String };
      Attribute { name = "k1"; jsxName = "k1"; type_ = String (* number | *) };
      Attribute { name = "k2"; jsxName = "k2"; type_ = String (* number | *) };
      Attribute { name = "k3"; jsxName = "k3"; type_ = String (* number | *) };
      Attribute { name = "k4"; jsxName = "k4"; type_ = String (* number | *) };
      Attribute { name = "k"; jsxName = "k"; type_ = String (* number | *) };
      Attribute { name = "kernelMatrix"; jsxName = "kernelMatrix"; type_ = String (* number | *) };
      Attribute { name = "limitingConeAngle"; jsxName = "limitingConeAngle"; type_ = String };
      Attribute { name = "lengthAdjust"; jsxName = "lengthAdjust"; type_ = String (* number | *) };
      Attribute { name = "local"; jsxName = "local"; type_ = String (* number | *) };
      Attribute { name = "marker-mid"; jsxName = "markerMid"; type_ = String };
      Attribute { name = "marker-start"; jsxName = "markerStart"; type_ = String };
      Attribute { name = "marker-units"; jsxName = "markerUnits"; type_ = String (* number | *) };
      Attribute { name = "markerWidth"; jsxName = "markerWidth"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/markerWidth *)
      Attribute { name = "markerHeight"; jsxName = "markerHeight"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/markerHeight *)
      Attribute { name = "maskUnits"; jsxName = "maskUnits"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/maskUnits *)
      Attribute { name = "maskContentUnits"; jsxName = "maskContentUnits"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/maskContentUnits *)
      Attribute { name = "mathematical"; jsxName = "mathematical"; type_ = String (* number | *) };
      Attribute { name = "mode"; jsxName = "mode"; type_ = String (* number | *) };
      Attribute { name = "numOctaves"; jsxName = "numOctaves"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/numOctaves *)
      Attribute { name = "offset"; jsxName = "offset"; type_ = String (* number | *) };
      Attribute { name = "order"; jsxName = "order"; type_ = String (* number | *) };
      Attribute { name = "orient"; jsxName = "orient"; type_ = String (* number | *) };
      Attribute { name = "orientation"; jsxName = "orientation"; type_ = String (* number | *) };
      Attribute { name = "origin"; jsxName = "origin"; type_ = String (* number | *) };
      Attribute { name = "overline-thickness"; jsxName = "overlineThickness"; type_ = String };
      Attribute { name = "overline-position"; jsxName = "overlinePosition"; type_ = String };
      Attribute { name = "paint-order"; jsxName = "paintOrder"; type_ = String (* number | *) };
      Attribute { name = "panose1"; jsxName = "panose1"; type_ = String (* number | *) };
      Attribute { name = "path"; jsxName = "path"; type_ = String };
      Attribute { name = "pathLength"; jsxName = "pathLength"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/pathLength *)
      Attribute { name = "patternContentUnits"; jsxName = "patternContentUnits"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/patternContentUnits *)
      Attribute { name = "patternUnits"; jsxName = "patternUnits"; type_ = String };
      Attribute { name = "points"; jsxName = "points"; type_ = String };
      Attribute { name = "pointsAtX"; jsxName = "pointsAtX"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/pointsAtX *)
      Attribute { name = "pointsAtY"; jsxName = "pointsAtY"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/pointsAtY *)
      Attribute { name = "pointsAtZ"; jsxName = "pointsAtZ"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/pointsAtZ *)
      Attribute { name = "preserveAspectRatio"; jsxName = "preserveAspectRatio"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/preserveAspectRatio *)
      Attribute { name = "r"; jsxName = "r"; type_ = String (* number | *) };
      Attribute { name = "radius"; jsxName = "radius"; type_ = String (* number | *) };
      Attribute { name = "requiredFeatures"; jsxName = "requiredFeatures"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/requiredFeatures *)
      Attribute { name = "refX"; jsxName = "refX"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/refX *)
      Attribute { name = "refY"; jsxName = "refY"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/refY *)
      Attribute { name = "rotate"; jsxName = "rotate"; type_ = String (* number | *) };
      Attribute { name = "rx"; jsxName = "rx"; type_ = String (* number | *) };
      Attribute { name = "ry"; jsxName = "ry"; type_ = String (* number | *) };
      Attribute { name = "scale"; jsxName = "scale"; type_ = String (* number | *) };
      Attribute { name = "seed"; jsxName = "seed"; type_ = String (* number | *) };
      Attribute { name = "spacing"; jsxName = "spacing"; type_ = String (* number | *) };
      Attribute { name = "speed"; jsxName = "speed"; type_ = String (* number | *) };
      Attribute { name = "spreadMethod"; jsxName = "spreadMethod"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/spreadMethod *)
      Attribute { name = "startOffset"; jsxName = "startOffset"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/startOffset *)
      Attribute { name = "stdDeviation"; jsxName = "stdDeviation"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/stdDeviation *)
      Attribute { name = "stemh"; jsxName = "stemh"; type_ = String (* number | *) };
      Attribute { name = "stemv"; jsxName = "stemv"; type_ = String (* number | *) };
      Attribute { name = "stitchTiles"; jsxName = "stitchTiles"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/stitchTiles *)
      Attribute { name = "strikethrough-position"; jsxName = "strikethroughPosition"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/strikethrough-position *)
      Attribute { name = "strikethrough-thickness"; jsxName = "strikethroughThickness"; type_ = String (* number | *) };
      Attribute { name = "stroke-width"; jsxName = "strokeWidth"; type_ = String (* number | *) };
      Attribute { name = "surfaceScale"; jsxName = "surfaceScale"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/surfaceScale *)
      Attribute { name = "systemLanguage"; jsxName = "systemLanguage"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/systemLanguage *)
      Attribute { name = "targetX"; jsxName = "targetX"; type_ = String (* number | *) };
      Attribute { name = "targetY"; jsxName = "targetY"; type_ = String (* number | *) };
      Attribute { name = "textLength"; jsxName = "textLength"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/textLength *)
      Attribute { name = "u1"; jsxName = "u1"; type_ = String (* number | *) };
      Attribute { name = "u2"; jsxName = "u2"; type_ = String (* number | *) };
      Attribute { name = "unicode"; jsxName = "unicode"; type_ = String (* number | *) };
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/unicode-range *)
      Attribute { name = "unicode-range"; jsxName = "unicodeRange"; type_ = String (* number | *) };
      (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/units-per-em *)
      Attribute { name = "units-per-em"; jsxName = "unitsPerEm"; type_ = String (* number | *) };
      Attribute { name = "v-alphabetic"; jsxName = "vAlphabetic"; type_ = String (* number | *) }; (* Deprecated *) (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/v-alphabetic *)
      Attribute { name = "version"; jsxName = "version"; type_ = String };
      Attribute { name = "vert-adv-y"; jsxName = "vertAdvY"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vert-adv-y *)
      Attribute { name = "vert-origin-x"; jsxName = "vertOriginX"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vert-origin-x *)
      Attribute { name = "vert-origin-y"; jsxName = "vertOriginY"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/vert-origin-y *)
      Attribute { name = "v-hanging"; jsxName = "vHanging"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/v-hanging *)
      Attribute { name = "v-ideographic"; jsxName = "vIdeographic"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/v-ideographic *)
      Attribute { name = "viewBox"; jsxName = "viewBox"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/viewBox *)
      Attribute { name = "viewTarget"; jsxName = "viewTarget"; type_ = String (* number | *) }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/viewTarget *)
      Attribute { name = "visibility"; jsxName = "visibility"; type_ = String (* number | *) };
      Attribute { name = "widths"; jsxName = "widths"; type_ = String (* number | *) };
      Attribute { name = "x1"; jsxName = "x1"; type_ = String (* number | *) };
      Attribute { name = "x2"; jsxName = "x2"; type_ = String (* number | *) };
      Attribute { name = "xChannelSelector"; jsxName = "xChannelSelector"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xChannelSelector *)
      Attribute { name = "xHeight"; jsxName = "xHeight"; type_ = String (* number | *) };
      (* All xlink: attributes are rendered like this and are deprecated *)
      Attribute { name = "xlink:actuate"; jsxName = "xlinkActuate"; type_ = String };
      Attribute { name = "xlink:arcrole"; jsxName = "xlinkArcrole"; type_ = String };
      Attribute { name = "xlink:href"; jsxName = "xlinkHref"; type_ = String };
      Attribute { name = "xlink:role"; jsxName = "xlinkRole"; type_ = String };
      Attribute { name = "xlink:show"; jsxName = "xlinkShow"; type_ = String };
      Attribute { name = "xlink:title"; jsxName = "xlinkTitle"; type_ = String };
      Attribute { name = "xlink:type"; jsxName = "xlinkType"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xlink:type *)
      Attribute { name = "xml:base"; jsxName = "xmlBase"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xml:base *)
      Attribute { name = "xml:lang"; jsxName = "xmlLang"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/xml:lang *)
      Attribute { name = "xmlns"; jsxName = "xmlns"; type_ = String };
      Attribute { name = "xmlnsXlink"; jsxName = "xmlnsXlink"; type_ = String };
      Attribute { name = "xmlSpace"; jsxName = "xmlSpace"; type_ = String };
      Attribute { name = "y1"; jsxName = "y1"; type_ = String (* number | *) };
      Attribute { name = "y2"; jsxName = "y2"; type_ = String (* number | *) };
      Attribute { name = "yChannelSelector"; jsxName = "yChannelSelector"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/yChannelSelector *)
      Attribute { name = "z"; jsxName = "z"; type_ = String (* number | *) };
      Attribute { name = "zoomAndPan"; jsxName = "zoomAndPan"; type_ = String }; (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/zoomAndPan *) (* Deprecated *)
    ]

  let attributes = htmlAttributes & filtersAttributes & presentationAttributes & stylingAttributes & coreAttributes
end

let webViewHTMLAttributes =
  [
    Attribute { name = "allowfullcreen"; jsxName = "allowFullScreen"; type_ = Bool };
    (* Attribute { name = "allowPopups"; jsxName = "allowPopups"; type_ = Bool }; Does it exist? *)
    Attribute { name = "autofocus"; jsxName = "autoFocus"; type_ = Bool };
    Attribute { name = "autoSize"; jsxName = "autoSize"; type_ = Bool };
    Attribute { name = "blinkFeatures"; jsxName = "blinkFeatures"; type_ = String };
    Attribute { name = "disableBlinkFeatures"; jsxName = "disableBlinkFeatures"; type_ = String };
    Attribute { name = "disableGuestResize"; jsxName = "disableGuestResize"; type_ = Bool };
    Attribute { name = "disableWebSecurity"; jsxName = "disableWebSecurity"; type_ = Bool };
    Attribute { name = "guestInstance"; jsxName = "guestInstance"; type_ = String };
    Attribute { name = "httpReferrer"; jsxName = "httpReferrer"; type_ = String };
    Attribute { name = "nodeIntegration"; jsxName = "nodeIntegration"; type_ = Bool };
    Attribute { name = "partition"; jsxName = "partition"; type_ = String };
    Attribute { name = "plugins"; jsxName = "plugins"; type_ = Bool };
    Attribute { name = "preload"; jsxName = "preload"; type_ = String };
    Attribute { name = "src"; jsxName = "src"; type_ = String };
    Attribute { name = "userAgent"; jsxName = "userAgent"; type_ = String };
    Attribute { name = "webPreferences"; jsxName = "webPreferences"; type_ = String };
  ]

let hackAttributes =
  [
    Event { jsxName = "_onclick"; type_ = Inline };
  ]

let commonHtmlAttributes = elementAttributes & reactAttributes & globalAttributes & globalEventHandlers & ariaAttributes & hackAttributes

let htmlElements =
  [
    { tag = "a"; attributes = commonHtmlAttributes & anchorHTMLAttributes };
    { tag = "abbr"; attributes = commonHtmlAttributes };
    { tag = "address"; attributes = commonHtmlAttributes };
    { tag = "area"; attributes = commonHtmlAttributes & areaHTMLAttributes };
    { tag = "article"; attributes = commonHtmlAttributes };
    { tag = "aside"; attributes = commonHtmlAttributes };
    { tag = "audio"; attributes = commonHtmlAttributes & mediaHTMLAttributes };
    { tag = "b"; attributes = commonHtmlAttributes };
    { tag = "base"; attributes = commonHtmlAttributes & baseHTMLAttributes };
    { tag = "bdi"; attributes = commonHtmlAttributes };
    { tag = "bdo"; attributes = commonHtmlAttributes };
    { tag = "big"; attributes = commonHtmlAttributes };
    { tag = "blockquote"; attributes = commonHtmlAttributes & blockquoteHTMLAttributes };
    { tag = "body"; attributes = commonHtmlAttributes };
    { tag = "br"; attributes = commonHtmlAttributes };
    { tag = "button"; attributes = commonHtmlAttributes & buttonHTMLAttributes };
    { tag = "canvas"; attributes = commonHtmlAttributes & canvasHTMLAttributes };
    { tag = "caption"; attributes = commonHtmlAttributes };
    { tag = "cite"; attributes = commonHtmlAttributes };
    { tag = "code"; attributes = commonHtmlAttributes };
    { tag = "col"; attributes = commonHtmlAttributes & colHTMLAttributes };
    { tag = "colgroup"; attributes = commonHtmlAttributes & colgroupHTMLAttributes };
    { tag = "data"; attributes = commonHtmlAttributes & dataHTMLAttributes };
    { tag = "datalist"; attributes = commonHtmlAttributes };
    { tag = "dd"; attributes = commonHtmlAttributes };
    { tag = "del"; attributes = commonHtmlAttributes & delHTMLAttributes };
    { tag = "details"; attributes = commonHtmlAttributes & detailsHTMLAttributes };
    { tag = "dfn"; attributes = commonHtmlAttributes };
    { tag = "dialog"; attributes = commonHtmlAttributes & dialogHTMLAttributes };
    { tag = "div"; attributes = commonHtmlAttributes };
    { tag = "dl"; attributes = commonHtmlAttributes };
    { tag = "dt"; attributes = commonHtmlAttributes };
    { tag = "em"; attributes = commonHtmlAttributes };
    { tag = "embed"; attributes = commonHtmlAttributes & embedHTMLAttributes };
    { tag = "fieldset"; attributes = commonHtmlAttributes & fieldsetHTMLAttributes };
    { tag = "figcaption"; attributes = commonHtmlAttributes };
    { tag = "figure"; attributes = commonHtmlAttributes };
    { tag = "footer"; attributes = commonHtmlAttributes };
    { tag = "form"; attributes = commonHtmlAttributes & formHTMLAttributes };
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
    { tag = "html"; attributes = commonHtmlAttributes & htmlHTMLAttributes };
    { tag = "i"; attributes = commonHtmlAttributes };
    { tag = "iframe"; attributes = commonHtmlAttributes & iframeHTMLAttributes };
    { tag = "img"; attributes = commonHtmlAttributes & imgHTMLAttributes };
    { tag = "input"; attributes = commonHtmlAttributes & inputHTMLAttributes };
    { tag = "ins"; attributes = commonHtmlAttributes & insHTMLAttributes };
    { tag = "kbd"; attributes = commonHtmlAttributes };
    { tag = "keygen"; attributes = commonHtmlAttributes & keygenHTMLAttributes };
    { tag = "label"; attributes = commonHtmlAttributes & labelHTMLAttributes };
    { tag = "legend"; attributes = commonHtmlAttributes };
    { tag = "li"; attributes = commonHtmlAttributes & liHTMLAttributes };
    { tag = "link"; attributes = commonHtmlAttributes & linkHTMLAttributes };
    { tag = "main"; attributes = commonHtmlAttributes };
    { tag = "map"; attributes = commonHtmlAttributes & mapHTMLAttributes };
    { tag = "mark"; attributes = commonHtmlAttributes };
    { tag = "menu"; attributes = commonHtmlAttributes & menuHTMLAttributes };
    { tag = "menuitem"; attributes = commonHtmlAttributes };
    { tag = "meta"; attributes = commonHtmlAttributes & metaHTMLAttributes };
    { tag = "meter"; attributes = commonHtmlAttributes & meterHTMLAttributes };
    { tag = "nav"; attributes = commonHtmlAttributes };
    { tag = "noindex"; attributes = commonHtmlAttributes };
    { tag = "noscript"; attributes = commonHtmlAttributes };
    { tag = "object"; attributes = commonHtmlAttributes & objectHTMLAttributes };
    { tag = "ol"; attributes = commonHtmlAttributes & olHTMLAttributes };
    { tag = "optgroup"; attributes = commonHtmlAttributes & optgroupHTMLAttributes };
    { tag = "option"; attributes = commonHtmlAttributes & optionHTMLAttributes };
    { tag = "output"; attributes = commonHtmlAttributes & outputHTMLAttributes };
    { tag = "p"; attributes = commonHtmlAttributes };
    { tag = "param"; attributes = commonHtmlAttributes & paramHTMLAttributes };
    { tag = "picture"; attributes = commonHtmlAttributes };
    { tag = "pre"; attributes = commonHtmlAttributes };
    { tag = "progress"; attributes = commonHtmlAttributes & progressHTMLAttributes };
    { tag = "q"; attributes = commonHtmlAttributes & quoteHTMLAttributes };
    { tag = "rp"; attributes = commonHtmlAttributes };
    { tag = "rt"; attributes = commonHtmlAttributes };
    { tag = "ruby"; attributes = commonHtmlAttributes };
    { tag = "s"; attributes = commonHtmlAttributes };
    { tag = "samp"; attributes = commonHtmlAttributes };
    { tag = "script"; attributes = commonHtmlAttributes & scriptHTMLAttributes };
    { tag = "section"; attributes = commonHtmlAttributes };
    { tag = "select"; attributes = commonHtmlAttributes & selectHTMLAttributes };
    { tag = "slot"; attributes = commonHtmlAttributes & slotHTMLAttributes };
    { tag = "small"; attributes = commonHtmlAttributes };
    { tag = "source"; attributes = commonHtmlAttributes & sourceHTMLAttributes };
    { tag = "span"; attributes = commonHtmlAttributes };
    { tag = "strong"; attributes = commonHtmlAttributes };
    { tag = "style"; attributes = commonHtmlAttributes & styleHTMLAttributes };
    { tag = "sub"; attributes = commonHtmlAttributes };
    { tag = "summary"; attributes = commonHtmlAttributes };
    { tag = "sup"; attributes = commonHtmlAttributes };
    { tag = "table"; attributes = commonHtmlAttributes & tableHTMLAttributes };
    { tag = "tbody"; attributes = commonHtmlAttributes };
    { tag = "td"; attributes = commonHtmlAttributes & tdHTMLAttributes };
    { tag = "template"; attributes = commonHtmlAttributes };
    { tag = "textarea"; attributes = commonHtmlAttributes & textareaHTMLAttributes };
    { tag = "tfoot"; attributes = commonHtmlAttributes };
    { tag = "th"; attributes = commonHtmlAttributes & thHTMLAttributes };
    { tag = "thead"; attributes = commonHtmlAttributes };
    { tag = "time"; attributes = commonHtmlAttributes & timeHTMLAttributes };
    { tag = "title"; attributes = commonHtmlAttributes };
    { tag = "tr"; attributes = commonHtmlAttributes };
    { tag = "track"; attributes = commonHtmlAttributes & trackHTMLAttributes };
    { tag = "u"; attributes = commonHtmlAttributes };
    { tag = "ul"; attributes = commonHtmlAttributes };
    { tag = "var"; attributes = commonHtmlAttributes };
    { tag = "video"; attributes = commonHtmlAttributes & videoHTMLAttributes };
    { tag = "wbr"; attributes = commonHtmlAttributes };
    { tag = "webview"; attributes = commonHtmlAttributes & webViewHTMLAttributes };
  ]

let commonSvgAttributes = SVG.attributes & reactAttributes & globalEventHandlers & ariaAttributes

let feConvolveMatrixAttributes = [ Attribute { name = "preserveAlpha"; jsxName = "preserveAlpha"; type_ = BooleanishString } ]

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
    { tag = "feConvolveMatrix"; attributes = commonSvgAttributes & feConvolveMatrixAttributes };
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

let elements = svgElements & htmlElements

let getJSXName = function
  | Attribute { jsxName; _ } -> jsxName
  | Event { jsxName; _ } -> jsxName

let getName = function
  | Attribute { name; _ } -> name
  | Event { jsxName; _ } -> jsxName

let domPropNames =
  (commonSvgAttributes & commonHtmlAttributes)
  |> List.map getJSXName
  (* We ignore prefixed names such as "hackAttributes prop list" *)
  |> List.filter (fun name -> not (String.starts_with ~prefix:"_" name))

type errors = [ `ElementNotFound | `AttributeNotFound ]

let getAttributes tag =
  List.find_opt (fun element -> element.tag = tag) elements
  |> Option.to_result ~none:`ElementNotFound

let isDataAttribute = String.starts_with ~prefix:"data"

let string_of_chars chars =
  let buf = Buffer.create 16 in
  List.iter (Buffer.add_char buf) chars;
  Buffer.contents buf

let chars_of_string str = List.init (String.length str) (String.get str)

let camelcaseToKebabcase str =
  let rec loop acc = function
    | [] -> acc
    | [ x ] -> x :: acc
    | x :: y :: xs ->
        if Char.uppercase_ascii y == y then
          loop ('-' :: x :: acc) (Char.lowercase_ascii y :: xs)
        else loop (x :: acc) (y :: xs)
  in
  str |> chars_of_string |> loop [] |> List.rev |> string_of_chars

let findByName tag jsxName =
  let byName p = getJSXName p = jsxName in
  if isDataAttribute jsxName then
    let name = camelcaseToKebabcase jsxName in
    Ok (Attribute { name; jsxName; type_ = String })
  else
    match getAttributes tag with
    | Ok { attributes; _ } ->
        List.find_opt byName attributes
        |> Option.to_result ~none:`AttributeNotFound
    | Error err -> Error err

let isReactValidProp name =
  let byName p = getJSXName p = name in
  reactValidHtml |> List.exists byName

module Levenshtein = struct
  (* Levenshtein distance from
     https://rosettacode.org/wiki/Levenshtein_distance *)
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
        else
          matrix.(i).(j) <-
            minimum
              (matrix.(i - 1).(j) + 1)
              (matrix.(i).(j - 1) + 1)
              (matrix.(i - 1).(j - 1) + 1)
      done
    done;
    matrix.(first).(second)
end

type closest = { name : string; distance : int }

let find_closest_name invalid =
  let accumulate_distance name bestMatch =
    let distance = Levenshtein.distance invalid name in
    match distance < bestMatch.distance with
    | true -> { name; distance }
    | false -> bestMatch
  in
  let { name; distance } =
    List.fold_right accumulate_distance domPropNames
      { name = ""; distance = max_int }
  in
  if distance > 2 then None else Some name
