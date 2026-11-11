class_name IconLibrary
extends RefCounted
static var cache: Dictionary = {}
const PATHS: Dictionary = {
	"undo": '<path d="M24 16L10 28l14 12M10 28h24c24 0 24 24 5 24"/>',
	"restart": '<path d="M50 22A22 22 0 1 0 53 40M50 8v16H34"/>',
	"pause": '<path d="M23 13v38M41 13v38"/>',
	"play": '<path d="M22 12l30 20-30 20Z"/>',
	"next": '<path d="M10 32h42M35 14l18 18-18 18"/>',
	"back": '<path d="M54 32H12M29 14L11 32l18 18"/>',
	"levels": '<rect x="10" y="10" width="16" height="16" rx="2"/><rect x="38" y="10" width="16" height="16" rx="2"/><rect x="10" y="38" width="16" height="16" rx="2"/><rect x="38" y="38" width="16" height="16" rx="2"/>',
	"info": '<circle cx="32" cy="32" r="23"/><path d="M32 29v17M32 18v1"/>',
	"settings": '<path d="M27 8h10l2 7 6 3 7-2 5 9-5 5v6l5 5-5 9-7-2-6 3-2 7H27l-2-7-6-3-7 2-5-9 5-5v-6l-5-5 5-9 7 2 6-3Z"/><circle cx="32" cy="33" r="9"/>',
	"home": '<path d="M8 29L32 9l24 20M15 25v30h13V38h9v17h12V25"/>',
	"close": '<path d="M16 16l32 32M48 16L16 48"/>',
	"lock": '<rect x="15" y="27" width="34" height="28" rx="5"/><path d="M22 27V19a10 10 0 0 1 20 0v8M32 38v7"/>',
	"chapters": '<rect x="10" y="15" width="33" height="40" rx="4"/><path d="M20 7h34v40M20 29h13M20 39h13"/>'
}
static func icon(key: String) -> Texture2D:
	if cache.has(key): return cache[key]
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#b7f4fa" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">' + PATHS[key] + '</g></svg>'
	var bitmap := Image.new()
	bitmap.load_svg_from_string(svg,2.0)
	var texture: Texture2D = ImageTexture.create_from_image(bitmap)
	cache[key] = texture
	return texture
