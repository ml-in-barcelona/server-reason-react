[@@@js.stop]

type dom_element = Js_of_ocaml.Dom_html.element Js_of_ocaml.Js.t

val dom_element_to_js : dom_element -> Ojs.t
val dom_element_of_js : Ojs.t -> dom_element

[@@@js.start]

[@@@js.implem
type dom_element = Js_of_ocaml.Dom_html.element Js_of_ocaml.Js.t

external dom_element_to_js : dom_element -> Ojs.t = "%identity"
external dom_element_of_js : Ojs.t -> dom_element = "%identity"]

val unmount_component_at_node : dom_element -> bool
  [@@js.custom
    val unmount_component_at_node_internal :
      Imports.react_dom -> dom_element -> bool
      [@@js.call "unmountComponentAtNode"]

    let unmount_component_at_node dom_element =
      unmount_component_at_node_internal Imports.react_dom dom_element]

val render : Core.element -> dom_element -> unit
  [@@js.custom
    val render_internal :
      Imports.react_dom -> Core.element -> dom_element -> unit
      [@@js.call "render"]

    let render element dom_element =
      render_internal Imports.react_dom element dom_element]

val render_to_element : id:string -> Core.element -> unit
  [@@js.custom
    val get_element_by_id : string -> dom_element option
      [@@js.global "document.getElementById"]

    let render_to_element ~id react_element =
      match get_element_by_id id with
      | None ->
          raise
            (Invalid_argument
               ("ReactDOM.render_to_element : no element of id " ^ id
              ^ " found in the HTML."))
      | Some element -> render react_element element]

val create_portal : Core.element -> dom_element -> Core.element
  [@@js.custom
    val create_portal_internal :
      Imports.react_dom -> Core.element -> dom_element -> Core.element
      [@@js.call "createPortal"]

    let create_portal element dom_element =
      create_portal_internal Imports.react_dom element dom_element]

type dom_ref = private Ojs.t

module Ref : sig
  type t = dom_ref
  type current_dom_ref = dom_element Core.js_nullable Core.Ref.t
  type callback_dom_ref = dom_element Core.js_nullable -> unit

  [@@@js.stop]

  val dom_ref : current_dom_ref -> dom_ref
  val callback_dom_ref : callback_dom_ref -> dom_ref

  [@@@js.start]

  [@@@js.implem
  external dom_ref : current_dom_ref -> dom_ref = "%identity"
  external callback_dom_ref : callback_dom_ref -> dom_ref = "%identity"]
end

type domProps = private Ojs.t

val create_element :
     string
  -> props:
       domProps
       (* props has to be non-optional as otherwise gen_js_api will put an empty list and React will break *)
  -> Core.element list
  -> Core.element
  [@@js.custom
    val create_element_internal :
         Imports.react
      -> string
      -> props:domProps
      -> (Core.element list[@js.variadic])
      -> Core.element
      [@@js.call "createElement"]

    let create_element typ ~props elts =
      create_element_internal Imports.react typ ~props elts]

