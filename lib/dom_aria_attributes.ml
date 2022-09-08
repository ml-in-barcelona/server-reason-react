include Dom_dsl_core.Prop

(* All the WAI-ARIA 1.1 attributes from https://www.w3.org/TR/wai-aria-1.1/ *)

(* Identifies the currently active element when DOM focus is on a composite widget, textbox, group, or application. *)
let ariaActivedescendant = string "aria-activedescendant"

(* Indicates whether assistive technologies will present all, or only parts of, the changed region based on the change notifications defined by the aria-relevant attribute. *)
let ariaAtomic = string (* Bool | 'false' | 'true' *) "aria-atomic"

(* Indicates whether inputting text could trigger display of one or more predictions of the user's intended value for an input and specifies how predictions would be
 * presented if they are made.
 *)
let ariaAutocomplete =
  string (* 'none' | 'inline' | 'list' | 'both' *) "aria-autocomplete"

(* Indicates an element is being modified and that assistive technologies MAY want to wait until the modifications are complete before exposing them to the user. *)
let ariaBusy = string (* Bool | 'false' | 'true' *) "aria-busy"

(* Indicates the current "checked" state of checkboxes, radio buttons, and other widgets.
 * @see aria-pressed @see aria-selected.
 *)
let ariaChecked = string (* Bool | 'false' | 'mixed' | 'true' *) "aria-checked"

(* Defines the total number of columns in a table, grid, or treegrid.
 * @see aria-colindex.
 *)
let ariaColcount = int "aria-colcount"

(* Defines an element's column index or position with respect to the total number of columns within a table, grid, or treegrid.
 * @see aria-colcount @see aria-colspan.
 *)
let ariaColindex = int "aria-colindex"

(* Defines the number of columns spanned by a cell or gridcell within a table, grid, or treegrid.
 * @see aria-colindex @see aria-rowspan.
 *)
let ariaColspan = int "aria-colspan"

(* Identifies the element (or elements) whose contents or presence are controlled by the current element.
 * @see aria-owns.
 *)
let ariaControls = string "aria-controls"

(* Indicates the element that represents the current item within a container or set of related elements. *)
let ariaCurrent = string "aria-current"

(* Bool | 'false' | 'true' |  'page' | 'step' | 'location' | 'date' | 'time' *)
(* Identifies the element (or elements) that describes the object.
 * @see aria-labelledby
 *)
let ariaDescribedby = string "aria-describedby"

(* Identifies the element that provides a detailed, extended description for the object.
 * @see aria-describedby.
 *)
let ariaDetails = string "aria-details"

(* Indicates that the element is perceivable but disabled, so it is not editable or otherwise operable.
 * @see aria-hidden @see aria-readonly.
 *)
let ariaDisabled = string (* Bool | 'false' | 'true' *) "aria-disabled"

(* Indicates what functions can be performed when a dragged object is released on the drop target.
 * @deprecated in ARIA 1.1
 *)
let ariaDropeffect = string "aria-dropeffect"

(* 'none' | 'copy' | 'execute' | 'link' | 'move' | 'popup' *)
(* Identifies the element that provides an error message for the object.
 * @see aria-invalid @see aria-describedby.
 *)
let ariaErrormessage = string "aria-errormessage"

(* Indicates whether the element, or another grouping element it controls, is currently expanded or collapsed. *)
let ariaExpanded = string (* Bool | 'false' | 'true' *) "aria-expanded"

(* Identifies the next element (or elements) in an alternate reading order of content which, at the user's discretion,
 * allows assistive technology to override the general default of reading in document source order.
 *)
let ariaFlowto = string "aria-flowto"

(* Indicates an element's "grabbed" state in a drag-and-drop operation.
 * @deprecated in ARIA 1.1
 *)
let ariaGrabbed = string (* Bool | 'false' | 'true' *) "aria-grabbed"

(* Indicates the availability and type of interactive popup element, such as menu or dialog, that can be triggered by an element. *)
let ariaHaspopup =
  string
    (* Bool | 'false' | 'true' | 'menu' | 'listbox' | 'tree' | 'grid' | 'dialog'; *)
    "aria-haspopup"

(* Indicates whether the element is exposed to an accessibility API.
 * @see aria-disabled.
 *)
let ariaHidden = string (* Bool | 'false' | 'true' *) "aria-hidden"

(* Indicates the entered value does not conform to the format expected by the application.
 * @see aria-errormessage.
 *)
let ariaInvalid =
  string (* Bool | 'false' | 'true' |  'grammar' | 'spelling'; *) "aria-invalid"

(* Indicates keyboard shortcuts that an author has implemented to activate or give focus to an element. *)
let ariaKeyshortcuts = string "aria-keyshortcuts"

(* Defines a String value that labels the current element.
 * @see aria-labelledby.
 *)
let ariaLabel = string "aria-label"

(* Identifies the element (or elements) that labels the current element.
 * @see aria-describedby.
 *)
let ariaLabelledby = string "aria-labelledby"

(* Defines the hierarchical level of an element within a structure. *)
let ariaLevel = int "aria-level"

(* Indicates that an element will be updated, and describes the types of updates the user agents, assistive technologies, and user can expect ;rom the live region. *)
let ariaLive = string (* 'off' | 'assertive' | 'polite' *) "aria-live"

(* Indicates whether an element is modal when displayed. *)
let ariaModal = string (* Bool | 'false' | 'true' *) "aria-modal"

(* Indicates whether a text box accepts multiple lines of input or only a single line. *)
let ariaMultiline = string (* Bool | 'false' | 'true' *) "aria-multiline"

(* Indicates that the user may select more than one item from the current selectable descendants. *)
let ariaMultiselectable =
  string (* Bool |  'false' | 'true' *) "aria-multiselectable"

(* Indicates whether the element's orientation is horizontal, vertical, or unknown/ambiguous. *)
let ariaOrientation = string (* 'horizontal' | 'vertical' *) "aria-orientation"

(* Identifies an element (or elements) in order to define a visual, functional, or contextual parent/child relationship
 * between DOM elements where the DOM hierarchy cannot be used to represent the relationship.
 * @see aria-controls.
 *)
let ariaOwns = string "aria-owns"

(* Defines a short hint (a word or short phrase) intended to aid the user with data entry when the control has no value.
   * A hint could be a sample value or a brief description of the expected format.
*)
let ariaPlaceholder = string "aria-placeholder"

(* Defines an element's number or position in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
 * @see aria-setsize.
 *)
let ariaPosinset = int "aria-posinset"

(* Indicates the current "pressed" state of toggle buttons.
 * @see aria-checked @see aria-selected.
 *)
let ariaPressed = string (* Bool | 'false' | 'mixed' | 'true' *) "aria-pressed"

(* Indicates that the element is not editable, but is otherwise operable.
 * @see aria-disabled.
 *)
let ariaReadonly = string (* Bool | 'false' | 'true' *) "aria-readonly"

(* Indicates what notifications the user agent will trigger when the accessibility tree within a live region is modified.
 * @see aria-atomic.
 *)
let ariaRelevant =
  string
    (* 'additions' | 'additions removals' | 'additions text' | 'all' | 'removals' | 'removals additions' | 'removals text' | 'text' | 'text additions' | 'text removals' *)
    "aria-relevant"

(* Indicates that user input is required on the element before a form may be submitted. *)
let ariaRequired = string (* Bool | 'false' | 'true' *) "aria-required"

(* Defines a human-readable, author-localized description for the role of an element. *)
let ariaRoledescription = string "aria-roledescription"

(* Defines the total number of rows in a table, grid, or treegrid.
 * @see aria-rowindex.
 *)
let ariaRowcount = int "aria-rowcount"

(* Defines an element's row index or position with respect to the total number of rows within a table, grid, or treegrid.
 * @see aria-rowcount @see aria-rowspan.
 *)
let ariaRowindex = int "aria-rowindex"

(* Defines the number of rows spanned by a cell or gridcell within a table, grid, or treegrid.
 * @see aria-rowindex @see aria-colspan.
 *)
let ariaRowspan = int "aria-rowspan"

(* Indicates the current "selected" state of various widgets.
 * @see aria-checked @see aria-pressed.
 *)
let ariaSelected = string (* Bool | 'false' | 'true' *) "aria-selected"

(* Defines the number of items in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
 * @see aria-posinset.
 *)
let ariaSetsize = int "aria-setsize"

(* Indicates if items in a table or grid are sorted in ascending or descending order. *)
let ariaSort =
  string (* 'none' | 'ascending' | 'descending' | 'other' *) "aria-sort"

(* Defines the maximum allowed value for a range widget. *)
let ariaValuemax = int "aria-valuemax"

(* Defines the minimum allowed value for a range widget. *)
let ariaValuemin = int "aria-valuemin"

(* Defines the current value for a range widget.
 * @see aria-valuetext.
 *)
let ariaValuenow = int "aria-valuenow"

(* Defines the human readable text alternative of aria-valuenow for a range widget. *)
let ariaValuetext = string "aria-valuetext"
