extends Control

const VU_COUNT = 128
const FREQ_MAX = 11050.0
const MIN_DB = 60

const WIDTH = 1920
const HEIGHT = 1060
const HEIGHT_SCALE = 8.0

const ANIMATION_SPEED = 0.04

var spectrum
var min_values = []
var max_values = []

func _ready():
	self.show()
	spectrum = AudioServer.get_bus_effect_instance(1, 0)
	min_values.resize(VU_COUNT)
	max_values.resize(VU_COUNT)
	min_values.fill(0.0)
	max_values.fill(0.0)

func _process(delta):
	spectrum_analyzer()



func _draw():
	var w = WIDTH / VU_COUNT
	for i in range(VU_COUNT):
		var min_height = min_values[i]
		var max_height = max_values[i]
		var height = lerp(min_height, max_height, ANIMATION_SPEED)

		draw_rect(
				Rect2(w * i, HEIGHT - height, w - 2, height),
				Color(1, 1, 1)
				#Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 0.6)
		)
		draw_line(
				Vector2(w * i, HEIGHT - height),
				Vector2(w * i + w - 2, HEIGHT - height),
				Color(0.871, 0.949, 1.0, 1.0),
				#Color.from_hsv(float(VU_COUNT * 0.6 + i * 0.5) / VU_COUNT, 0.5, 1.0),
				2.0,
				true
		)


func spectrum_analyzer():
	var data = []
	var prev_hz = 0

	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT * HEIGHT_SCALE
		data.append(height)
		prev_hz = hz

	for i in range(VU_COUNT):
		if data[i] > max_values[i]:
			max_values[i] = data[i]
		else:
			max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)

		if data[i] <= 0.0:
			min_values[i] = lerp(min_values[i], 0.0, ANIMATION_SPEED)

	# Sound plays back continuously, so the graph needs to be updated every frame.
	queue_redraw()
