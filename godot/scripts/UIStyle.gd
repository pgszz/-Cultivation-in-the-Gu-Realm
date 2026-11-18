class_name UIStyle
extends RefCounted

const INK := Color("e7e9da")
const DIM := Color("93a99f")
const GOLD := Color("d8bc7c")
const JADE := Color("76c2aa")
const RED := Color("df8775")
const BG := Color("142a29")

static func box(color: Color = BG, border: Color = Color("38504a"), radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(8)
	return s

static func label(text: String, font_size: int = 16, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, callback: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 32
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_stylebox_override("normal", box(Color("203b35")))
	b.add_theme_stylebox_override("hover", box(Color("305548"), JADE))
	b.add_theme_stylebox_override("pressed", box(Color("385b48"), GOLD))
	b.add_theme_stylebox_override("disabled", box(Color("1a2c2a"), Color("2a3e37")))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD))
	if callback.is_valid():
		b.pressed.connect(callback)
	return b

static func rich(font_size: int = 16) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("normal_font_size", font_size)
	l.add_theme_color_override("default_color", INK)
	l.scroll_active = true
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return l

static func card(parent: Node, min_width: float = 0.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box())
	panel.custom_minimum_size.x = min_width
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	return v

static func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func meter(value: float, maximum: float, color: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size.y = 9
	p.max_value = maximum
	p.value = value
	p.show_percentage = false
	p.add_theme_stylebox_override("background", box(Color("0c1a1a"), Color("0c1a1a"), 3))
	p.add_theme_stylebox_override("fill", box(color, color, 3))
	return p
