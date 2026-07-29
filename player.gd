extends CharacterBody2D



# ==========================================
# 1. إعدادات قابلة للتعديل من الـ Inspector
# ==========================================
@export_group("الحركة - Movement")
@export var speed: float = 200.0
@export var jump_velocity: float = -380.0

@export_group("الاندفاع - Dash")
@export var dash_speed: float = 500.0     # سرعة الاندفاع
@export var dash_duration: float = 0.2    # مدة الاندفاع بالثواني (كلما قل الوقت قلّت المسافة)
@export var dash_cooldown: float = 0.8    # وقت الانتظار للاندفاع التالي

@export_group("القتال - Combat")
@export var attack1_duration: float = 0.28
@export var attack2_duration: float = 0.28
@export var combo_reset_time: float = 0.25

@export_group("الصحة - Health")
@export var max_health: int = 3
var current_health: int = 3

# ==========================================
# 2. المتغيرات الداخلية والحالات
# ==========================================
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dashing: bool = false
var can_dash: bool = true
var is_attacking: bool = false

var combo_step: int = 1
var buffered_attack: bool = false
var combo_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_collision: CollisionShape2D = $AttackArea

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var playback = anim_tree.get("parameters/playback")

# ==========================================
# 3. دالة البداية والتحديث
# ==========================================

func _physics_process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0 and not is_attacking:
			combo_step = 1

	# أثناء الاندفاع نكتفي بالتحريك ثم نخرج
	if is_dashing:
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_attacking:
		handle_movement()
		handle_jump()
		handle_dash()
		update_animations()

	handle_attack_input()
	move_and_slide()

# ==========================================
# 4. دوال التحكم والحركة
# ==========================================
func handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0)
		
		if attack_collision:
			attack_collision.position.x = abs(attack_collision.position.x) * (-1 if direction < 0 else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# ==========================================
# 5. نظام الاندفاع المحمي من الطيران (Fixed Dash)
# ==========================================
func handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and not is_attacking:
		start_dash()

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	is_attacking = false
	
	if attack_collision:
		attack_collision.disabled = true

	var dash_direction = -1 if sprite.flip_h else 1
	velocity.x = dash_direction * dash_speed
	velocity.y = 0
	
	playback.travel("dash")
	
	await get_tree().create_timer(dash_duration).timeout
	
	# إيقاف السرعة تماماً وإعادة التحكم
	velocity.x = 0
	is_dashing = false
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# ==========================================
# 6. نظام الهجوم
# ==========================================
func handle_attack_input() -> void:
	if Input.is_action_just_pressed("attack"):
		if not is_attacking:
			start_combo_attack()
		else:
			buffered_attack = true

func start_combo_attack() -> void:
	is_attacking = true
	buffered_attack = false
	velocity.x = 0

	if combo_step == 1:
		playback.travel("attack1")
		if attack_collision:
			attack_collision.disabled = false
		
		await get_tree().create_timer(attack1_duration).timeout
		
		if attack_collision:
			attack_collision.disabled = true
		
		if buffered_attack:
			combo_step = 2
			start_combo_attack()
		else:
			is_attacking = false
			combo_step = 2
			combo_timer = combo_reset_time

	elif combo_step == 2:
		playback.travel("attack2")
		if attack_collision:
			attack_collision.disabled = false
		
		await get_tree().create_timer(attack2_duration).timeout
		
		if attack_collision:
			attack_collision.disabled = true
		
		combo_step = 1
		is_attacking = false
		
		if buffered_attack:
			start_combo_attack()

# ==========================================
# 7. إدارة الأنيميشن العادية
# ==========================================
func update_animations() -> void:
	if is_attacking or is_dashing:
		return

	if is_on_floor():
		if velocity.x != 0:
			playback.travel("run")
		else:
			playback.travel("idle")
	else:
		if velocity.y < 0:
			playback.travel("jump")
		else:
			playback.travel("fall")





func _process(_delta: float) -> void:
	# حماية مطلقة لمنع تجاوز الفريمات تحت أي ظرف
	if $Sprite2D and $Sprite2D.texture:
		var max_frames = $Sprite2D.hframes * $Sprite2D.vframes
		if max_frames > 0 and $Sprite2D.frame >= max_frames:
			$Sprite2D.frame = 0
			












	# Handle jump.
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	
	# Flipe the sprite
	
		
	# Play animations

	
func _ready():
	current_health = max_health
	anim_tree.active = true
	if attack_collision:
		attack_collision.disabled = true

							



	

	
	if SaveManager and SaveManager.target_spawn_point != "":
		var spawn_node = get_parent().find_child(SaveManager.target_spawn_point)
		if spawn_node:
			global_position = spawn_node.global_position
			print("تم نقل اللاعب إلى نقطة البوابة: ", spawn_node.name)
			apply_facing_direction(SaveManager.player_facing_left)
			
		SaveManager.target_spawn_point = ""
		
		
func apply_facing_direction(facing_left: bool):
	print("حالة اتجاه الوجه المطلوبة هي: ", facing_left)
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
				# أضفنا not هنا لعكس المنطق ليتوافق مع الاتجاه الأصلي لصور الشخصية
			child.flip_h = not  facing_left
											
												
		

			
