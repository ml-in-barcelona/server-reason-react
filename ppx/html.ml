let ( & ) = List.append

type attributeType =
  | String
  | Int
  | Float
  | Bool
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
  | Drag

type attribute =
  { type_ : attributeType
  ; name : string
  ; jsxName : string
  }

type event =
  { type_ : eventType
  ; name : string
  }

type prop =
  | Attribute of attribute
  | Event of event

type element =
  { tag : string
  ; attributes : prop list
  }

let attributeReferrerPolicy = String
(* | Empty
   | NoReferrer
   | NoReferrerWhenDowngrade
   | Origin
   | OriginWhenCrossOrigin
   | SameOrigin
   | StrictOrigin
   | StrictOriginWhenCrossOrigin
   | UnsafeUrl *)

let attributeAnchorTarget = String
(* | Self
   | Blank
   | Parent
   | Top
   | Custom of String *)

let globalEventHandlers =
  (* https://developer.mozilla.org/en-US/docs/Web/Events/Event_handlers *)
  [ Event { name = "onCopy"; type_ = Clipboard }
  ; Event { name = "onCopyCapture"; type_ = Clipboard }
  ; Event { name = "onCut"; type_ = Clipboard }
  ; Event { name = "onCutCapture"; type_ = Clipboard }
  ; Event { name = "onPaste"; type_ = Clipboard }
  ; Event { name = "onPasteCapture"; type_ = Clipboard }
  ; Event { name = "onCompositionEnd"; type_ = Composition }
  ; Event { name = "onCompositionEndCapture"; type_ = Composition }
  ; Event { name = "onCompositionStart"; type_ = Composition }
  ; Event { name = "onCompositionStartCapture"; type_ = Composition }
  ; Event { name = "onCompositionUpdate"; type_ = Composition }
  ; Event { name = "onCompositionUpdateCapture"; type_ = Composition }
  ; Event { name = "onFocus"; type_ = Focus }
  ; Event { name = "onFocusCapture"; type_ = Focus }
  ; Event { name = "onBlur"; type_ = Focus }
  ; Event { name = "onBlurCapture"; type_ = Focus }
  ; Event { name = "onChange"; type_ = Form }
  ; Event { name = "onChangeCapture"; type_ = Form }
  ; Event { name = "onBeforeInput"; type_ = Form }
  ; Event { name = "onBeforeInputCapture"; type_ = Form }
  ; Event { name = "onInput"; type_ = Form }
  ; Event { name = "onInputCapture"; type_ = Form }
  ; Event { name = "onReset"; type_ = Form }
  ; Event { name = "onResetCapture"; type_ = Form }
  ; Event { name = "onSubmit"; type_ = Form }
  ; Event { name = "onSubmitCapture"; type_ = Form }
  ; Event { name = "onInvalid"; type_ = Form }
  ; Event { name = "onInvalidCapture"; type_ = Form }
  ; Event { name = "onLoad"; type_ = Media }
  ; Event { name = "onLoadCapture"; type_ = Media }
  ; Event { name = "onError"; type_ = Media }
  ; Event { name = "onErrorCapture"; type_ = Media }
  ; Event { name = "onKeyDown"; type_ = Keyboard }
  ; Event { name = "onKeyDownCapture"; type_ = Keyboard }
  ; Event { name = "onKeyPress"; type_ = Keyboard }
  ; Event { name = "onKeyPressCapture"; type_ = Keyboard }
  ; Event { name = "onKeyUp"; type_ = Keyboard }
  ; Event { name = "onKeyUpCapture"; type_ = Keyboard }
  ; Event { name = "onAbort"; type_ = Media }
  ; Event { name = "onAbortCapture"; type_ = Media }
  ; Event { name = "onCanPlay"; type_ = Media }
  ; Event { name = "onCanPlayCapture"; type_ = Media }
  ; Event { name = "onCanPlayThrough"; type_ = Media }
  ; Event { name = "onCanPlayThroughCapture"; type_ = Media }
  ; Event { name = "onDurationChange"; type_ = Media }
  ; Event { name = "onDurationChangeCapture"; type_ = Media }
  ; Event { name = "onEmptied"; type_ = Media }
  ; Event { name = "onEmptiedCapture"; type_ = Media }
  ; Event { name = "onEncrypted"; type_ = Media }
  ; Event { name = "onEncryptedCapture"; type_ = Media }
  ; Event { name = "onEnded"; type_ = Media }
  ; Event { name = "onEndedCapture"; type_ = Media }
  ; Event { name = "onLoadedData"; type_ = Media }
  ; Event { name = "onLoadedDataCapture"; type_ = Media }
  ; Event { name = "onLoadedMetadata"; type_ = Media }
  ; Event { name = "onLoadedMetadataCapture"; type_ = Media }
  ; Event { name = "onLoadStart"; type_ = Media }
  ; Event { name = "onLoadStartCapture"; type_ = Media }
  ; Event { name = "onPause"; type_ = Media }
  ; Event { name = "onPauseCapture"; type_ = Media }
  ; Event { name = "onPlay"; type_ = Media }
  ; Event { name = "onPlayCapture"; type_ = Media }
  ; Event { name = "onPlaying"; type_ = Media }
  ; Event { name = "onPlayingCapture"; type_ = Media }
  ; Event { name = "onProgress"; type_ = Media }
  ; Event { name = "onProgressCapture"; type_ = Media }
  ; Event { name = "onRateChange"; type_ = Media }
  ; Event { name = "onRateChangeCapture"; type_ = Media }
  ; Event { name = "onSeeked"; type_ = Media }
  ; Event { name = "onSeekedCapture"; type_ = Media }
  ; Event { name = "onSeeking"; type_ = Media }
  ; Event { name = "onSeekingCapture"; type_ = Media }
  ; Event { name = "onStalled"; type_ = Media }
  ; Event { name = "onStalledCapture"; type_ = Media }
  ; Event { name = "onSuspend"; type_ = Media }
  ; Event { name = "onSuspendCapture"; type_ = Media }
  ; Event { name = "onTimeUpdate"; type_ = Media }
  ; Event { name = "onTimeUpdateCapture"; type_ = Media }
  ; Event { name = "onVolumeChange"; type_ = Media }
  ; Event { name = "onVolumeChangeCapture"; type_ = Media }
  ; Event { name = "onWaiting"; type_ = Media }
  ; Event { name = "onWaitingCapture"; type_ = Media }
  ; Event { name = "onAuxClick"; type_ = Mouse }
  ; Event { name = "onAuxClickCapture"; type_ = Mouse }
  ; Event { name = "onClick"; type_ = Mouse }
  ; Event { name = "onClickCapture"; type_ = Mouse }
  ; Event { name = "onContextMenu"; type_ = Mouse }
  ; Event { name = "onContextMenuCapture"; type_ = Mouse }
  ; Event { name = "onDoubleClick"; type_ = Mouse }
  ; Event { name = "onDoubleClickCapture"; type_ = Mouse }
  ; Event { name = "onDrag"; type_ = Drag }
  ; Event { name = "onDragCapture"; type_ = Drag }
  ; Event { name = "onDragEnd"; type_ = Drag }
  ; Event { name = "onDragEndCapture"; type_ = Drag }
  ; Event { name = "onDragEnter"; type_ = Drag }
  ; Event { name = "onDragEnterCapture"; type_ = Drag }
  ; Event { name = "onDragExit"; type_ = Drag }
  ; Event { name = "onDragExitCapture"; type_ = Drag }
  ; Event { name = "onDragLeave"; type_ = Drag }
  ; Event { name = "onDragLeaveCapture"; type_ = Drag }
  ; Event { name = "onDragOver"; type_ = Drag }
  ; Event { name = "onDragOverCapture"; type_ = Drag }
  ; Event { name = "onDragStart"; type_ = Drag }
  ; Event { name = "onDragStartCapture"; type_ = Drag }
  ; Event { name = "onDrop"; type_ = Drag }
  ; Event { name = "onDropCapture"; type_ = Drag }
  ; Event { name = "onMouseDown"; type_ = Mouse }
  ; Event { name = "onMouseDownCapture"; type_ = Mouse }
  ; Event { name = "onMouseEnter"; type_ = Mouse }
  ; Event { name = "onMouseLeave"; type_ = Mouse }
  ; Event { name = "onMouseMove"; type_ = Mouse }
  ; Event { name = "onMouseMoveCapture"; type_ = Mouse }
  ; Event { name = "onMouseOut"; type_ = Mouse }
  ; Event { name = "onMouseOutCapture"; type_ = Mouse }
  ; Event { name = "onMouseOver"; type_ = Mouse }
  ; Event { name = "onMouseOverCapture"; type_ = Mouse }
  ; Event { name = "onMouseUp"; type_ = Mouse }
  ; Event { name = "onMouseUpCapture"; type_ = Mouse }
  ; Event { name = "onSelect"; type_ = Selection }
  ; Event { name = "onSelectCapture"; type_ = Selection }
  ; Event { name = "onTouchCancel"; type_ = Touch }
  ; Event { name = "onTouchCancelCapture"; type_ = Touch }
  ; Event { name = "onTouchEnd"; type_ = Touch }
  ; Event { name = "onTouchEndCapture"; type_ = Touch }
  ; Event { name = "onTouchMove"; type_ = Touch }
  ; Event { name = "onTouchMoveCapture"; type_ = Touch }
  ; Event { name = "onTouchStart"; type_ = Touch }
  ; Event { name = "onTouchStartCapture"; type_ = Touch }
  ; Event { name = "onPointerDown"; type_ = Pointer }
  ; Event { name = "onPointerDownCapture"; type_ = Pointer }
  ; Event { name = "onPointerMove"; type_ = Pointer }
  ; Event { name = "onPointerMoveCapture"; type_ = Pointer }
  ; Event { name = "onPointerUp"; type_ = Pointer }
  ; Event { name = "onPointerUpCapture"; type_ = Pointer }
  ; Event { name = "onPointerCancel"; type_ = Pointer }
  ; Event { name = "onPointerCancelCapture"; type_ = Pointer }
  ; Event { name = "onPointerEnter"; type_ = Pointer }
  ; Event { name = "onPointerEnterCapture"; type_ = Pointer }
  ; Event { name = "onPointerLeave"; type_ = Pointer }
  ; Event { name = "onPointerLeaveCapture"; type_ = Pointer }
  ; Event { name = "onPointerOver"; type_ = Pointer }
  ; Event { name = "onPointerOverCapture"; type_ = Pointer }
  ; Event { name = "onPointerOut"; type_ = Pointer }
  ; Event { name = "onPointerOutCapture"; type_ = Pointer }
  ; Event { name = "onGotPointerCapture"; type_ = Pointer }
  ; Event { name = "onGotPointerCaptureCapture"; type_ = Pointer }
  ; Event { name = "onLostPointerCapture"; type_ = Pointer }
  ; Event { name = "onLostPointerCaptureCapture"; type_ = Pointer }
  ; Event { name = "onScroll"; type_ = UI }
  ; Event { name = "onScrollCapture"; type_ = UI }
  ; Event { name = "onWheel"; type_ = Wheel }
  ; Event { name = "onWheelCapture"; type_ = Wheel }
  ; Event { name = "onAnimationStart"; type_ = Animation }
  ; Event { name = "onAnimationStartCapture"; type_ = Animation }
  ; Event { name = "onAnimationEnd"; type_ = Animation }
  ; Event { name = "onAnimationEndCapture"; type_ = Animation }
  ; Event { name = "onAnimationIteration"; type_ = Animation }
  ; Event { name = "onAnimationIterationCapture"; type_ = Animation }
  ; Event { name = "onTransitionEnd"; type_ = Transition }
  ; Event { name = "onTransitionEndCapture"; type_ = Transition }
  ]

(* All the WAI-ARIA 1.1 attributes from https://www.w3.org/TR/wai-aria-1.1/ *)
let ariaAttributes =
  [ (* Identifies the currently active element when DOM focus is on a composite widget, textbox, group, or application. *)
    Attribute
      { name = "ariaActivedescendant"
      ; jsxName = "aria-activedescendant"
      ; type_ = String
      }
    (* Indicates whether assistive technologies will present all, or only parts of, the changed region based on the change notifications defined by the aria-relevant attribute. *)
  ; Attribute
      { name = "ariaAtomic"
      ; jsxName = "aria-atomic"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates whether inputting text could trigger display of one or more predictions of the user's intended value for an input and specifies how predictions would be
     * presented if they are made.
     *)
  ; Attribute
      { name = "ariaAutocomplete"
      ; jsxName = "aria-autocomplete"
      ; type_ = String (* 'none' | 'inline' | 'list' | 'both' *)
      }
    (* Indicates an element is being modified and that assistive technologies MAY want to wait until the modifications are complete before exposing them to the user. *)
  ; Attribute
      { name = "ariaBusy"
      ; jsxName = "aria-busy"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates the current "checked" state of checkboxes, radio buttons, and other widgets.
     * @see aria-pressed @see aria-selected.
     *)
  ; Attribute
      { name = "ariaChecked"
      ; jsxName = "aria-checked"
      ; type_ = String (* Bool | 'false' | 'mixed' | 'true' *)
      }
    (* Defines the total number of columns in a table, grid, or treegrid.
     * @see aria-colindex.
     *)
  ; Attribute { name = "ariaColcount"; jsxName = "aria-colcount"; type_ = Int }
    (* Defines an element's column index or position with respect to the total number of columns within a table, grid, or treegrid.
     * @see aria-colcount @see aria-colspan.
     *)
  ; Attribute { name = "ariaColindex"; jsxName = "aria-colindex"; type_ = Int }
    (* Defines the number of columns spanned by a cell or gridcell within a table, grid, or treegrid.
     * @see aria-colindex @see aria-rowspan.
     *)
  ; Attribute { name = "ariaColspan"; jsxName = "aria-colspan"; type_ = Int }
    (* Identifies the element (or elements) whose contents or presence are controlled by the current element.
     * @see aria-owns.
     *)
  ; Attribute
      { name = "ariaControls"; jsxName = "aria-controls"; type_ = String }
    (* Indicates the element that represents the current item within a container or set of related elements. *)
  ; Attribute
      { name = "ariaCurrent"
      ; jsxName = "aria-current"
      ; type_ =
          String
          (* Bool | 'false' | 'true' |  'page' | 'step' | 'location' | 'date' | 'time' *)
      }
    (* Identifies the element (or elements) that describes the object.
     * @see aria-labelledby
     *)
  ; Attribute
      { name = "ariaDescribedby"; jsxName = "aria-describedby"; type_ = String }
    (* Identifies the element that provides a detailed, extended description for the object.
     * @see aria-describedby.
     *)
  ; Attribute { name = "ariaDetails"; jsxName = "aria-details"; type_ = String }
    (* Indicates that the element is perceivable but disabled, so it is not editable or otherwise operable.
     * @see aria-hidden @see aria-readonly.
     *)
  ; Attribute
      { name = "ariaDisabled"
      ; jsxName = "aria-disabled"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates what functions can be performed when a dragged object is released on the drop target.
     * @deprecated in ARIA 1.1
     *)
  ; Attribute
      { name = "ariaDropeffect"
      ; jsxName = "aria-dropeffect"
      ; type_ =
          String (* 'none' | 'copy' | 'execute' | 'link' | 'move' | 'popup' *)
      }
    (* Identifies the element that provides an error message for the object.
     * @see aria-invalid @see aria-describedby.
     *)
  ; Attribute
      { name = "ariaErrormessage"
      ; jsxName = "aria-errormessage"
      ; type_ = String
      }
    (* Indicates whether the element, or another grouping element it controls, is currently expanded or collapsed. *)
  ; Attribute
      { name = "ariaExpanded"
      ; jsxName = "aria-expanded"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Identifies the next element (or elements) in an alternate reading order of content which, at the user's discretion,
     * allows assistive technology to override the general default of reading in document source order.
     *)
  ; Attribute { name = "ariaFlowto"; jsxName = "aria-flowto"; type_ = String }
    (* Indicates an element's "grabbed" state in a drag-and-drop operation.
     * @deprecated in ARIA 1.1
     *)
  ; Attribute
      { name = "ariaGrabbed"
      ; jsxName = "aria-grabbed"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates the availability and type of interactive popup element, such as menu or dialog, that can be triggered by an element. *)
  ; Attribute
      { name = "ariaHaspopup"
      ; jsxName = "aria-haspopup"
      ; type_ =
          String
          (* Bool | 'false' | 'true' | 'menu' | 'listbox' | 'tree' | 'grid' | 'dialog'; *)
      }
    (* Indicates whether the element is exposed to an accessibility API.
     * @see aria-disabled.
     *)
  ; Attribute
      { name = "ariaHidden"
      ; jsxName = "aria-hidden"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates the entered value does not conform to the format expected by the application.
     * @see aria-errormessage.
     *)
  ; Attribute
      { name = "ariaInvalid"
      ; jsxName = "aria-invalid"
      ; type_ = String (* Bool | 'false' | 'true' |  'grammar' | 'spelling'; *)
      }
    (* Indicates keyboard shortcuts that an author has implemented to activate or give focus to an element. *)
  ; Attribute
      { name = "ariaKeyshortcuts"
      ; jsxName = "aria-keyshortcuts"
      ; type_ = String
      }
    (* Defines a String value that labels the current element.
     * @see aria-labelledby.
     *)
  ; Attribute { name = "ariaLabel"; jsxName = "aria-label"; type_ = String }
    (* Identifies the element (or elements) that labels the current element.
     * @see aria-describedby.
     *)
  ; Attribute
      { name = "ariaLabelledby"; jsxName = "aria-labelledby"; type_ = String }
    (* Defines the hierarchical level of an element within a structure. *)
  ; Attribute { name = "ariaLevel"; jsxName = "aria-level"; type_ = Int }
    (* Indicates that an element will be updated, and describes the types of updates the user agents, assistive technologies, and user can expect ;rom the live region. *)
  ; Attribute
      { name = "ariaLive"
      ; jsxName = "aria-live"
      ; type_ = String (* 'off' | 'assertive' | 'polite' *)
      }
    (* Indicates whether an element is modal when displayed. *)
  ; Attribute
      { name = "ariaModal"
      ; jsxName = "aria-modal"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates whether a text box accepts multiple lines of input or only a single line. *)
  ; Attribute
      { name = "ariaMultiline"
      ; jsxName = "aria-multiline"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates that the user may select more than one item from the current selectable descendants. *)
  ; Attribute
      { name = "ariaMultiselectable"
      ; jsxName = "aria-multiselectable"
      ; type_ = String (* Bool |  'false' | 'true' *)
      }
    (* Indicates whether the element's orientation is horizontal, vertical, or unknown/ambiguous. *)
  ; Attribute
      { name = "ariaOrientation"
      ; jsxName = "aria-orientation"
      ; type_ = String (* 'horizontal' | 'vertical' *)
      }
    (* Identifies an element (or elements) in order to define a visual, functional, or contextual parent/child relationship
     * between DOM elements where the DOM hierarchy cannot be used to represent the relationship.
     * @see aria-controls.
     *)
  ; Attribute { name = "ariaOwns"; jsxName = "aria-owns"; type_ = String }
    (* Defines a short hint (a word or short phrase) intended to aid the user with data entry when the control has no value.
     * A hint could be a sample value or a brief description of the expected format.
     *)
  ; Attribute
      { name = "ariaPlaceholder"; jsxName = "aria-placeholder"; type_ = String }
    (* Defines an element's number or position in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
     * @see aria-setsize.
     *)
  ; Attribute { name = "ariaPosinset"; jsxName = "aria-posinset"; type_ = Int }
    (* Indicates the current "pressed" state of toggle buttons.
     * @see aria-checked @see aria-selected.
     *)
  ; Attribute
      { name = "ariaPressed"
      ; jsxName = "aria-pressed"
      ; type_ = String (* Bool | 'false' | 'mixed' | 'true' *)
      }
    (* Indicates that the element is not editable, but is otherwise operable.
     * @see aria-disabled.
     *)
  ; Attribute
      { name = "ariaReadonly"
      ; jsxName = "aria-readonly"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Indicates what notifications the user agent will trigger when the accessibility tree within a live region is modified.
     * @see aria-atomic.
     *)
  ; Attribute
      { name = "ariaRelevant"
      ; jsxName = "aria-relevant"
      ; type_ =
          String
          (* 'additions' | 'additions removals' | 'additions text' | 'all' | 'removals' | 'removals additions' | 'removals text' | 'text' | 'text additions' | 'text removals' *)
      }
    (* Indicates that user input is required on the element before a form may be submitted. *)
  ; Attribute
      { name = "ariaRequired"
      ; jsxName = "aria-required"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Defines a human-readable, author-localized description for the role of an element. *)
  ; Attribute
      { name = "ariaRoledescription"
      ; jsxName = "aria-roledescription"
      ; type_ = String
      }
    (* Defines the total number of rows in a table, grid, or treegrid.
     * @see aria-rowindex.
     *)
  ; Attribute { name = "ariaRowcount"; jsxName = "aria-rowcount"; type_ = Int }
    (* Defines an element's row index or position with respect to the total number of rows within a table, grid, or treegrid.
     * @see aria-rowcount @see aria-rowspan.
     *)
  ; Attribute { name = "ariaRowindex"; jsxName = "aria-rowindex"; type_ = Int }
    (* Defines the number of rows spanned by a cell or gridcell within a table, grid, or treegrid.
     * @see aria-rowindex @see aria-colspan.
     *)
  ; Attribute { name = "ariaRowspan"; jsxName = "aria-rowspan"; type_ = Int }
    (* Indicates the current "selected" state of various widgets.
     * @see aria-checked @see aria-pressed.
     *)
  ; Attribute
      { name = "ariaSelected"
      ; jsxName = "aria-selected"
      ; type_ = String (* Bool | 'false' | 'true' *)
      }
    (* Defines the number of items in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
     * @see aria-posinset.
     *)
  ; Attribute { name = "ariaSetsize"; jsxName = "aria-setsize"; type_ = Int }
    (* Indicates if items in a table or grid are sorted in ascending or descending order. *)
  ; Attribute
      { name = "ariaSort"
      ; jsxName = "aria-sort"
      ; type_ = String (* 'none' | 'ascending' | 'descending' | 'other' *)
      }
    (* Defines the maximum allowed value for a range widget. *)
  ; Attribute { name = "ariaValuemax"; jsxName = "aria-valuemax"; type_ = Int }
    (* Defines the minimum allowed value for a range widget. *)
  ; Attribute { name = "ariaValuemin"; jsxName = "aria-valuemin"; type_ = Int }
    (* Defines the current value for a range widget.
     * @see aria-valuetext.
     *)
  ; Attribute { name = "ariaValuenow"; jsxName = "aria-valuenow"; type_ = Int }
    (* Defines the human readable text alternative of aria-valuenow for a range widget. *)
  ; Attribute
      { name = "ariaValuetext"; jsxName = "aria-valuetext"; type_ = String }
  ]

(* All the WAI-ARIA 1.1 role attribute values from https://www.w3.org/TR/wai-aria-1.1/#role_definitions *)
let ariaRole = String
(* | Alert
   | Alertdialog
   | Application
   | Article
   | Banner
   | Button
   | Cell
   | Checkbox
   | Columnheader
   | Combobox
   | Complementary
   | Contentinfo
   | Definition
   | Dialog
   | Directory
   | Document
   | Feed
   | Figure
   | Form
   | Grid
   | Gridcell
   | Group
   | Heading
   | Img
   | Link
   | List
   | Listbox
   | Listitem
   | Log
   | Main
   | Marquee
   | Math
   | Menu
   | Menubar
   | Menuitem
   | Menuitemcheckbox
   | Menuitemradio
   | Navigation
   | None
   | Note
   | Option
   | Presentation
   | Progressbar
   | Radio
   | Radiogroup
   | Region
   | Row
   | Rowgroup
   | Rowheader
   | Scrollbar
   | Search
   | Searchbox
   | Separator
   | Slider
   | Spinbutton
   | Status
   | Switch
   | Tab
   | Table
   | Tablist
   | Tabpanel
   | Term
   | Textbox
   | Timer
   | Toolbar
   | Tooltip
   | Tree
   | Treegrid
   | Treeitem
   | Custom of String *)

let reactAttributes =
  [ (* https://reactjs.org/docs/dom-elements.html *)
    Attribute
      { name = "dangerouslySetInnerHTML"
      ; jsxName = "dangerouslySetInnerHTML"
      ; type_ = InnerHtml
      }
  ; Attribute { name = "ref"; jsxName = "ref"; type_ = Ref }
  ; Attribute { name = "key"; jsxName = "key"; type_ = String }
  ; Attribute { name = "className"; jsxName = "className"; type_ = String }
  ; Attribute
      { name = "defaultChecked"; jsxName = "defaultChecked"; type_ = Bool }
  ; Attribute
      { name = "defaultValue"
      ; jsxName = "defaultValue"
      ; type_ = String (* | number | ReadonlyArray<String> *)
      }
  ; Attribute
      { name = "suppressContentEditableWarning"
      ; jsxName = "suppressContentEditableWarning"
      ; type_ = Bool
      }
  ; Attribute
      { name = "suppressHydrationWarning"
      ; jsxName = "suppressHydrationWarning"
      ; type_ = Bool
      }
  ]

let globalAttributes =
  [ (* https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes *)
    (* Standard HTML Attributes *)
    Attribute { name = "accessKey"; jsxName = "accessKey"; type_ = String }
  ; Attribute
      { name = "autoCapitalize"; jsxName = "autoCapitalize"; type_ = String }
  ; Attribute { name = "contextMenu"; jsxName = "contextMenu"; type_ = String }
  ; Attribute
      { name = "contentEditable"; jsxName = "contentEditable"; type_ = String }
  ; Attribute { name = "dir"; jsxName = "dir"; type_ = String }
  ; Attribute
      { name = "draggable"
      ; jsxName = "draggable"
      ; type_ = String (* Booleanish *)
      }
  ; Attribute { name = "hidden"; jsxName = "hidden"; type_ = Bool }
  ; Attribute { name = "id"; jsxName = "id"; type_ = String }
  ; Attribute { name = "itemProp"; jsxName = "itemProp"; type_ = String }
  ; Attribute { name = "itemScope"; jsxName = "itemScope"; type_ = Bool }
  ; Attribute { name = "itemType"; jsxName = "itemType"; type_ = String }
  ; Attribute { name = "itemID"; jsxName = "itemID"; type_ = String }
  ; Attribute { name = "itemRef"; jsxName = "itemRef"; type_ = String }
  ; Attribute { name = "lang"; jsxName = "lang"; type_ = String }
  ; Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String }
  ; Attribute { name = "part"; jsxName = "part"; type_ = String }
  ; Attribute { name = "nonce"; jsxName = "nonce"; type_ = String }
  ; Attribute { name = "slot"; jsxName = "slot"; type_ = String }
  ; Attribute
      { name = "spellCheck"
      ; jsxName = "spellCheck"
      ; type_ = String (* Booleanish *)
      }
  ; Attribute { name = "style"; jsxName = "style"; type_ = Style }
  ; Attribute { name = "tabIndex"; jsxName = "tabIndex"; type_ = Int }
  ; Attribute { name = "enterKeyHint"; jsxName = "enterKeyHint"; type_ = Int }
    (* data-* attributes are globaly available *)
    (* Experimental ; Attribute {name= "exportParts"; jsxName= "exportParts"; type_= Int} *)
  ; Attribute { name = "title"; jsxName = "title"; type_ = String }
  ; Attribute
      { name = "translate"
      ; jsxName = "translate"
      ; type_ = String (* 'yes' | 'no' *)
      }
    (* Living Standard
       * Hints at the type of data that might be entered by the user while editing the element or its contents
       * @see https://html.spec.whatwg.org/multipage/interaction.html#input-modalities:-the-inputmode-attribute *)
  ; Attribute
      { name = "inputMode"
      ; jsxName = "inputmode"
      ; type_ =
          String
          (* 'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search' *)
      }
    (* Specify that a standard HTML element should behave like a defined custom built-in element
        * @see https://html.spec.whatwg.org/multipage/custom-elements.html#attr-is *)
  ; Attribute { name = "is"; jsxName = "is"; type_ = String }
  ]

let elementAttributes =
  [ Attribute { name = "radioGroup"; jsxName = "radioGroup"; type_ = String }
    (* WAI-ARIA *)
  ; Attribute { name = "role"; jsxName = "role"; type_ = ariaRole }
    (* RDFa Attributes *)
  ; Attribute { name = "about"; jsxName = "about"; type_ = String }
  ; Attribute { name = "dataType"; jsxName = "dataType"; type_ = String }
  ; Attribute { name = "inlist"; jsxName = "inlist"; type_ = String (* any *) }
  ; Attribute { name = "prefix"; jsxName = "prefix"; type_ = String }
  ; Attribute { name = "property"; jsxName = "property"; type_ = String }
  ; Attribute { name = "resource"; jsxName = "resource"; type_ = String }
  ; Attribute { name = "typeof"; jsxName = "typeof"; type_ = String }
  ; Attribute { name = "vocab"; jsxName = "vocab"; type_ = String }
    (* Non-standard Attributes *)
  ; Attribute { name = "autoCorrect"; jsxName = "autoCorrect"; type_ = String }
  ; Attribute { name = "autoSave"; jsxName = "autoSave"; type_ = String }
  ; Attribute { name = "color"; jsxName = "color"; type_ = String }
  ; Attribute { name = "results"; jsxName = "results"; type_ = Int }
  ; Attribute { name = "security"; jsxName = "security"; type_ = String }
  ]

let anchorHTMLAttributes =
  [ Attribute
      { name = "download"; jsxName = "download"; type_ = String (* any; *) }
  ; Attribute { name = "href"; jsxName = "href"; type_ = String }
  ; Attribute { name = "hrefLang"; jsxName = "hrefLang"; type_ = String }
  ; Attribute { name = "media"; jsxName = "media"; type_ = String }
  ; Attribute { name = "ping"; jsxName = "ping"; type_ = String }
  ; Attribute { name = "rel"; jsxName = "rel"; type_ = String }
  ; Attribute
      { name = "target"; jsxName = "target"; type_ = attributeAnchorTarget }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ; Attribute
      { name = "referrerPolicy"
      ; jsxName = "referrerPolicy"
      ; type_ = attributeReferrerPolicy
      }
  ]

let areaHTMLAttributes =
  [ Attribute { name = "alt"; jsxName = "alt"; type_ = String }
  ; Attribute { name = "coords"; jsxName = "coords"; type_ = String }
  ; Attribute
      { name = "download"; jsxName = "download"; type_ = String (* any *) }
  ; Attribute { name = "href"; jsxName = "href"; type_ = String }
  ; Attribute { name = "hrefLang"; jsxName = "hrefLang"; type_ = String }
  ; Attribute { name = "media"; jsxName = "media"; type_ = String }
  ; Attribute
      { name = "referrerPolicy"
      ; jsxName = "referrerPolicy"
      ; type_ = attributeReferrerPolicy
      }
  ; Attribute { name = "rel"; jsxName = "rel"; type_ = String }
  ; Attribute { name = "shape"; jsxName = "shape"; type_ = String }
  ; Attribute { name = "target"; jsxName = "target"; type_ = String }
  ]

let baseHTMLAttributes =
  [ Attribute { name = "href"; jsxName = "href"; type_ = String }
  ; Attribute { name = "target"; jsxName = "target"; type_ = String }
  ]

let blockquoteHTMLAttributes =
  [ Attribute { name = "cite"; jsxName = "cite"; type_ = String } ]

let buttonHTMLAttributes =
  [ Attribute { name = "autoFocus"; jsxName = "autofocus"; type_ = Bool }
  ; Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "formAction"; jsxName = "formAction"; type_ = String }
  ; Attribute { name = "formEncType"; jsxName = "formEncType"; type_ = String }
  ; Attribute { name = "formMethod"; jsxName = "formMethod"; type_ = String }
  ; Attribute
      { name = "formNoValidate"; jsxName = "formNoValidate"; type_ = Bool }
  ; Attribute { name = "formTarget"; jsxName = "formTarget"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute
      { name = "type_"
      ; jsxName = "type"
      ; type_ = String (* 'submit' | 'reset' | 'button' *)
      }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let canvasHTMLAttributes =
  [ Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let colHTMLAttributes =
  [ Attribute { name = "span"; jsxName = "span"; type_ = Int (* number *) }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let colgroupHTMLAttributes =
  [ Attribute { name = "span"; jsxName = "span"; type_ = Int (* number *) } ]

let dataHTMLAttributes =
  [ Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let detailsHTMLAttributes =
  [ Attribute { name = "open"; jsxName = "open"; type_ = Bool }
  ; Event { name = "onToggle"; type_ = Media }
  ]

let delHTMLAttributes =
  [ Attribute { name = "cite"; type_ = String; jsxName = "cite" }
  ; Attribute { name = "dateTime"; type_ = String; jsxName = "dateTime" }
  ]

let dialogHTMLAttributes =
  [ Attribute { name = "open"; jsxName = "open"; type_ = Bool } ]

let embedHTMLAttributes =
  [ Attribute
      { name = "height"; type_ = String (* number |  *); jsxName = "height" }
  ; Attribute { name = "src"; type_ = String; jsxName = "src" }
  ; Attribute { name = "type_"; type_ = String; jsxName = "type" }
  ; Attribute
      { name = "width"; type_ = String (* number |  *); jsxName = "width" }
  ]

let fieldsetHTMLAttributes =
  [ Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ]

let formHTMLAttributes =
  [ Attribute
      { name = "acceptCharset"; jsxName = "acceptCharset"; type_ = String }
  ; Attribute { name = "action"; jsxName = "action"; type_ = String }
  ; Attribute
      { name = "autoComplete"; jsxName = "autoComplete"; type_ = String }
  ; Attribute { name = "encType"; jsxName = "encType"; type_ = String }
  ; Attribute { name = "method"; jsxName = "method"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "noValidate"; jsxName = "noValidate"; type_ = Bool }
  ; Attribute { name = "target"; jsxName = "target"; type_ = String }
  ]

let htmlHTMLAttributes =
  [ Attribute { name = "manifest"; jsxName = "manifest"; type_ = String } ]

let iframeHTMLAttributes =
  [ Attribute { name = "allow"; jsxName = "allow"; type_ = String }
  ; Attribute
      { name = "allowFullScreen"; jsxName = "allowFullScreen"; type_ = Bool }
  ; Attribute
      { name = "allowTransparency"
      ; jsxName = "allowTransparency"
      ; type_ = Bool
      }
  ; (* deprecated *)
    Attribute
      { name = "frameBorder"
      ; jsxName = "frameBorder"
      ; type_ = String (* number |  *)
      }
  ; Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; (* deprecated *)
    Attribute
      { name = "marginHeight"
      ; jsxName = "marginHeight"
      ; type_ = Int (* number *)
      }
  ; (* deprecated *)
    Attribute
      { name = "marginWidth"
      ; jsxName = "marginWidth"
      ; type_ = Int (* number *)
      }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "sandbox"; jsxName = "sandbox"; type_ = String }
  ; (* deprecated *)
    Attribute { name = "scrolling"; jsxName = "scrolling"; type_ = String }
  ; Attribute { name = "seamless"; jsxName = "seamless"; type_ = Bool }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "srcDoc"; jsxName = "srcDoc"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let imgHTMLAttributes =
  [ Attribute { name = "alt"; jsxName = "alt"; type_ = String }
  ; Attribute
      { name = "crossOrigin"
      ; jsxName = "crossOrigin"
      ; type_ = String (* "anonymous" | "use-credentials" | "" *)
      }
  ; Attribute
      { name = "decoding"
      ; jsxName = "decoding"
      ; type_ = String (* "async" | "auto" | "sync" *)
      }
  ; Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute { name = "sizes"; jsxName = "sizes"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "srcSet"; jsxName = "srcset"; type_ = String }
  ; Attribute { name = "useMap"; jsxName = "usemap"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let insHTMLAttributes =
  [ Attribute { name = "cite"; jsxName = "cite"; type_ = String }
  ; Attribute { name = "dateTime"; jsxName = "datetime"; type_ = String }
  ]

let inputTypeAttribute = String
(*
        | 'button'
        | 'checkbox'
        | 'color'
        | 'date'
        | 'datetime-local'
        | 'email'
        | 'file'
        | 'hidden'
        | 'image'
        | 'month'
        | 'number'
        | 'password'
        | 'radio'
        | 'range'
        | 'reset'
        | 'search'
        | 'submit'
        | 'tel'
        | 'text'
        | 'time'
        | 'url'
        | 'week'
        | (String & {}); *)

let inputHTMLAttributes =
  [ Attribute { name = "accept"; jsxName = "accept"; type_ = String }
  ; Attribute { name = "alt"; jsxName = "alt"; type_ = String }
  ; Attribute
      { name = "autoComplete"; jsxName = "autoComplete"; type_ = String }
  ; Attribute { name = "autoFocus"; jsxName = "autoFocus"; type_ = Bool }
  ; Attribute
      { name = "capture"
      ; jsxName = "capture"
      ; type_ =
          String
          (* Bool | *)
          (* https://www.w3.org/TR/html-media-capture/ *)
      }
  ; Attribute { name = "checked"; jsxName = "checked"; type_ = Bool }
  ; Attribute { name = "crossOrigin"; jsxName = "crossOrigin"; type_ = String }
  ; Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "formAction"; jsxName = "formAction"; type_ = String }
  ; Attribute { name = "formEncType"; jsxName = "formEncType"; type_ = String }
  ; Attribute { name = "formMethod"; jsxName = "formMethod"; type_ = String }
  ; Attribute
      { name = "formNoValidate"; jsxName = "formNoValidate"; type_ = Bool }
  ; Attribute { name = "formTarget"; jsxName = "formTarget"; type_ = String }
  ; Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute { name = "list"; jsxName = "list"; type_ = String }
  ; Attribute { name = "max"; jsxName = "max"; type_ = String (* number |  *) }
  ; Attribute
      { name = "maxLength"; jsxName = "maxLength"; type_ = Int (* number *) }
  ; Attribute { name = "min"; jsxName = "min"; type_ = String (* number |  *) }
  ; Attribute
      { name = "minLength"; jsxName = "minLength"; type_ = Int (* number *) }
  ; Attribute { name = "multiple"; jsxName = "multiple"; type_ = Bool }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "pattern"; jsxName = "pattern"; type_ = String }
  ; Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String }
  ; Attribute { name = "readOnly"; jsxName = "readOnly"; type_ = Bool }
  ; Attribute { name = "required"; jsxName = "required"; type_ = Bool }
  ; Attribute { name = "size"; jsxName = "size"; type_ = Int (* number *) }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute
      { name = "step"; jsxName = "step"; type_ = String (* number |  *) }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = inputTypeAttribute }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ; Event { name = "onChange"; type_ = Form }
  ]

let keygenHTMLAttributes =
  [ Attribute { name = "autoFocus"; jsxName = "autoFocus"; type_ = Bool }
  ; Attribute { name = "challenge"; jsxName = "challenge"; type_ = String }
  ; Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "keyType"; jsxName = "keyType"; type_ = String }
  ; Attribute { name = "keyParams"; jsxName = "keyParams"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ]

let labelHTMLAttributes =
  [ Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "htmlFor"; jsxName = "htmlFor"; type_ = String }
  ]

let liHTMLAttributes =
  [ Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let linkHTMLAttributes =
  [ Attribute { name = "as"; jsxName = "as"; type_ = String }
  ; Attribute { name = "crossOrigin"; jsxName = "crossOrigin"; type_ = String }
  ; Attribute { name = "href"; jsxName = "href"; type_ = String }
  ; Attribute { name = "hrefLang"; jsxName = "hrefLang"; type_ = String }
  ; Attribute { name = "integrity"; jsxName = "integrity"; type_ = String }
  ; Attribute { name = "imageSrcSet"; jsxName = "imageSrcSet"; type_ = String }
  ; Attribute { name = "media"; jsxName = "media"; type_ = String }
  ; Attribute { name = "rel"; jsxName = "rel"; type_ = String }
  ; Attribute { name = "sizes"; jsxName = "sizes"; type_ = String }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ; Attribute { name = "charSet"; jsxName = "charSet"; type_ = String }
  ]

let mapHTMLAttributes =
  [ Attribute { name = "name"; jsxName = "name"; type_ = String } ]

let menuHTMLAttributes =
  [ Attribute { name = "type_"; jsxName = "type"; type_ = String } ]

let mediaHTMLAttributes =
  [ Attribute { name = "autoPlay"; jsxName = "autoPlay"; type_ = Bool }
  ; Attribute { name = "controls"; jsxName = "controls"; type_ = Bool }
  ; Attribute
      { name = "controlsList"; jsxName = "controlsList"; type_ = String }
  ; Attribute { name = "crossOrigin"; jsxName = "crossOrigin"; type_ = String }
  ; Attribute { name = "loop"; jsxName = "loop"; type_ = Bool }
  ; (* deprecated *)
    Attribute { name = "mediaGroup"; jsxName = "mediaGroup"; type_ = String }
  ; Attribute { name = "muted"; jsxName = "muted"; type_ = Bool }
  ; Attribute { name = "playsInline"; jsxName = "playsInline"; type_ = Bool }
  ; Attribute { name = "preload"; jsxName = "preload"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ]

let metaHTMLAttributes =
  [ Attribute { name = "charSet"; jsxName = "charSet"; type_ = String }
  ; Attribute { name = "content"; jsxName = "content"; type_ = String }
  ; Attribute { name = "httpEquiv"; jsxName = "httpEquiv"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "media"; jsxName = "media"; type_ = String }
  ]

let meterHTMLAttributes =
  [ Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "high"; jsxName = "high"; type_ = Int (* number *) }
  ; Attribute { name = "low"; jsxName = "low"; type_ = Int (* number *) }
  ; Attribute { name = "max"; jsxName = "max"; type_ = String (* number |  *) }
  ; Attribute { name = "min"; jsxName = "min"; type_ = String (* number |  *) }
  ; Attribute
      { name = "optimum"; jsxName = "optimum"; type_ = Int (* number *) }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let quoteHTMLAttributes =
  [ Attribute { name = "cite"; jsxName = "cite"; type_ = String } ]

let objectHTMLAttributes =
  [ Attribute { name = "classID"; jsxName = "classID"; type_ = String }
  ; Attribute { name = "data"; jsxName = "data"; type_ = String }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ; Attribute { name = "useMap"; jsxName = "useMap"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ; Attribute { name = "wmode"; jsxName = "wmode"; type_ = String }
  ]

let olHTMLAttributes =
  [ Attribute { name = "reversed"; jsxName = "reversed"; type_ = Bool }
  ; Attribute { name = "start"; jsxName = "start"; type_ = Int (* number *) }
  ; Attribute
      { name = "type_"
      ; jsxName = "type"
      ; type_ = String (* '1' | 'a' | 'A' | 'i' | 'I' *)
      }
  ]

let optgroupHTMLAttributes =
  [ Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "label"; jsxName = "label"; type_ = String }
  ]

let optionHTMLAttributes =
  [ Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "label"; jsxName = "label"; type_ = String }
  ; Attribute { name = "selected"; jsxName = "selected"; type_ = Bool }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let outputHTMLAttributes =
  [ Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "htmlFor"; jsxName = "htmlFor"; type_ = String }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ]

let paramHTMLAttributes =
  [ Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let progressHTMLAttributes =
  [ Attribute { name = "max"; jsxName = "max"; type_ = String (* number |  *) }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ]

let slotHTMLAttributes =
  [ Attribute { name = "name"; jsxName = "name"; type_ = String } ]

let scriptHTMLAttributes =
  [ (* deprecated *)
    Attribute { name = "async"; jsxName = "async"; type_ = Bool }
  ; Attribute { name = "charSet"; jsxName = "charSet"; type_ = String }
  ; Attribute { name = "crossOrigin"; jsxName = "crossOrigin"; type_ = String }
  ; Attribute { name = "defer"; jsxName = "defer"; type_ = Bool }
  ; Attribute { name = "integrity"; jsxName = "integrity"; type_ = String }
  ; Attribute { name = "noModule"; jsxName = "noModule"; type_ = Bool }
  ; Attribute { name = "nonce"; jsxName = "nonce"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ]

let selectHTMLAttributes =
  [ Attribute
      { name = "autoComplete"; jsxName = "autoComplete"; type_ = String }
  ; Attribute { name = "autoFocus"; jsxName = "autoFocus"; type_ = Bool }
  ; Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute { name = "multiple"; jsxName = "multiple"; type_ = Bool }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "required"; jsxName = "required"; type_ = Bool }
  ; Attribute { name = "size"; jsxName = "size"; type_ = Int (* number *) }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ; Event { name = "onChange"; type_ = Form }
  ]

let sourceHTMLAttributes =
  [ Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute { name = "media"; jsxName = "media"; type_ = String }
  ; Attribute { name = "sizes"; jsxName = "sizes"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "srcSet"; jsxName = "srcSet"; type_ = String }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let styleHTMLAttributes =
  [ Attribute { name = "media"; jsxName = "media"; type_ = String }
  ; Attribute { name = "nonce"; jsxName = "nonce"; type_ = String }
  ; Attribute { name = "scoped"; jsxName = "scoped"; type_ = Bool }
  ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
  ]

let tableHTMLAttributes =
  [ Attribute
      { name = "cellPadding"
      ; jsxName = "cellPadding"
      ; type_ = String (* number |  *)
      }
  ; Attribute
      { name = "cellSpacing"
      ; jsxName = "cellSpacing"
      ; type_ = String (* number |  *)
      }
  ; Attribute { name = "summary"; jsxName = "summary"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ]

let textareaHTMLAttributes =
  [ Attribute
      { name = "autoComplete"; jsxName = "autoComplete"; type_ = String }
  ; Attribute { name = "autoFocus"; jsxName = "autoFocus"; type_ = String }
  ; Attribute { name = "cols"; jsxName = "cols"; type_ = Int (* number *) }
  ; Attribute { name = "dirName"; jsxName = "dirName"; type_ = String }
  ; Attribute { name = "disabled"; jsxName = "disabled"; type_ = Bool }
  ; Attribute { name = "form"; jsxName = "form"; type_ = String }
  ; Attribute
      { name = "maxLength"; jsxName = "maxLength"; type_ = Int (* number *) }
  ; Attribute
      { name = "minLength"; jsxName = "minLength"; type_ = Int (* number *) }
  ; Attribute { name = "name"; jsxName = "name"; type_ = String }
  ; Attribute { name = "placeholder"; jsxName = "placeholder"; type_ = String }
  ; Attribute { name = "readOnly"; jsxName = "readOnly"; type_ = Bool }
  ; Attribute { name = "required"; jsxName = "required"; type_ = Bool }
  ; Attribute { name = "rows"; jsxName = "rows"; type_ = Int (* number *) }
  ; Attribute
      { name = "value"
      ; jsxName = "value"
      ; type_ = String (* | ReadonlyArray<String> | number *)
      }
  ; Attribute { name = "wrap"; jsxName = "wrap"; type_ = String }
  ; Event { name = "onChange"; type_ = Form }
  ]

let tdHTMLAttributes =
  [ Attribute
      { name = "align"
      ; jsxName = "align"
      ; type_ =
          String (* type_= "left" | "center" | "right" | "justify" | "char" *)
      }
  ; Attribute
      { name = "colSpan"; jsxName = "colSpan"; type_ = Int (* number *) }
  ; Attribute { name = "headers"; jsxName = "headers"; type_ = String }
  ; Attribute
      { name = "rowSpan"; jsxName = "rowspan"; type_ = Int (* number *) }
  ; Attribute { name = "scope"; jsxName = "scope"; type_ = String }
  ; Attribute { name = "abbr"; jsxName = "abbr"; type_ = String }
  ; Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ; Attribute
      { name = "valign"
      ; jsxName = "valign"
      ; type_ = String (* "top" | "middle" | "bottom" | "baseline" *)
      }
  ]

let thHTMLAttributes =
  [ Attribute
      { name = "align"
      ; jsxName = "align"
      ; type_ = String (* "left" | "center" | "right" | "justify" | "char" *)
      }
  ; Attribute
      { name = "colSpan"; jsxName = "colSpan"; type_ = Int (* number *) }
  ; Attribute { name = "headers"; jsxName = "headers"; type_ = String }
  ; Attribute
      { name = "rowSpan"; jsxName = "rowSpan"; type_ = Int (* number *) }
  ; Attribute { name = "scope"; jsxName = "scope"; type_ = String }
  ; Attribute { name = "abbr"; jsxName = "abbr"; type_ = String }
  ]

let timeHTMLAttributes =
  [ Attribute { name = "dateTime"; jsxName = "datetime"; type_ = String } ]

let trackHTMLAttributes =
  [ Attribute { name = "default"; jsxName = "default"; type_ = Bool }
  ; Attribute { name = "kind"; jsxName = "kind"; type_ = String }
  ; Attribute { name = "label"; jsxName = "label"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "srcLang"; jsxName = "srclang"; type_ = String }
  ]

let videoHTMLAttributes =
  [ Attribute
      { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
  ; Attribute { name = "playsInline"; jsxName = "playsinline"; type_ = Bool }
  ; Attribute { name = "poster"; jsxName = "poster"; type_ = String }
  ; Attribute
      { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
  ; Attribute
      { name = "disablePictureInPicture"
      ; jsxName = "disablepictureinpicture"
      ; type_ = Bool
      }
  ]

module SVG = struct
  (* "https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/" *)

  let coreAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Core *)
    [ Attribute { name = "id"; jsxName = "id"; type_ = String }
    ; Attribute { name = "lang"; jsxName = "lang"; type_ = String }
    ; Attribute { name = "tabIndex"; jsxName = "tabIndex"; type_ = String }
    ; Attribute { name = "xmlBase"; jsxName = "xmlBase"; type_ = String }
    ; Attribute { name = "xmlLang"; jsxName = "xmlLang"; type_ = String }
    ; Attribute { name = "xmlSpace"; jsxName = "xmlSpace"; type_ = String }
    ]

  let stylingAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/Styling *)
    [ Attribute { name = "className"; jsxName = "className"; type_ = String }
    ; Attribute { name = "style"; jsxName = "style"; type_ = Style }
    ]

  let presentationAttributes =
    (* Presentation attributes *)
    [ Attribute
        { name = "clip"; jsxName = "clip"; type_ = String (* number |  *) }
    ; Attribute { name = "clipPath"; jsxName = "clipPath"; type_ = String }
    ; Attribute
        { name = "cursor"; jsxName = "cursor"; type_ = String (* number |  *) }
    ; Attribute { name = "fill"; jsxName = "fill"; type_ = String }
    ; Attribute { name = "filter"; jsxName = "filter"; type_ = String }
    ; Attribute { name = "fontFamily"; jsxName = "fontFamily"; type_ = String }
    ; Attribute
        { name = "letterSpacing"; jsxName = "letterSpacing"; type_ = String }
    ; Attribute
        { name = "lightingColor"; jsxName = "lightingColor"; type_ = String }
    ; Attribute { name = "markerEnd"; jsxName = "markerEnd"; type_ = String }
    ; Attribute { name = "mask"; jsxName = "mask"; type_ = String }
    ; Attribute
        { name = "pointerEvents"; jsxName = "pointerEvents"; type_ = String }
    ; Attribute { name = "stopColor"; jsxName = "stopColor"; type_ = String }
    ; Attribute { name = "stroke"; jsxName = "stroke"; type_ = String }
    ; Attribute { name = "textAnchor"; jsxName = "textAnchor"; type_ = String }
    ; Attribute { name = "transform"; jsxName = "transform"; type_ = String }
    ; Attribute
        { name = "transformOrigin"
        ; jsxName = "transformOrigin"
        ; type_ = String
        }
    ; Attribute
        { name = "alignmentBaseline"
        ; jsxName = "alignmentBaseline"
        ; type_ =
            String
            (* "auto" | "baseline" | "before-edge" | "text-before-edge" | "middle" | "central" | "after-edge" "text-after-edge" | "ideographic" | "alphabetic" | "hanging" | "mathematical" | "inherit" *)
        }
    ; Attribute
        { name = "clipRule"
        ; jsxName = "clipRule"
        ; type_ = (* number | "linearRGB" | "inherit" *) String
        }
    ; Attribute
        { name = "colorProfile"
        ; jsxName = "colorProfile"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "direction"
        ; jsxName = "direction"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "display"
        ; jsxName = "display"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "divisor"
        ; jsxName = "divisor"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fillOpacity"
        ; jsxName = "fillOpacity"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fillRule"
        ; jsxName = "fillRule"
        ; type_ = String (* type_= "nonzero" | "evenodd" | "inherit" *)
        }
    ; Attribute
        { name = "floodColor"
        ; jsxName = "floodColor"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "floodOpacity"
        ; jsxName = "floodOpacity"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fontSize"
        ; jsxName = "fontSize"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fontStretch"
        ; jsxName = "fontStretch"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fontStyle"
        ; jsxName = "fontStyle"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fontVariant"
        ; jsxName = "fontVariant"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "fontWeight"
        ; jsxName = "fontWeight"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "glyphOrientationHorizontal"
        ; jsxName = "glyphOrientationHorizontal"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "glyphOrientationVertical"
        ; jsxName = "glyphOrientationVertical"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "kerning"
        ; jsxName = "kerning"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "keyPoints"
        ; jsxName = "keyPoints"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "opacity"
        ; jsxName = "opacity"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "operator"
        ; jsxName = "operator"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "overflow"
        ; jsxName = "overflow"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "stopOpacity"
        ; jsxName = "stopOpacity"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "strokeLinecap"
        ; jsxName = "strokeLinecap"
        ; type_ = String (* type_= "butt" | "round" | "square" | "inherit" *)
        }
    ; Attribute
        { name = "unicodeBidi"
        ; jsxName = "unicodeBidi"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vectorEffect"
        ; jsxName = "vectorEffect"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "wordSpacing"
        ; jsxName = "wordSpacing"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "writingMode"
        ; jsxName = "writingMode"
        ; type_ = String (* number |  *)
        }
    ]

  let filtersAttributes =
    (* https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute#filters_attributes *)
    [ (* Filter primitive attributes *)
      Attribute
        { name = "height"; jsxName = "height"; type_ = String (* number |  *) }
    ; Attribute
        { name = "width"; jsxName = "width"; type_ = String (* number |  *) }
    ; Attribute { name = "result"; jsxName = "result"; type_ = String }
    ; Attribute { name = "x"; jsxName = "x"; type_ = String (* number |  *) }
    ; Attribute { name = "y"; jsxName = "y"; type_ = String (* number |  *) }
      (* Transfer function attributes
         type, tableValues, slope, intercept, amplitude, exponent, offset
      *)
    ; Attribute { name = "type_"; jsxName = "type"; type_ = String }
    ; Attribute
        { name = "exponent"
        ; jsxName = "exponent"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "slope"; jsxName = "slope"; type_ = String (* number |  *) }
    ; Attribute
        { name = "amplitude"
        ; jsxName = "amplitude"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "intercept"
        ; jsxName = "intercept"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "tableValues"
        ; jsxName = "tableValues"
        ; type_ = String (* number |  *)
        }
      (* Animation target element attributes
         *)
    ; Attribute { name = "href"; jsxName = "href"; type_ = String }
      (* Animation attribute target attributes*)
    ; Attribute
        { name = "attributeName"; jsxName = "attributeName"; type_ = String }
    ; Attribute
        { name = "attributeType"; jsxName = "attributeType"; type_ = String }
      (* Animation timing attributes
         begin, dur, end, min, max, restart, repeatCount, repeatDur, fill *)
    ; Attribute
        { name = "begin"; jsxName = "begin"; type_ = String (* number |  *) }
    ; Attribute
        { name = "dur"; jsxName = "dur"; type_ = String (* number |  *) }
    ; Attribute
        { name = "end"; jsxName = "end"; type_ = String (* number |  *) }
    ; Attribute
        { name = "max"; jsxName = "max"; type_ = String (* number |  *) }
    ; Attribute
        { name = "min"; jsxName = "min"; type_ = String (* number |  *) }
    ; Attribute
        { name = "repeatCount"
        ; jsxName = "repeatCount"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "restart"
        ; jsxName = "restart"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "repeatDur"
        ; jsxName = "repeatDur"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "fill"; jsxName = "fill"; type_ = String }
      (* Animation value attributes *)
    ; Attribute
        { name = "calcMode"
        ; jsxName = "calcMode"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "values"; jsxName = "values"; type_ = String }
    ; Attribute
        { name = "keySplines"
        ; jsxName = "keySplines"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "keyTimes"
        ; jsxName = "keyTimes"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "from"; jsxName = "from"; type_ = String (* number |  *) }
    ; Attribute { name = "to"; jsxName = "to"; type_ = String (* number |  *) }
    ; Attribute { name = "by"; jsxName = "by"; type_ = String (* number |  *) }
      (* Animation addition attributes *)
    ; Attribute
        { name = "accumulate"
        ; jsxName = "accumulate"
        ; type_ = String (* type_= "none" | "sum" *)
        }
    ; Attribute
        { name = "additive"
        ; jsxName = "additive"
        ; type_ = String (* type_= "replace" | "sum" *)
        }
    ]

  let htmlAttributes =
    (* These are valid SVG attributes, that are HTML Attributes as well *)
    [ Attribute { name = "color"; jsxName = "color"; type_ = String }
    ; Attribute { name = "id"; jsxName = "id"; type_ = String }
    ; Attribute { name = "lang"; jsxName = "lang"; type_ = String }
    ; Attribute { name = "media"; jsxName = "media"; type_ = String }
    ; Attribute { name = "method"; jsxName = "method"; type_ = String }
    ; Attribute { name = "name"; jsxName = "name"; type_ = String }
    ; Attribute { name = "style"; jsxName = "style"; type_ = Style }
    ; Attribute { name = "target"; jsxName = "target"; type_ = String }
      (* Other HTML properties supported by SVG elements in browsers *)
    ; Attribute { name = "role"; jsxName = "role"; type_ = ariaRole }
    ; Attribute
        { name = "tabIndex"; jsxName = "tabIndex"; type_ = Int (* number *) }
    ; Attribute
        { name = "crossOrigin"
        ; jsxName = "crossOrigin"
        ; type_ = String (* "anonymous" | "use-credentials" | "" *)
        }
      (* SVG Specific attributes *)
    ; Attribute
        { name = "accentHeight"
        ; jsxName = "accentHeight"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "allowReorder"
        ; jsxName = "allowReorder"
        ; type_ = String (* type_= "no" | "yes" *)
        }
    ; Attribute
        { name = "alphabetic"
        ; jsxName = "alphabetic"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "arabicForm"
        ; jsxName = "arabicForm"
        ; type_ =
            String (* type_= "initial" | "medial" | "terminal" | "isolated" *)
        }
    ; Attribute
        { name = "ascent"; jsxName = "ascent"; type_ = String (* number |  *) }
    ; Attribute
        { name = "autoReverse"
        ; jsxName = "autoReverse"
        ; type_ = String (* Booleanish *)
        }
    ; Attribute
        { name = "azimuth"
        ; jsxName = "azimuth"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "baseProfile"
        ; jsxName = "baseProfile"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "bbox"; jsxName = "bbox"; type_ = String (* number |  *) }
    ; Attribute
        { name = "bias"; jsxName = "bias"; type_ = String (* number |  *) }
    ; Attribute
        { name = "capHeight"
        ; jsxName = "capHeight"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "cx"; jsxName = "cx"; type_ = String (* number |  *) }
    ; Attribute { name = "cy"; jsxName = "cy"; type_ = String (* number |  *) }
    ; Attribute { name = "d"; jsxName = "d"; type_ = String }
    ; Attribute
        { name = "decelerate"
        ; jsxName = "decelerate"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "descent"
        ; jsxName = "descent"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "dx"; jsxName = "dx"; type_ = String (* number |  *) }
    ; Attribute { name = "dy"; jsxName = "dy"; type_ = String (* number |  *) }
    ; Attribute
        { name = "edgeMode"
        ; jsxName = "edgeMode"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "elevation"
        ; jsxName = "elevation"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "externalResourcesRequired"
        ; jsxName = "externalResourcesRequired"
        ; type_ = String (* Booleanish *)
        }
    ; Attribute
        { name = "filterRes"
        ; jsxName = "filterRes"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "filterUnits"
        ; jsxName = "filterUnits"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "format"; jsxName = "format"; type_ = String (* number |  *) }
    ; Attribute { name = "fr"; jsxName = "fr"; type_ = String (* number |  *) }
    ; Attribute { name = "fx"; jsxName = "fx"; type_ = String (* number |  *) }
    ; Attribute { name = "fy"; jsxName = "fy"; type_ = String (* number |  *) }
    ; Attribute { name = "g1"; jsxName = "g1"; type_ = String (* number |  *) }
    ; Attribute { name = "g2"; jsxName = "g2"; type_ = String (* number |  *) }
    ; Attribute
        { name = "glyphName"
        ; jsxName = "glyphName"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "glyphRef"
        ; jsxName = "glyphRef"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "gradientTransform"
        ; jsxName = "gradientTransform"
        ; type_ = String
        }
    ; Attribute
        { name = "gradientUnits"; jsxName = "gradientUnits"; type_ = String }
    ; Attribute
        { name = "hanging"
        ; jsxName = "hanging"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "horizAdvX"
        ; jsxName = "horizAdvX"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "horizOriginX"
        ; jsxName = "horizOriginX"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "ideographic"
        ; jsxName = "ideographic"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "in2"; jsxName = "in2"; type_ = String (* number |  *) }
    ; Attribute { name = "in"; jsxName = "in"; type_ = String }
    ; Attribute { name = "k1"; jsxName = "k1"; type_ = String (* number |  *) }
    ; Attribute { name = "k2"; jsxName = "k2"; type_ = String (* number |  *) }
    ; Attribute { name = "k3"; jsxName = "k3"; type_ = String (* number |  *) }
    ; Attribute { name = "k4"; jsxName = "k4"; type_ = String (* number |  *) }
    ; Attribute { name = "k"; jsxName = "k"; type_ = String (* number |  *) }
    ; Attribute
        { name = "kernelMatrix"
        ; jsxName = "kernelMatrix"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "limitingConeAngle"
        ; jsxName = "limitingConeAngle"
        ; type_ = String
        }
    ; Attribute
        { name = "lengthAdjust"
        ; jsxName = "lengthAdjust"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "local"; jsxName = "local"; type_ = String (* number |  *) }
    ; Attribute
        { name = "markerHeight"
        ; jsxName = "markerHeight"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "markerMid"; jsxName = "markerMid"; type_ = String }
    ; Attribute
        { name = "markerStart"; jsxName = "markerStart"; type_ = String }
    ; Attribute
        { name = "markerUnits"
        ; jsxName = "markerUnits"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "markerWidth"
        ; jsxName = "markerWidth"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "maskUnits"
        ; jsxName = "maskUnits"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "mathematical"
        ; jsxName = "mathematical"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "mode"; jsxName = "mode"; type_ = String (* number |  *) }
    ; Attribute
        { name = "numOctaves"
        ; jsxName = "numOctaves"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "offset"; jsxName = "offset"; type_ = String (* number |  *) }
    ; Attribute
        { name = "order"; jsxName = "order"; type_ = String (* number |  *) }
    ; Attribute
        { name = "orient"; jsxName = "orient"; type_ = String (* number |  *) }
    ; Attribute
        { name = "orientation"
        ; jsxName = "orientation"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "origin"; jsxName = "origin"; type_ = String (* number |  *) }
    ; Attribute
        { name = "overlineThickness"
        ; jsxName = "overlineThickness"
        ; type_ = Int
        }
    ; Attribute
        { name = "paintOrder"
        ; jsxName = "paintOrder"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "panose1"
        ; jsxName = "panose1"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "path"; jsxName = "path"; type_ = String }
    ; Attribute
        { name = "pathLength"
        ; jsxName = "pathLength"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "patternContentUnits"
        ; jsxName = "patternContentUnits"
        ; type_ = String
        }
    ; Attribute
        { name = "patternUnits"; jsxName = "patternUnits"; type_ = String }
    ; Attribute { name = "points"; jsxName = "points"; type_ = String }
    ; Attribute
        { name = "pointsAtX"
        ; jsxName = "pointsAtX"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "pointsAtY"
        ; jsxName = "pointsAtY"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "pointsAtZ"
        ; jsxName = "pointsAtZ"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "preserveAspectRatio"
        ; jsxName = "preserveAspectRatio"
        ; type_ = String
        }
    ; Attribute { name = "r"; jsxName = "r"; type_ = String (* number |  *) }
    ; Attribute
        { name = "radius"; jsxName = "radius"; type_ = String (* number |  *) }
    ; Attribute
        { name = "refX"; jsxName = "refX"; type_ = String (* number |  *) }
    ; Attribute
        { name = "refY"; jsxName = "refY"; type_ = String (* number |  *) }
    ; Attribute
        { name = "rotate"; jsxName = "rotate"; type_ = String (* number |  *) }
    ; Attribute { name = "rx"; jsxName = "rx"; type_ = String (* number |  *) }
    ; Attribute { name = "ry"; jsxName = "ry"; type_ = String (* number |  *) }
    ; Attribute
        { name = "scale"; jsxName = "scale"; type_ = String (* number |  *) }
    ; Attribute
        { name = "seed"; jsxName = "seed"; type_ = String (* number |  *) }
    ; Attribute
        { name = "spacing"
        ; jsxName = "spacing"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "speed"; jsxName = "speed"; type_ = String (* number |  *) }
    ; Attribute
        { name = "spreadMethod"; jsxName = "spreadMethod"; type_ = String }
    ; Attribute
        { name = "startOffset"
        ; jsxName = "startOffset"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "stdDeviation"
        ; jsxName = "stdDeviation"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "stemh"; jsxName = "stemh"; type_ = String (* number |  *) }
    ; Attribute
        { name = "stemv"; jsxName = "stemv"; type_ = String (* number |  *) }
    ; Attribute
        { name = "stitchTiles"
        ; jsxName = "stitchTiles"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "strikethroughPosition"
        ; jsxName = "strikethroughPosition"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "strikethroughThickness"
        ; jsxName = "strikethroughThickness"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "strokeWidth"
        ; jsxName = "strokeWidth"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "surfaceScale"
        ; jsxName = "surfaceScale"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "targetX"
        ; jsxName = "targetX"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "targetY"
        ; jsxName = "targetY"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "textLength"
        ; jsxName = "textLength"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "u1"; jsxName = "u1"; type_ = String (* number |  *) }
    ; Attribute { name = "u2"; jsxName = "u2"; type_ = String (* number |  *) }
    ; Attribute
        { name = "unicode"
        ; jsxName = "unicode"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "unicodeRange"
        ; jsxName = "unicodeRange"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "unitsPerEm"
        ; jsxName = "unitsPerEm"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vAlphabetic"
        ; jsxName = "vAlphabetic"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "version"; jsxName = "version"; type_ = String }
    ; Attribute
        { name = "vertAdvY"
        ; jsxName = "vertAdvY"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vertOriginX"
        ; jsxName = "vertOriginX"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vertOriginY"
        ; jsxName = "vertOriginY"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vHanging"
        ; jsxName = "vHanging"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "vIdeographic"
        ; jsxName = "vIdeographic"
        ; type_ = String (* number |  *)
        }
    ; Attribute { name = "viewBox"; jsxName = "viewBox"; type_ = String }
    ; Attribute
        { name = "viewTarget"
        ; jsxName = "viewTarget"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "visibility"
        ; jsxName = "visibility"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "widths"; jsxName = "widths"; type_ = String (* number |  *) }
    ; Attribute { name = "x1"; jsxName = "x1"; type_ = String (* number |  *) }
    ; Attribute { name = "x2"; jsxName = "x2"; type_ = String (* number |  *) }
    ; Attribute
        { name = "xChannelSelector"
        ; jsxName = "xChannelSelector"
        ; type_ = String
        }
    ; Attribute
        { name = "xHeight"
        ; jsxName = "xHeight"
        ; type_ = String (* number |  *)
        }
    ; Attribute
        { name = "xlinkActuate"; jsxName = "xlinkActuate"; type_ = String }
    ; Attribute
        { name = "xlinkArcrole"; jsxName = "xlinkArcrole"; type_ = String }
    ; Attribute { name = "xlinkHref"; jsxName = "xlinkHref"; type_ = String }
    ; Attribute { name = "xlinkRole"; jsxName = "xlinkRole"; type_ = String }
    ; Attribute { name = "xlinkShow"; jsxName = "xlinkShow"; type_ = String }
    ; Attribute { name = "xlinkTitle"; jsxName = "xlinkTitle"; type_ = String }
    ; Attribute { name = "xlinkType"; jsxName = "xlinkType"; type_ = String }
    ; Attribute { name = "xmlBase"; jsxName = "xmlBase"; type_ = String }
    ; Attribute { name = "xmlLang"; jsxName = "xmlLang"; type_ = String }
    ; Attribute { name = "xmlns"; jsxName = "xmlns"; type_ = String }
    ; Attribute { name = "xmlnsXlink"; jsxName = "xmlnsXlink"; type_ = String }
    ; Attribute { name = "xmlSpace"; jsxName = "xmlSpace"; type_ = String }
    ; Attribute { name = "y1"; jsxName = "y1"; type_ = String (* number |  *) }
    ; Attribute { name = "y2"; jsxName = "y2"; type_ = String (* number |  *) }
    ; Attribute
        { name = "yChannelSelector"
        ; jsxName = "yChannelSelector"
        ; type_ = String
        }
    ; Attribute { name = "z"; jsxName = "z"; type_ = String (* number |  *) }
    ; Attribute { name = "zoomAndPan"; jsxName = "zoomAndPan"; type_ = String }
    ]

  let attributes =
    htmlAttributes & filtersAttributes & presentationAttributes
    & stylingAttributes & coreAttributes
end

let webViewHTMLAttributes =
  [ Attribute
      { name = "allowFullScreen"; jsxName = "allowfullcreen"; type_ = Bool }
  ; Attribute { name = "allowPopups"; jsxName = "allowPopups"; type_ = Bool }
  ; Attribute { name = "autoFocus"; jsxName = "autoFocus"; type_ = Bool }
  ; Attribute { name = "autoSize"; jsxName = "autoSize"; type_ = Bool }
  ; Attribute
      { name = "blinkFeatures"; jsxName = "blinkFeatures"; type_ = String }
  ; Attribute
      { name = "disableBlinkFeatures"
      ; jsxName = "disableBlinkFeatures"
      ; type_ = String
      }
  ; Attribute
      { name = "disableGuestResize"
      ; jsxName = "disableGuestResize"
      ; type_ = Bool
      }
  ; Attribute
      { name = "disableWebSecurity"
      ; jsxName = "disableWebSecurity"
      ; type_ = Bool
      }
  ; Attribute
      { name = "guestInstance"; jsxName = "guestInstance"; type_ = String }
  ; Attribute
      { name = "httpReferrer"; jsxName = "httpReferrer"; type_ = String }
  ; Attribute
      { name = "nodeIntegration"; jsxName = "nodeIntegration"; type_ = Bool }
  ; Attribute { name = "partition"; jsxName = "partition"; type_ = String }
  ; Attribute { name = "plugins"; jsxName = "plugins"; type_ = Bool }
  ; Attribute { name = "preload"; jsxName = "preload"; type_ = String }
  ; Attribute { name = "src"; jsxName = "src"; type_ = String }
  ; Attribute { name = "userAgent"; jsxName = "userAgent"; type_ = String }
  ; Attribute
      { name = "webPreferences"; jsxName = "webPreferences"; type_ = String }
  ]

let commonHtmlAttributes =
  elementAttributes & reactAttributes & globalAttributes & globalEventHandlers

let htmlElements =
  [ { tag = "a"; attributes = commonHtmlAttributes & anchorHTMLAttributes }
  ; { tag = "abbr"; attributes = commonHtmlAttributes }
  ; { tag = "address"; attributes = commonHtmlAttributes }
  ; { tag = "area"; attributes = commonHtmlAttributes & areaHTMLAttributes }
  ; { tag = "article"; attributes = commonHtmlAttributes }
  ; { tag = "aside"; attributes = commonHtmlAttributes }
  ; { tag = "audio"; attributes = commonHtmlAttributes & mediaHTMLAttributes }
  ; { tag = "b"; attributes = commonHtmlAttributes }
  ; { tag = "base"; attributes = commonHtmlAttributes & baseHTMLAttributes }
  ; { tag = "bdi"; attributes = commonHtmlAttributes }
  ; { tag = "bdo"; attributes = commonHtmlAttributes }
  ; { tag = "big"; attributes = commonHtmlAttributes }
  ; { tag = "blockquote"
    ; attributes = commonHtmlAttributes & blockquoteHTMLAttributes
    }
  ; { tag = "body"; attributes = commonHtmlAttributes }
  ; { tag = "br"; attributes = commonHtmlAttributes }
  ; { tag = "button"; attributes = commonHtmlAttributes & buttonHTMLAttributes }
  ; { tag = "canvas"; attributes = commonHtmlAttributes & canvasHTMLAttributes }
  ; { tag = "caption"; attributes = commonHtmlAttributes }
  ; { tag = "cite"; attributes = commonHtmlAttributes }
  ; { tag = "code"; attributes = commonHtmlAttributes }
  ; { tag = "col"; attributes = commonHtmlAttributes & colHTMLAttributes }
  ; { tag = "colgroup"
    ; attributes = commonHtmlAttributes & colgroupHTMLAttributes
    }
  ; { tag = "data"; attributes = commonHtmlAttributes & dataHTMLAttributes }
  ; { tag = "datalist"; attributes = commonHtmlAttributes }
  ; { tag = "dd"; attributes = commonHtmlAttributes }
  ; { tag = "del"; attributes = commonHtmlAttributes & delHTMLAttributes }
  ; { tag = "details"
    ; attributes = commonHtmlAttributes & detailsHTMLAttributes
    }
  ; { tag = "dfn"; attributes = commonHtmlAttributes }
  ; { tag = "dialog"; attributes = commonHtmlAttributes & dialogHTMLAttributes }
  ; { tag = "div"; attributes = commonHtmlAttributes }
  ; { tag = "dl"; attributes = commonHtmlAttributes }
  ; { tag = "dt"; attributes = commonHtmlAttributes }
  ; { tag = "em"; attributes = commonHtmlAttributes }
  ; { tag = "embed"; attributes = commonHtmlAttributes & embedHTMLAttributes }
  ; { tag = "fieldset"
    ; attributes = commonHtmlAttributes & fieldsetHTMLAttributes
    }
  ; { tag = "figcaption"; attributes = commonHtmlAttributes }
  ; { tag = "figure"; attributes = commonHtmlAttributes }
  ; { tag = "footer"; attributes = commonHtmlAttributes }
  ; { tag = "form"; attributes = commonHtmlAttributes & formHTMLAttributes }
  ; { tag = "h1"; attributes = commonHtmlAttributes }
  ; { tag = "h2"; attributes = commonHtmlAttributes }
  ; { tag = "h3"; attributes = commonHtmlAttributes }
  ; { tag = "h4"; attributes = commonHtmlAttributes }
  ; { tag = "h5"; attributes = commonHtmlAttributes }
  ; { tag = "h6"; attributes = commonHtmlAttributes }
  ; { tag = "head"; attributes = commonHtmlAttributes }
  ; { tag = "header"; attributes = commonHtmlAttributes }
  ; { tag = "hgroup"; attributes = commonHtmlAttributes }
  ; { tag = "hr"; attributes = commonHtmlAttributes }
  ; { tag = "html"; attributes = commonHtmlAttributes & htmlHTMLAttributes }
  ; { tag = "i"; attributes = commonHtmlAttributes }
  ; { tag = "iframe"; attributes = commonHtmlAttributes & iframeHTMLAttributes }
  ; { tag = "img"; attributes = commonHtmlAttributes & imgHTMLAttributes }
  ; { tag = "input"; attributes = commonHtmlAttributes & inputHTMLAttributes }
  ; { tag = "ins"; attributes = commonHtmlAttributes & insHTMLAttributes }
  ; { tag = "kbd"; attributes = commonHtmlAttributes }
  ; { tag = "keygen"; attributes = commonHtmlAttributes & keygenHTMLAttributes }
  ; { tag = "label"; attributes = commonHtmlAttributes & labelHTMLAttributes }
  ; { tag = "legend"; attributes = commonHtmlAttributes }
  ; { tag = "li"; attributes = commonHtmlAttributes & liHTMLAttributes }
  ; { tag = "link"; attributes = commonHtmlAttributes & linkHTMLAttributes }
  ; { tag = "main"; attributes = commonHtmlAttributes }
  ; { tag = "map"; attributes = commonHtmlAttributes & mapHTMLAttributes }
  ; { tag = "mark"; attributes = commonHtmlAttributes }
  ; { tag = "menu"; attributes = commonHtmlAttributes & menuHTMLAttributes }
  ; { tag = "menuitem"; attributes = commonHtmlAttributes }
  ; { tag = "meta"; attributes = commonHtmlAttributes & metaHTMLAttributes }
  ; { tag = "meter"; attributes = commonHtmlAttributes & meterHTMLAttributes }
  ; { tag = "nav"; attributes = commonHtmlAttributes }
  ; { tag = "noindex"; attributes = commonHtmlAttributes }
  ; { tag = "noscript"; attributes = commonHtmlAttributes }
  ; { tag = "object"; attributes = commonHtmlAttributes & objectHTMLAttributes }
  ; { tag = "ol"; attributes = commonHtmlAttributes & olHTMLAttributes }
  ; { tag = "optgroup"
    ; attributes = commonHtmlAttributes & optgroupHTMLAttributes
    }
  ; { tag = "option"; attributes = commonHtmlAttributes & optionHTMLAttributes }
  ; { tag = "output"; attributes = commonHtmlAttributes & outputHTMLAttributes }
  ; { tag = "p"; attributes = commonHtmlAttributes }
  ; { tag = "param"; attributes = commonHtmlAttributes & paramHTMLAttributes }
  ; { tag = "picture"; attributes = commonHtmlAttributes }
  ; { tag = "pre"; attributes = commonHtmlAttributes }
  ; { tag = "progress"
    ; attributes = commonHtmlAttributes & progressHTMLAttributes
    }
  ; { tag = "q"; attributes = commonHtmlAttributes & quoteHTMLAttributes }
  ; { tag = "rp"; attributes = commonHtmlAttributes }
  ; { tag = "rt"; attributes = commonHtmlAttributes }
  ; { tag = "ruby"; attributes = commonHtmlAttributes }
  ; { tag = "s"; attributes = commonHtmlAttributes }
  ; { tag = "samp"; attributes = commonHtmlAttributes }
  ; { tag = "script"; attributes = commonHtmlAttributes & scriptHTMLAttributes }
  ; { tag = "section"; attributes = commonHtmlAttributes }
  ; { tag = "select"; attributes = commonHtmlAttributes & selectHTMLAttributes }
  ; { tag = "slot"; attributes = commonHtmlAttributes & slotHTMLAttributes }
  ; { tag = "small"; attributes = commonHtmlAttributes }
  ; { tag = "source"; attributes = commonHtmlAttributes & sourceHTMLAttributes }
  ; { tag = "span"; attributes = commonHtmlAttributes }
  ; { tag = "strong"; attributes = commonHtmlAttributes }
  ; { tag = "style"; attributes = commonHtmlAttributes & styleHTMLAttributes }
  ; { tag = "sub"; attributes = commonHtmlAttributes }
  ; { tag = "summary"; attributes = commonHtmlAttributes }
  ; { tag = "sup"; attributes = commonHtmlAttributes }
  ; { tag = "table"; attributes = commonHtmlAttributes & tableHTMLAttributes }
  ; { tag = "tbody"; attributes = commonHtmlAttributes }
  ; { tag = "td"; attributes = commonHtmlAttributes & tdHTMLAttributes }
  ; { tag = "template"; attributes = commonHtmlAttributes }
  ; { tag = "textarea"
    ; attributes = commonHtmlAttributes & textareaHTMLAttributes
    }
  ; { tag = "tfoot"; attributes = commonHtmlAttributes }
  ; { tag = "th"; attributes = commonHtmlAttributes & thHTMLAttributes }
  ; { tag = "thead"; attributes = commonHtmlAttributes }
  ; { tag = "time"; attributes = commonHtmlAttributes & timeHTMLAttributes }
  ; { tag = "title"; attributes = commonHtmlAttributes }
  ; { tag = "tr"; attributes = commonHtmlAttributes }
  ; { tag = "track"; attributes = commonHtmlAttributes & trackHTMLAttributes }
  ; { tag = "u"; attributes = commonHtmlAttributes }
  ; { tag = "ul"; attributes = commonHtmlAttributes }
  ; { tag = "var"; attributes = commonHtmlAttributes }
  ; { tag = "video"; attributes = commonHtmlAttributes & videoHTMLAttributes }
  ; { tag = "wbr"; attributes = commonHtmlAttributes }
  ; { tag = "webview"
    ; attributes = commonHtmlAttributes & webViewHTMLAttributes
    }
  ]

let commonSvgAttributes =
  SVG.attributes & reactAttributes & globalEventHandlers & ariaAttributes

let svgElements =
  [ { tag = "svg"; attributes = commonSvgAttributes }
  ; { tag = "animate"; attributes = commonSvgAttributes }
  ; { tag = "animateMotion"; attributes = commonSvgAttributes }
  ; { tag = "animateTransform"; attributes = commonSvgAttributes }
  ; { tag = "circle"; attributes = commonSvgAttributes }
  ; { tag = "clipPath"; attributes = commonSvgAttributes }
  ; { tag = "defs"; attributes = commonSvgAttributes }
  ; { tag = "desc"; attributes = commonSvgAttributes }
  ; { tag = "ellipse"; attributes = commonSvgAttributes }
  ; { tag = "feBlend"; attributes = commonSvgAttributes }
  ; { tag = "feColorMatrix"; attributes = commonSvgAttributes }
  ; { tag = "feComponentTransfer"; attributes = commonSvgAttributes }
  ; { tag = "feComposite"; attributes = commonSvgAttributes }
  ; { tag = "feConvolveMatrix"; attributes = commonSvgAttributes }
  ; { tag = "feDiffuseLighting"; attributes = commonSvgAttributes }
  ; { tag = "feDisplacementMap"; attributes = commonSvgAttributes }
  ; { tag = "feDistantLight"; attributes = commonSvgAttributes }
  ; { tag = "feDropShadow"; attributes = commonSvgAttributes }
  ; { tag = "feFlood"; attributes = commonSvgAttributes }
  ; { tag = "feFuncA"; attributes = commonSvgAttributes }
  ; { tag = "feFuncB"; attributes = commonSvgAttributes }
  ; { tag = "feFuncG"; attributes = commonSvgAttributes }
  ; { tag = "feFuncR"; attributes = commonSvgAttributes }
  ; { tag = "feGaussianBlur"; attributes = commonSvgAttributes }
  ; { tag = "feImage"; attributes = commonSvgAttributes }
  ; { tag = "feMerge"; attributes = commonSvgAttributes }
  ; { tag = "feMergeNode"; attributes = commonSvgAttributes }
  ; { tag = "feMorphology"; attributes = commonSvgAttributes }
  ; { tag = "feOffset"; attributes = commonSvgAttributes }
  ; { tag = "fePointLight"; attributes = commonSvgAttributes }
  ; { tag = "feSpecularLighting"; attributes = commonSvgAttributes }
  ; { tag = "feSpotLight"; attributes = commonSvgAttributes }
  ; { tag = "feTile"; attributes = commonSvgAttributes }
  ; { tag = "feTurbulence"; attributes = commonSvgAttributes }
  ; { tag = "filter"; attributes = commonSvgAttributes }
  ; { tag = "foreignObject"; attributes = commonSvgAttributes }
  ; { tag = "g"; attributes = commonSvgAttributes }
  ; { tag = "image"; attributes = commonSvgAttributes }
  ; { tag = "line"; attributes = commonSvgAttributes }
  ; { tag = "linearGradient"; attributes = commonSvgAttributes }
  ; { tag = "marker"; attributes = commonSvgAttributes }
  ; { tag = "mask"; attributes = commonSvgAttributes }
  ; { tag = "metadata"; attributes = commonSvgAttributes }
  ; { tag = "mpath"; attributes = commonSvgAttributes }
  ; { tag = "path"; attributes = commonSvgAttributes }
  ; { tag = "pattern"; attributes = commonSvgAttributes }
  ; { tag = "polygon"; attributes = commonSvgAttributes }
  ; { tag = "polyline"; attributes = commonSvgAttributes }
  ; { tag = "radialGradient"; attributes = commonSvgAttributes }
  ; { tag = "rect"; attributes = commonSvgAttributes }
  ; { tag = "stop"; attributes = commonSvgAttributes }
  ; { tag = "switch"; attributes = commonSvgAttributes }
  ; { tag = "symbol"; attributes = commonSvgAttributes }
  ; { tag = "text"; attributes = commonSvgAttributes }
  ; { tag = "textPath"; attributes = commonSvgAttributes }
  ; { tag = "tspan"; attributes = commonSvgAttributes }
  ; { tag = "use"; attributes = commonSvgAttributes }
  ; { tag = "view"; attributes = commonSvgAttributes }
  ]

let elements = svgElements & htmlElements

let getName = function
  | Attribute { name; _ } -> name
  | Event { name; _ } -> name

let getJSXName = function
  | Attribute { jsxName; _ } -> jsxName
  | Event { name; _ } -> name

type errors =
  [ `ElementNotFound
  | `AttributeNotFound
  ]

let getAttributes tag =
  List.find_opt (fun element -> element.tag = tag) elements
  |> Option.to_result ~none:`ElementNotFound

let findByName tag name =
  let byName p = getName p = name in
  match getAttributes tag with
  | Ok { attributes } ->
      List.find_opt byName attributes
      |> Option.to_result ~none:`AttributeNotFound
  | Error err -> Error err