val forward_ref : ('props -> dom_ref -> Core.element) -> 'props Core.component
  [@@js.custom
    val forward_ref_internal :
         Imports.react
      -> ('props -> dom_ref -> Core.element)
      -> 'props Core.component
      [@@js.call "forwardRef"]

    let forward_ref renderFunc = forward_ref_internal Imports.react renderFunc]

type block

module Style : sig
  [@@@js.stop]

  type decl
  type t = block

  val make : decl array -> block
  val azimuth : string -> decl
  val background : string -> decl
  val background_attachment : string -> decl
  val background_color : string -> decl
  val background_image : string -> decl
  val background_position : string -> decl
  val background_repeat : string -> decl
  val border : string -> decl
  val border_collapse : string -> decl
  val border_color : string -> decl
  val border_spacing : string -> decl
  val border_style : string -> decl
  val border_top : string -> decl
  val border_right : string -> decl
  val border_bottom : string -> decl
  val border_left : string -> decl
  val border_top_color : string -> decl
  val border_right_color : string -> decl
  val border_bottom_color : string -> decl
  val border_left_color : string -> decl
  val border_top_style : string -> decl
  val border_right_style : string -> decl
  val border_bottom_style : string -> decl
  val border_left_style : string -> decl
  val border_top_width : string -> decl
  val border_right_width : string -> decl
  val border_bottom_width : string -> decl
  val border_left_width : string -> decl
  val border_width : string -> decl
  val bottom : string -> decl
  val caption_side : string -> decl
  val clear : string -> decl
  val color : string -> decl
  val content : string -> decl
  val counter_increment : string -> decl
  val counter_reset : string -> decl
  val cue : string -> decl
  val cue_after : string -> decl
  val cue_before : string -> decl
  val direction : string -> decl
  val display : string -> decl
  val elevation : string -> decl
  val empty_cells : string -> decl
  val float : string -> decl
  val font : string -> decl
  val font_family : string -> decl
  val font_size : string -> decl
  val font_size_adjust : string -> decl
  val font_stretch : string -> decl
  val font_style : string -> decl
  val font_variant : string -> decl
  val font_weight : string -> decl
  val height : string -> decl
  val left : string -> decl
  val letter_spacing : string -> decl
  val line_height : string -> decl
  val list_style : string -> decl
  val list_style_image : string -> decl
  val list_style_position : string -> decl
  val list_style_type : string -> decl
  val margin : string -> decl
  val margin_top : string -> decl
  val margin_right : string -> decl
  val margin_bottom : string -> decl
  val margin_left : string -> decl
  val marker_offset : string -> decl
  val marks : string -> decl
  val max_height : string -> decl
  val max_width : string -> decl
  val min_height : string -> decl
  val min_width : string -> decl
  val orphans : string -> decl
  val outline : string -> decl
  val outline_color : string -> decl
  val outline_style : string -> decl
  val outline_width : string -> decl
  val overflow : string -> decl
  val overflow_x : string -> decl
  val overflow_y : string -> decl
  val padding : string -> decl
  val padding_top : string -> decl
  val padding_right : string -> decl
  val padding_bottom : string -> decl
  val padding_left : string -> decl
  val page : string -> decl
  val page_break_after : string -> decl
  val page_break_before : string -> decl
  val page_break_inside : string -> decl
  val pause : string -> decl
  val pause_after : string -> decl
  val pause_before : string -> decl
  val pitch : string -> decl
  val pitch_range : string -> decl
  val play_during : string -> decl
  val position : string -> decl
  val quotes : string -> decl
  val richness : string -> decl
  val right : string -> decl
  val size : string -> decl
  val speak : string -> decl
  val speak_header : string -> decl
  val speak_numeral : string -> decl
  val speak_punctuation : string -> decl
  val speech_rate : string -> decl
  val stress : string -> decl
  val table_layout : string -> decl
  val text_align : string -> decl
  val text_decoration : string -> decl
  val text_indent : string -> decl
  val text_shadow : string -> decl
  val text_transform : string -> decl
  val top : string -> decl
  val unicode_bidi : string -> decl
  val vertical_align : string -> decl
  val visibility : string -> decl
  val voice_family : string -> decl
  val volume : string -> decl
  val white_space : string -> decl
  val widows : string -> decl
  val width : string -> decl
  val word_spacing : string -> decl
  val z_index : string -> decl
  val opacity : string -> decl
  val background_origin : string -> decl
  val background_size : string -> decl
  val background_clip : string -> decl
  val border_radius : string -> decl
  val border_top_left_radius : string -> decl
  val border_top_right_radius : string -> decl
  val border_bottom_left_radius : string -> decl
  val border_bottom_right_radius : string -> decl
  val border_image : string -> decl
  val border_image_source : string -> decl
  val border_image_slice : string -> decl
  val border_image_width : string -> decl
  val border_image_outset : string -> decl
  val border_image_repeat : string -> decl
  val box_shadow : string -> decl
  val columns : string -> decl
  val column_count : string -> decl
  val column_fill : string -> decl
  val column_gap : string -> decl
  val column_rule : string -> decl
  val column_rule_color : string -> decl
  val column_rule_style : string -> decl
  val column_rule_width : string -> decl
  val column_span : string -> decl
  val column_width : string -> decl
  val break_after : string -> decl
  val break_before : string -> decl
  val break_inside : string -> decl
  val rest : string -> decl
  val rest_after : string -> decl
  val rest_before : string -> decl
  val speak_as : string -> decl
  val voice_balance : string -> decl
  val voice_duration : string -> decl
  val voice_pitch : string -> decl
  val voice_range : string -> decl
  val voice_rate : string -> decl
  val voice_stress : string -> decl
  val voice_volume : string -> decl
  val object_fit : string -> decl
  val object_position : string -> decl
  val image_resolution : string -> decl
  val image_orientation : string -> decl
  val align_content : string -> decl
  val align_items : string -> decl
  val align_self : string -> decl
  val flex : string -> decl
  val flex_basis : string -> decl
  val flex_direction : string -> decl
  val flex_flow : string -> decl
  val flex_grow : string -> decl
  val flex_shrink : string -> decl
  val flex_wrap : string -> decl
  val justify_content : string -> decl
  val order : string -> decl
  val text_decoration_color : string -> decl
  val text_decoration_line : string -> decl
  val text_decoration_skip : string -> decl
  val text_decoration_style : string -> decl
  val text_emphasis : string -> decl
  val text_emphasis_color : string -> decl
  val text_emphasis_position : string -> decl
  val text_emphasis_style : string -> decl
  val text_underline_position : string -> decl
  val font_feature_settings : string -> decl
  val font_kerning : string -> decl
  val font_language_override : string -> decl
  val font_synthesis : string -> decl
  val fornt_variant_alternates : string -> decl
  val font_variant_caps : string -> decl
  val font_variant_east_asian : string -> decl
  val font_variant_ligatures : string -> decl
  val font_variant_numeric : string -> decl
  val font_variant_position : string -> decl
  val all : string -> decl
  val text_combine_upright : string -> decl
  val text_orientation : string -> decl
  val writing_mode : string -> decl
  val shape_image_threshold : string -> decl
  val shape_margin : string -> decl
  val shape_outside : string -> decl
  val mask : string -> decl
  val mask_border : string -> decl
  val mask_border_mode : string -> decl
  val mask_border_outset : string -> decl
  val mask_border_repeat : string -> decl
  val mask_border_slice : string -> decl
  val mask_border_source : string -> decl
  val mask_border_width : string -> decl
  val mask_clip : string -> decl
  val mask_composite : string -> decl
  val mask_image : string -> decl
  val mask_mode : string -> decl
  val mask_origin : string -> decl
  val mask_position : string -> decl
  val mask_repeat : string -> decl
  val mask_size : string -> decl
  val mask_type : string -> decl
  val background_blend_mode : string -> decl
  val isolation : string -> decl
  val mix_blend_mode : string -> decl
  val box_decoration_break : string -> decl
  val box_sizing : string -> decl
  val caret_color : string -> decl
  val nav_down : string -> decl
  val nav_left : string -> decl
  val nav_right : string -> decl
  val nav_up : string -> decl
  val outline_offset : string -> decl
  val resize : string -> decl
  val text_overflow : string -> decl
  val grid : string -> decl
  val grid_area : string -> decl
  val grid_auto_columns : string -> decl
  val grid_auto_flow : string -> decl
  val grid_auto_rows : string -> decl
  val grid_column : string -> decl
  val grid_column_end : string -> decl
  val grid_column_gap : string -> decl
  val grid_column_start : string -> decl
  val grid_gap : string -> decl
  val grid_row : string -> decl
  val grid_row_end : string -> decl
  val grid_row_gap : string -> decl
  val grid_row_start : string -> decl
  val grid_template : string -> decl
  val grid_template_areas : string -> decl
  val grid_template_columns : string -> decl
  val grid_template_rows : string -> decl
  val will_change : string -> decl
  val hanging_punctuation : string -> decl
  val hyphens : string -> decl
  val line_break : string -> decl
  val overflow_wrap : string -> decl
  val tab_size : string -> decl
  val text_align_last : string -> decl
  val text_justify : string -> decl
  val word_break : string -> decl
  val word_wrap : string -> decl
  val animation : string -> decl
  val animation_delay : string -> decl
  val animation_direction : string -> decl
  val animation_duration : string -> decl
  val animation_fill_mode : string -> decl
  val animation_iteration_count : string -> decl
  val animation_name : string -> decl
  val animation_play_state : string -> decl
  val animation_timing_function : string -> decl
  val transition : string -> decl
  val transition_delay : string -> decl
  val transition_duration : string -> decl
  val transition_property : string -> decl
  val transition_timing_function : string -> decl
  val backface_visibility : string -> decl
  val perspective : string -> decl
  val perspective_origin : string -> decl
  val transform : string -> decl
  val transform_origin : string -> decl
  val transform_style : string -> decl
  val justify_items : string -> decl
  val justify_self : string -> decl
  val place_content : string -> decl
  val place_items : string -> decl
  val place_self : string -> decl
  val appearance : string -> decl
  val caret : string -> decl
  val caret_animation : string -> decl
  val caret_shape : string -> decl
  val user_select : string -> decl
  val max_lines : string -> decl
  val marquee_direction : string -> decl
  val marquee_loop : string -> decl
  val marquee_speed : string -> decl
  val marquee_style : string -> decl
  val overflow_style : string -> decl
  val rotation : string -> decl
  val rotation_point : string -> decl
  val alignment_baseline : string -> decl
  val baseline_shift : string -> decl
  val clip : string -> decl
  val clip_path : string -> decl
  val clip_rule : string -> decl
  val color_interpolation : string -> decl
  val color_interpolation_filters : string -> decl
  val color_profile : string -> decl
  val color_rendering : string -> decl
  val cursor : string -> decl
  val dominant_baseline : string -> decl
  val fill : string -> decl
  val fill_opacity : string -> decl
  val fill_rule : string -> decl
  val filter : string -> decl
  val flood_color : string -> decl
  val flood_opacity : string -> decl
  val glyph_orientation_horizontal : string -> decl
  val glyph_orientation_vertical : string -> decl
  val image_rendering : string -> decl
  val kerning : string -> decl
  val lighting_color : string -> decl
  val marker_end : string -> decl
  val marker_mid : string -> decl
  val marker_start : string -> decl
  val pointer_events : string -> decl
  val shape_rendering : string -> decl
  val stop_color : string -> decl
  val stop_opacity : string -> decl
  val stroke : string -> decl
  val stroke_dasharray : string -> decl
  val stroke_dashoffset : string -> decl
  val stroke_linecap : string -> decl
  val stroke_linejoin : string -> decl
  val stroke_miterlimit : string -> decl
  val stroke_opacity : string -> decl
  val stroke_width : string -> decl
  val text_anchor : string -> decl
  val text_rendering : string -> decl
  val ruby_align : string -> decl
  val ruby_merge : string -> decl
  val ruby_position : string -> decl

  [@@@js.start]

  [@@@js.implem
  type decl = string * Js_of_ocaml.Js.Unsafe.any
  type t = block

  let string_style_prop property value =
    (property, Js_of_ocaml.Js.Unsafe.inject (Js_of_ocaml.Js.string value))

  let make = Js_of_ocaml.Js.Unsafe.obj
  let azimuth = string_style_prop "azimuth"
  let background = string_style_prop "background"
  let background_attachment = string_style_prop "backgroundAttachment"
  let background_color = string_style_prop "backgroundColor"
  let background_image = string_style_prop "backgroundImage"
  let background_position = string_style_prop "backgroundPosition"
  let background_repeat = string_style_prop "backgroundRepeat"
  let border = string_style_prop "border"
  let border_collapse = string_style_prop "borderCollapse"
  let border_color = string_style_prop "borderColor"
  let border_spacing = string_style_prop "borderSpacing"
  let border_style = string_style_prop "borderStyle"
  let border_top = string_style_prop "borderTop"
  let border_right = string_style_prop "borderRight"
  let border_bottom = string_style_prop "borderBottom"
  let border_left = string_style_prop "borderLeft"
  let border_top_color = string_style_prop "borderTopColor"
  let border_right_color = string_style_prop "borderRightColor"
  let border_bottom_color = string_style_prop "borderBottomColor"
  let border_left_color = string_style_prop "borderLeftColor"
  let border_top_style = string_style_prop "borderTopStyle"
  let border_right_style = string_style_prop "borderRightStyle"
  let border_bottom_style = string_style_prop "borderBottomStyle"
  let border_left_style = string_style_prop "borderLeftStyle"
  let border_top_width = string_style_prop "borderTopWidth"
  let border_right_width = string_style_prop "borderRightWidth"
  let border_bottom_width = string_style_prop "borderBottomWidth"
  let border_left_width = string_style_prop "borderLeftWidth"
  let border_width = string_style_prop "borderWidth"
  let bottom = string_style_prop "bottom"
  let caption_side = string_style_prop "captionSide"
  let clear = string_style_prop "clear"
  let clip = string_style_prop "clip"
  let color = string_style_prop "color"
  let content = string_style_prop "content"
  let counter_increment = string_style_prop "counterIncrement"
  let counter_reset = string_style_prop "counterReset"
  let cue = string_style_prop "cue"
  let cue_after = string_style_prop "cueAfter"
  let cue_before = string_style_prop "cueBefore"
  let cursor = string_style_prop "cursor"
  let direction = string_style_prop "direction"
  let display = string_style_prop "display"
  let elevation = string_style_prop "elevation"
  let empty_cells = string_style_prop "emptyCells"
  let float = string_style_prop "float"
  let font = string_style_prop "font"
  let font_family = string_style_prop "fontFamily"
  let font_size = string_style_prop "fontSize"
  let font_size_adjust = string_style_prop "fontSizeAdjust"
  let font_stretch = string_style_prop "fontStretch"
  let font_style = string_style_prop "fontStyle"
  let font_variant = string_style_prop "fontVariant"
  let font_weight = string_style_prop "fontWeight"
  let height = string_style_prop "height"
  let left = string_style_prop "left"
  let letter_spacing = string_style_prop "letterSpacing"
  let line_height = string_style_prop "lineHeight"
  let list_style = string_style_prop "listStyle"
  let list_style_image = string_style_prop "listStyleImage"
  let list_style_position = string_style_prop "listStylePosition"
  let list_style_type = string_style_prop "listStyleType"
  let margin = string_style_prop "margin"
  let margin_top = string_style_prop "marginTop"
  let margin_right = string_style_prop "marginRight"
  let margin_bottom = string_style_prop "marginBottom"
  let margin_left = string_style_prop "marginLeft"
  let marker_offset = string_style_prop "markerOffset"
  let marks = string_style_prop "marks"
  let max_height = string_style_prop "maxHeight"
  let max_width = string_style_prop "maxWidth"
  let min_height = string_style_prop "minHeight"
  let min_width = string_style_prop "minWidth"
  let orphans = string_style_prop "orphans"
  let outline = string_style_prop "outline"
  let outline_color = string_style_prop "outlineColor"
  let outline_style = string_style_prop "outlineStyle"
  let outline_width = string_style_prop "outlineWidth"
  let overflow = string_style_prop "overflow"
  let overflow_x = string_style_prop "overflowX"
  let overflow_y = string_style_prop "overflowY"
  let padding = string_style_prop "padding"
  let padding_top = string_style_prop "paddingTop"
  let padding_right = string_style_prop "paddingRight"
  let padding_bottom = string_style_prop "paddingBottom"
  let padding_left = string_style_prop "paddingLeft"
  let page = string_style_prop "page"
  let page_break_after = string_style_prop "pageBreakAfter"
  let page_break_before = string_style_prop "pageBreakBefore"
  let page_break_inside = string_style_prop "pageBreakInside"
  let pause = string_style_prop "pause"
  let pause_after = string_style_prop "pauseAfter"
  let pause_before = string_style_prop "pauseBefore"
  let pitch = string_style_prop "pitch"
  let pitch_range = string_style_prop "pitchRange"
  let play_during = string_style_prop "playDuring"
  let position = string_style_prop "position"
  let quotes = string_style_prop "quotes"
  let richness = string_style_prop "richness"
  let right = string_style_prop "right"
  let size = string_style_prop "size"
  let speak = string_style_prop "speak"
  let speak_header = string_style_prop "speakHeader"
  let speak_numeral = string_style_prop "speakNumeral"
  let speak_punctuation = string_style_prop "speakPunctuation"
  let speech_rate = string_style_prop "speechRate"
  let stress = string_style_prop "stress"
  let table_layout = string_style_prop "tableLayout"
  let text_align = string_style_prop "textAlign"
  let text_decoration = string_style_prop "textDecoration"
  let text_indent = string_style_prop "textIndent"
  let text_shadow = string_style_prop "textShadow"
  let text_transform = string_style_prop "textTransform"
  let top = string_style_prop "top"
  let unicode_bidi = string_style_prop "unicodeBidi"
  let vertical_align = string_style_prop "verticalAlign"
  let visibility = string_style_prop "visibility"
  let voice_family = string_style_prop "voiceFamily"
  let volume = string_style_prop "volume"
  let white_space = string_style_prop "whiteSpace"
  let widows = string_style_prop "widows"
  let width = string_style_prop "width"
  let word_spacing = string_style_prop "wordSpacing"
  let z_index = string_style_prop "zIndex"
  let opacity = string_style_prop "opacity"
  let background_origin = string_style_prop "backgroundOrigin"
  let background_size = string_style_prop "backgroundSize"
  let background_clip = string_style_prop "backgroundClip"
  let border_radius = string_style_prop "borderRadius"
  let border_top_left_radius = string_style_prop "borderTopLeftRadius"
  let border_top_right_radius = string_style_prop "borderTopRightRadius"
  let border_bottom_left_radius = string_style_prop "borderBottomLeftRadius"
  let border_bottom_right_radius = string_style_prop "borderBottomRightRadius"
  let border_image = string_style_prop "borderImage"
  let border_image_source = string_style_prop "borderImageSource"
  let border_image_slice = string_style_prop "borderImageSlice"
  let border_image_width = string_style_prop "borderImageWidth"
  let border_image_outset = string_style_prop "borderImageOutset"
  let border_image_repeat = string_style_prop "borderImageRepeat"
  let box_shadow = string_style_prop "boxShadow"
  let columns = string_style_prop "columns"
  let column_count = string_style_prop "columnCount"
  let column_fill = string_style_prop "columnFill"
  let column_gap = string_style_prop "columnGap"
  let column_rule = string_style_prop "columnRule"
  let column_rule_color = string_style_prop "columnRuleColor"
  let column_rule_style = string_style_prop "columnRuleStyle"
  let column_rule_width = string_style_prop "columnRuleWidth"
  let column_span = string_style_prop "columnSpan"
  let column_width = string_style_prop "columnWidth"
  let break_after = string_style_prop "breakAfter"
  let break_before = string_style_prop "breakBefore"
  let break_inside = string_style_prop "breakInside"
  let rest = string_style_prop "rest"
  let rest_after = string_style_prop "restAfter"
  let rest_before = string_style_prop "restBefore"
  let speak_as = string_style_prop "speakAs"
  let voice_balance = string_style_prop "voiceBalance"
  let voice_duration = string_style_prop "voiceDuration"
  let voice_pitch = string_style_prop "voicePitch"
  let voice_range = string_style_prop "voiceRange"
  let voice_rate = string_style_prop "voiceRate"
  let voice_stress = string_style_prop "voiceStress"
  let voice_volume = string_style_prop "voiceVolume"
  let object_fit = string_style_prop "objectFit"
  let object_position = string_style_prop "objectPosition"
  let image_resolution = string_style_prop "imageResolution"
  let image_orientation = string_style_prop "imageOrientation"
  let align_content = string_style_prop "alignContent"
  let align_items = string_style_prop "alignItems"
  let align_self = string_style_prop "alignSelf"
  let flex = string_style_prop "flex"
  let flex_basis = string_style_prop "flexBasis"
  let flex_direction = string_style_prop "flexDirection"
  let flex_flow = string_style_prop "flexFlow"
  let flex_grow = string_style_prop "flexGrow"
  let flex_shrink = string_style_prop "flexShrink"
  let flex_wrap = string_style_prop "flexWrap"
  let justify_content = string_style_prop "justifyContent"
  let order = string_style_prop "order"
  let text_decoration_color = string_style_prop "textDecorationColor"
  let text_decoration_line = string_style_prop "textDecorationLine"
  let text_decoration_skip = string_style_prop "textDecorationSkip"
  let text_decoration_style = string_style_prop "textDecorationStyle"
  let text_emphasis = string_style_prop "textEmphasis"
  let text_emphasis_color = string_style_prop "textEmphasisColor"
  let text_emphasis_position = string_style_prop "textEmphasisPosition"
  let text_emphasis_style = string_style_prop "textEmphasisStyle"
  let text_underline_position = string_style_prop "textUnderlinePosition"
  let font_feature_settings = string_style_prop "fontFeatureSettings"
  let font_kerning = string_style_prop "fontKerning"
  let font_language_override = string_style_prop "fontLanguageOverride"
  let font_synthesis = string_style_prop "fontSynthesis"
  let fornt_variant_alternates = string_style_prop "forntVariantAlternates"
  let font_variant_caps = string_style_prop "fontVariantCaps"
  let font_variant_east_asian = string_style_prop "fontVariantEastAsian"
  let font_variant_ligatures = string_style_prop "fontVariantLigatures"
  let font_variant_numeric = string_style_prop "fontVariantNumeric"
  let font_variant_position = string_style_prop "fontVariantPosition"
  let all = string_style_prop "all"
  let glyph_orientation_vertical = string_style_prop "glyphOrientationVertical"
  let text_combine_upright = string_style_prop "textCombineUpright"
  let text_orientation = string_style_prop "textOrientation"
  let writing_mode = string_style_prop "writingMode"
  let shape_image_threshold = string_style_prop "shapeImageThreshold"
  let shape_margin = string_style_prop "shapeMargin"
  let shape_outside = string_style_prop "shapeOutside"
  let clip_path = string_style_prop "clipPath"
  let clip_rule = string_style_prop "clipRule"
  let mask = string_style_prop "mask"
  let mask_border = string_style_prop "maskBorder"
  let mask_border_mode = string_style_prop "maskBorderMode"
  let mask_border_outset = string_style_prop "maskBorderOutset"
  let mask_border_repeat = string_style_prop "maskBorderRepeat"
  let mask_border_slice = string_style_prop "maskBorderSlice"
  let mask_border_source = string_style_prop "maskBorderSource"
  let mask_border_width = string_style_prop "maskBorderWidth"
  let mask_clip = string_style_prop "maskClip"
  let mask_composite = string_style_prop "maskComposite"
  let mask_image = string_style_prop "maskImage"
  let mask_mode = string_style_prop "maskMode"
  let mask_origin = string_style_prop "maskOrigin"
  let mask_position = string_style_prop "maskPosition"
  let mask_repeat = string_style_prop "maskRepeat"
  let mask_size = string_style_prop "maskSize"
  let mask_type = string_style_prop "maskType"
  let background_blend_mode = string_style_prop "backgroundBlendMode"
  let isolation = string_style_prop "isolation"
  let mix_blend_mode = string_style_prop "mixBlendMode"
  let box_decoration_break = string_style_prop "boxDecorationBreak"
  let box_sizing = string_style_prop "boxSizing"
  let caret_color = string_style_prop "caretColor"
  let nav_down = string_style_prop "navDown"
  let nav_left = string_style_prop "navLeft"
  let nav_right = string_style_prop "navRight"
  let nav_up = string_style_prop "navUp"
  let outline_offset = string_style_prop "outlineOffset"
  let resize = string_style_prop "resize"
  let text_overflow = string_style_prop "textOverflow"
  let grid = string_style_prop "grid"
  let grid_area = string_style_prop "gridArea"
  let grid_auto_columns = string_style_prop "gridAutoColumns"
  let grid_auto_flow = string_style_prop "gridAutoFlow"
  let grid_auto_rows = string_style_prop "gridAutoRows"
  let grid_column = string_style_prop "gridColumn"
  let grid_column_end = string_style_prop "gridColumnEnd"
  let grid_column_gap = string_style_prop "gridColumnGap"
  let grid_column_start = string_style_prop "gridColumnStart"
  let grid_gap = string_style_prop "gridGap"
  let grid_row = string_style_prop "gridRow"
  let grid_row_end = string_style_prop "gridRowEnd"
  let grid_row_gap = string_style_prop "gridRowGap"
  let grid_row_start = string_style_prop "gridRowStart"
  let grid_template = string_style_prop "gridTemplate"
  let grid_template_areas = string_style_prop "gridTemplateAreas"
  let grid_template_columns = string_style_prop "gridTemplateColumns"
  let grid_template_rows = string_style_prop "gridTemplateRows"
  let will_change = string_style_prop "willChange"
  let hanging_punctuation = string_style_prop "hangingPunctuation"
  let hyphens = string_style_prop "hyphens"
  let line_break = string_style_prop "lineBreak"
  let overflow_wrap = string_style_prop "overflowWrap"
  let tab_size = string_style_prop "tabSize"
  let text_align_last = string_style_prop "textAlignLast"
  let text_justify = string_style_prop "textJustify"
  let word_break = string_style_prop "wordBreak"
  let word_wrap = string_style_prop "wordWrap"
  let animation = string_style_prop "animation"
  let animation_delay = string_style_prop "animationDelay"
  let animation_direction = string_style_prop "animationDirection"
  let animation_duration = string_style_prop "animationDuration"
  let animation_fill_mode = string_style_prop "animationFillMode"
  let animation_iteration_count = string_style_prop "animationIterationCount"
  let animation_name = string_style_prop "animationName"
  let animation_play_state = string_style_prop "animationPlayState"
  let animation_timing_function = string_style_prop "animationTimingFunction"
  let transition = string_style_prop "transition"
  let transition_delay = string_style_prop "transitionDelay"
  let transition_duration = string_style_prop "transitionDuration"
  let transition_property = string_style_prop "transitionProperty"
  let transition_timing_function = string_style_prop "transitionTimingFunction"
  let backface_visibility = string_style_prop "backfaceVisibility"
  let perspective = string_style_prop "perspective"
  let perspective_origin = string_style_prop "perspectiveOrigin"
  let transform = string_style_prop "transform"
  let transform_origin = string_style_prop "transformOrigin"
  let transform_style = string_style_prop "transformStyle"
  let justify_items = string_style_prop "justifyItems"
  let justify_self = string_style_prop "justifySelf"
  let place_content = string_style_prop "placeContent"
  let place_items = string_style_prop "placeItems"
  let place_self = string_style_prop "placeSelf"
  let appearance = string_style_prop "appearance"
  let caret = string_style_prop "caret"
  let caret_animation = string_style_prop "caretAnimation"
  let caret_shape = string_style_prop "caretShape"
  let user_select = string_style_prop "userSelect"
  let max_lines = string_style_prop "maxLines"
  let marquee_direction = string_style_prop "marqueeDirection"
  let marquee_loop = string_style_prop "marqueeLoop"
  let marquee_speed = string_style_prop "marqueeSpeed"
  let marquee_style = string_style_prop "marqueeStyle"
  let overflow_style = string_style_prop "overflowStyle"
  let rotation = string_style_prop "rotation"
  let rotation_point = string_style_prop "rotationPoint"
  let alignment_baseline = string_style_prop "alignmentBaseline"
  let baseline_shift = string_style_prop "baselineShift"
  let clip = string_style_prop "clip"
  let clip_path = string_style_prop "clipPath"
  let clip_rule = string_style_prop "clipRule"
  let color_interpolation = string_style_prop "colorInterpolation"

  let color_interpolation_filters =
    string_style_prop "colorInterpolationFilters"

  let color_profile = string_style_prop "colorProfile"
  let color_rendering = string_style_prop "colorRendering"
  let cursor = string_style_prop "cursor"
  let dominant_baseline = string_style_prop "dominantBaseline"
  let fill = string_style_prop "fill"
  let fill_opacity = string_style_prop "fillOpacity"
  let fill_rule = string_style_prop "fillRule"
  let filter = string_style_prop "filter"
  let flood_color = string_style_prop "floodColor"
  let flood_opacity = string_style_prop "floodOpacity"

  let glyph_orientation_horizontal =
    string_style_prop "glyphOrientationHorizontal"

  let glyph_orientation_vertical = string_style_prop "glyphOrientationVertical"
  let image_rendering = string_style_prop "imageRendering"
  let kerning = string_style_prop "kerning"
  let lighting_color = string_style_prop "lightingColor"
  let marker_end = string_style_prop "markerEnd"
  let marker_mid = string_style_prop "markerMid"
  let marker_start = string_style_prop "markerStart"
  let pointer_events = string_style_prop "pointerEvents"
  let shape_rendering = string_style_prop "shapeRendering"
  let stop_color = string_style_prop "stopColor"
  let stop_opacity = string_style_prop "stopOpacity"
  let stroke = string_style_prop "stroke"
  let stroke_dasharray = string_style_prop "strokeDasharray"
  let stroke_dashoffset = string_style_prop "strokeDashoffset"
  let stroke_linecap = string_style_prop "strokeLinecap"
  let stroke_linejoin = string_style_prop "strokeLinejoin"
  let stroke_miterlimit = string_style_prop "strokeMiterlimit"
  let stroke_opacity = string_style_prop "strokeOpacity"
  let stroke_width = string_style_prop "strokeWidth"
  let text_anchor = string_style_prop "textAnchor"
  let text_rendering = string_style_prop "textRendering"
  let ruby_align = string_style_prop "rubyAlign"
  let ruby_merge = string_style_prop "rubyMerge"
  let ruby_position = string_style_prop "rubyPosition"]
end

module SafeString : sig
  type t = private string

  val make_unchecked : string -> t [@@js.custom let make_unchecked str = str]
  val to_string : t -> string [@@js.custom let to_string str = str]
end
