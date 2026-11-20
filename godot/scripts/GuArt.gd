class_name GuArt
extends RefCounted

# Original generated transparent Gu paintings; creation record in assets/gu/painted/SOURCE.json.
const PORTRAITS := {
	"iron_bone": preload("res://assets/gu/painted/iron_bone.png"),
	"jade_bone": preload("res://assets/gu/painted/jade_bone.png"),
	"vitality_leaf": preload("res://assets/gu/painted/vitality_leaf.png"),
	"self_reliance": preload("res://assets/gu/painted/self_reliance.png"),
	"tempered_sinew": preload("res://assets/gu/painted/tempered_sinew.png"),
	"clot_thread": preload("res://assets/gu/painted/clot_thread.png"),
	"numb_ant": preload("res://assets/gu/painted/numb_ant.png"),
	"lucid_larva": preload("res://assets/gu/painted/lucid_larva.png"),
	"sinew_spring": preload("res://assets/gu/painted/sinew_spring.png"),
	"feather_marrow": preload("res://assets/gu/painted/feather_marrow.png"),
	"ballast_bone": preload("res://assets/gu/painted/ballast_bone.png"),
	"scar_crust": preload("res://assets/gu/painted/scar_crust.png"),
	"red_pulse": preload("res://assets/gu/painted/red_pulse.png"),
	"lung_bell": preload("res://assets/gu/painted/lung_bell.png"),
	"bitter_liver": preload("res://assets/gu/painted/bitter_liver.png"),
	"warm_muscle": preload("res://assets/gu/painted/warm_muscle.png"),
	"nerve_lantern": preload("res://assets/gu/painted/nerve_lantern.png"),
	"clear_cornea": preload("res://assets/gu/painted/clear_cornea.png"),
	"ear_suture": preload("res://assets/gu/painted/ear_suture.png"),
	"joint_mender": preload("res://assets/gu/painted/joint_mender.png"),
	"clear_origin_silkworm":preload("res://assets/gu/painted/clear_origin_silkworm.png"),
	"deep_spring_butterfly":preload("res://assets/gu/painted/deep_spring_butterfly.png"),
	"marrow_lotus_beetle":preload("res://assets/gu/painted/marrow_lotus_beetle.png"),
	"nine_aurora_cocoon":preload("res://assets/gu/painted/nine_aurora_cocoon.png"),
	"bronze_relic":preload("res://assets/gu/painted/bronze_relic.png"),
	"red_iron_relic":preload("res://assets/gu/painted/red_iron_relic.png"),
	"silver_relic":preload("res://assets/gu/painted/silver_relic.png"),
	"gold_relic":preload("res://assets/gu/painted/gold_relic.png"),
	"purple_relic":preload("res://assets/gu/painted/purple_relic.png"),
	"quiet_incense_moth":preload("res://assets/gu/painted/quiet_incense_moth.png"),
	"wall_polish_snail":preload("res://assets/gu/painted/wall_polish_snail.png"),
	"copper_fletch":preload("res://assets/gu/painted/copper_fletch.png"),
	"sand_fang":preload("res://assets/gu/painted/sand_fang.png"),
	"rain_needle":preload("res://assets/gu/painted/rain_needle.png"),
	"obsidian_mantis":preload("res://assets/gu/painted/obsidian_mantis.png"),
	"storm_hornet":preload("res://assets/gu/painted/storm_hornet.png"),
	"sun_ember_scarab":preload("res://assets/gu/painted/sun_ember_scarab.png"),
	"glacier_centipede":preload("res://assets/gu/painted/glacier_centipede.png"),
	"bark_bastion":preload("res://assets/gu/painted/bark_bastion.png"),
	"quartz_tortoise":preload("res://assets/gu/painted/quartz_tortoise.png"),
	"thunder_insulator":preload("res://assets/gu/painted/thunder_insulator.png"),
	"basalt_heart":preload("res://assets/gu/painted/basalt_heart.png"),
	"prism_aegis":preload("res://assets/gu/painted/prism_aegis.png"),
	"scar_stitch":preload("res://assets/gu/painted/scar_stitch.png"),
	"red_dew_tick":preload("res://assets/gu/painted/red_dew_tick.png"),
	"calm_bell_moth":preload("res://assets/gu/painted/calm_bell_moth.png"),
	"purifying_lacewing":preload("res://assets/gu/painted/purifying_lacewing.png"),
	"return_spring_silk":preload("res://assets/gu/painted/return_spring_silk.png"),
	"grass_skipper":preload("res://assets/gu/painted/grass_skipper.png"),
	"river_fin":preload("res://assets/gu/painted/river_fin.png"),
	"gale_kite_moth":preload("res://assets/gu/painted/gale_kite_moth.png"),
	"shadow_step_spider":preload("res://assets/gu/painted/shadow_step_spider.png"),
	"lantern_antenna":preload("res://assets/gu/painted/lantern_antenna.png"),
	"ore_echo_cicada":preload("res://assets/gu/painted/ore_echo_cicada.png"),
	"horizon_owl_moth":preload("res://assets/gu/painted/horizon_owl_moth.png"),
	"deep_resonance_beetle":preload("res://assets/gu/painted/deep_resonance_beetle.png"),
	"reed_cutter":preload("res://assets/gu/painted/reed_cutter.png"),
	"flint_mason":preload("res://assets/gu/painted/flint_mason.png"),
	"amber_resin_ant":preload("res://assets/gu/painted/amber_resin_ant.png"),
	"mountain_borer":preload("res://assets/gu/painted/mountain_borer.png"),
	"hope_gu":preload("res://assets/gu/painted/hope_gu.png"),
	"golden_splinter":preload("res://assets/gu/painted/golden_splinter.png"),
	"stone_pellet":preload("res://assets/gu/painted/stone_pellet.png"),
	"wind_shear":preload("res://assets/gu/painted/wind_shear.png"),
	"venom_gnat":preload("res://assets/gu/painted/venom_gnat.png"),
	"red_lotus_moth":preload("res://assets/gu/painted/red_lotus_moth.png"),
	"ice_lance":preload("res://assets/gu/painted/ice_lance.png"),
	"thunder_pupa":preload("res://assets/gu/painted/thunder_pupa.png"),
	"thorn_seed":preload("res://assets/gu/painted/thorn_seed.png"),
	"iron_drill":preload("res://assets/gu/painted/iron_drill.png"),
	"rime_wing":preload("res://assets/gu/painted/rime_wing.png"),
	"blood_suture":preload("res://assets/gu/painted/blood_suture.png"),
	"warm_pupa":preload("res://assets/gu/painted/warm_pupa.png"),
	"rain_pearl":preload("res://assets/gu/painted/rain_pearl.png"),
	"vigor_grub":preload("res://assets/gu/painted/vigor_grub.png"),
	"spring_cocoon":preload("res://assets/gu/painted/spring_cocoon.png"),
	"reed_armor":preload("res://assets/gu/painted/reed_armor.png"),
	"mirror_scale":preload("res://assets/gu/painted/mirror_scale.png"),
	"cinder_coat":preload("res://assets/gu/painted/cinder_coat.png"),
	"frost_ward":preload("res://assets/gu/painted/frost_ward.png"),
	"quick_cricket":preload("res://assets/gu/painted/quick_cricket.png"),
	"cloud_locust":preload("res://assets/gu/painted/cloud_locust.png"),
	"water_skater":preload("res://assets/gu/painted/water_skater.png"),
	"mist_butterfly":preload("res://assets/gu/painted/mist_butterfly.png"),
	"far_sight":preload("res://assets/gu/painted/far_sight.png"),
	"earth_cicada":preload("res://assets/gu/painted/earth_cicada.png"),
	"scent_ant":preload("res://assets/gu/painted/scent_ant.png"),
	"ore_mandible":preload("res://assets/gu/painted/ore_mandible.png"),
	"timber_mantis":preload("res://assets/gu/painted/timber_mantis.png"),
	"gather_scarab":preload("res://assets/gu/painted/gather_scarab.png"),
	"burrow_grub":preload("res://assets/gu/painted/burrow_grub.png"),
	"soothing_moth":preload("res://assets/gu/painted/soothing_moth.png"),
	"stream_gu":preload("res://assets/gu/painted/stream_gu.png"),
	"ember_moth":preload("res://assets/gu/painted/ember_moth.png"),
	"frost_midge":preload("res://assets/gu/painted/frost_midge.png"),
	"vine_spider":preload("res://assets/gu/painted/vine_spider.png"),
	"mending_silk":preload("res://assets/gu/painted/mending_silk.png"),
	"resin_beetle":preload("res://assets/gu/painted/resin_beetle.png"),
	"dew_moth":preload("res://assets/gu/painted/dew_moth.png"),
	"wind_moth":preload("res://assets/gu/painted/wind_moth.png"),
	"night_firefly":preload("res://assets/gu/painted/night_firefly.png"),
	"echo_cicada":preload("res://assets/gu/painted/echo_cicada.png"),
	"gravel_shell":preload("res://assets/gu/painted/gravel_shell.png"),
	"bamboo_saw":preload("res://assets/gu/painted/bamboo_saw.png"),
	"veil_leaf":preload("res://assets/gu/painted/veil_leaf.png"),
	"moon_glow":preload("res://assets/gu/painted/moon_glow.png"),
	"white_jade":preload("res://assets/gu/painted/white_jade.png"),
	"moon_raiment":preload("res://assets/gu/painted/moon_raiment.png"),
	"copper_skin":preload("res://assets/gu/painted/copper_skin.png"),
	"iron_skin":preload("res://assets/gu/painted/iron_skin.png"),
	"stone_skin":preload("res://assets/gu/painted/stone_skin.png"),
	"beast_skin":preload("res://assets/gu/painted/beast_skin.png"),
	"brute_longhorn":preload("res://assets/gu/painted/brute_longhorn.png"),
	"yellow_camel":preload("res://assets/gu/painted/yellow_camel.png"),
	"dragon_cricket":preload("res://assets/gu/painted/dragon_cricket.png"),
	"moon_blade":preload("res://assets/gu/painted/moon_blade.png"),
	"jiu_chong":preload("res://assets/gu/painted/jiu_chong.png"),
	"jade_skin":preload("res://assets/gu/painted/jade_skin.png"),
	"little_light":preload("res://assets/gu/painted/little_light.png"),
	"white_boar":preload("res://assets/gu/painted/white_boar.png"),
	"black_boar":preload("res://assets/gu/painted/black_boar.png"),
}

static func texture(id: String) -> Texture2D:
	return PORTRAITS.get(id)

static func fitted_rect(id: String, bounds: Rect2) -> Rect2:
	var art:=texture(id)
	if art==null: return bounds
	var extent:=art.get_size()
	var fitted:=extent*minf(bounds.size.x/extent.x,bounds.size.y/extent.y)
	return Rect2(bounds.position+(bounds.size-fitted)*0.5,fitted)

static func portrait(side: float = 96) -> TextureRect:
	var view:=TextureRect.new()
	view.custom_minimum_size=Vector2(side,side)
	view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view

static func decorate(button: Button, id: String, side: int = 32) -> void:
	button.icon=texture(id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",side)
	button.add_theme_constant_override("h_separation",6)
