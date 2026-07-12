class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from horizontal strip PNGs (pixel-art-sheets spec).
## defs: anim_name -> { path: String, frames: int, fps: float, loop: bool (default true) }


static func build(defs: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	for anim: StringName in defs:
		var d: Dictionary = defs[anim]
		var tex: Texture2D = load(d.path)
		var fw := tex.get_width() / int(d.frames)
		if not sf.has_animation(anim):
			sf.add_animation(anim)
		sf.set_animation_speed(anim, d.fps)
		sf.set_animation_loop(anim, d.get("loop", true))
		for i in int(d.frames):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, tex.get_height())
			sf.add_frame(anim, at)
	sf.remove_animation(&"default")
	return sf
