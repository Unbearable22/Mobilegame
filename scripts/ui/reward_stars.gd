class_name RewardStars
extends Label
var revealed: int = 0
var reward_total: int = 0
var suffix: String = ""
var reveal_tween: Tween
func begin(total: int,reduced: bool) -> void:
	reward_total = clampi(total,0,3)
	if reveal_tween: reveal_tween.kill()
	if reduced:
		revealed = reward_total
		_render()
		return
	revealed = 0
	_render()
	reveal_tween = create_tween()
	for count in range(1,reward_total+1):
		reveal_tween.tween_interval(.16)
		reveal_tween.tween_callback(func(): revealed=count; _render())
func _render() -> void:
	text = "★".repeat(revealed)+"☆".repeat(reward_total-revealed)+suffix
