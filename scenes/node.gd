extends Node

# Preload
var bee_scene = preload("res://scenes/bee.tscn")
var block_scene = preload("res://scenes/block.tscn")
var bull_scene = preload("res://scenes/bull.tscn")
var slug_scene = preload("res://scenes/slug.tscn")
var plant_scene = preload("res://scenes/piranha_plant.tscn")

var obstacle_types := [block_scene, bull_scene]
var obstacles : Array
var bee_heights := [150, 300]

const SUNNY_START_POS := Vector2i(150, 380)
const CAM_START_POS := Vector2i(576, 280)

var difficulty
const MAX_DIFFICULTY : int = 2

# Score
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int

var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : int =  25
const SPEED_MODIFIER : int = 5000

var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

# Called when the node enters the scene tree for the first time
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$Restart.get_node("Button").pressed.connect(new_game)
	new_game()
	
func new_game():	
	# Score
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0

	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# Reset the nodes
	$CharacterBody2D.position = SUNNY_START_POS
	$CharacterBody2D.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)

	$CanvasLayer.get_node("StartLabel").show()
	$Restart.hide()

# Called every frame. 
func _process(delta):
	if game_running:
		
		# Spedd
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		# Generate obstacles
		generate_obs()
		
		# Move character and camera
		$CharacterBody2D.position.x += speed
		$Camera2D.position.x += speed

		# Score
		score += speed
		# Test ## print(score)
		show_score()
		
		#update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		# Remove obstacles
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
			
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$CanvasLayer.get_node("StartLabel").hide()
	
func generate_obs():
	
	if obstacles	.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		
		for i in range(randi() % max_obs + 1):
			
			obs = obs_type.instantiate()

			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
				
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		
		# Add spaw animation
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				#generate bird obstacles
				obs = bee_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bee_heights[randi() % bee_heights.size()]
				add_obs(obs, obs_x, obs_y)	
		
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "CharacterBody2D":
		game_over()

func show_score():
	$CanvasLayer.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$CanvasLayer.get_node("HighLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)
			
func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$Restart.show()
