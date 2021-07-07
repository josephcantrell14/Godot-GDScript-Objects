extends KinematicBody

var hp := 180
var speed := 35
var velocity := Vector3()
const blood = true

func _physics_process(delta) -> void: #run at a fixed time interval
    if global_transform.origin.distance_to(get_parent().get_node("Player").global_transform.origin) >= 300: #move toward player
        var direction = (get_parent().get_node("Player").global_transform.origin - global_transform.origin).normalized()
        velocity = direction*speed
        velocity.y = 0
        velocity = move_and_slide(velocity,Vector3.UP)
    else: #move away from player
        var direction = -1*(get_parent().get_node("Player").global_transform.origin - global_transform.origin).normalized()
        velocity = direction*speed
        velocity.y = 0
        velocity = move_and_slide(velocity,Vector3.UP)
    look_at(get_parent().get_node("Player").global_transform.origin,Vector3.UP)
    rotation_degrees.y += 180
    #collide(direction)
    #if not $Jesus2/AnimationPlayer.is_playing():
        #$Jesus2/AnimationPlayer.play("Walkv2")
func hitByPlayer(damage) -> void:
    if hp > 0:
        hp -= damage
        if hp <= 0:
            end()
func end() -> void: #enemy defeated animation and deinstancing
    var explosion = preload("res://ExplosionReal.tscn").instance()
    get_parent().add_child(explosion)
    explosion.scale = Vector3(150,150,150)
    explosion.global_transform.origin = global_transform.origin + Vector3(0,-50,0)
    explosion.get_node("Particles").emitting = true
    hide()
    $ShootTimer.stop()
    $CollisionShape.disabled = true
    $CollisionShape2.disabled = true
    $CollisionShapeHead.disabled = true
    get_parent().get_node("HUD").addScore(120)
    $EndSound.play()
func shoot() -> void:
    var bullet = preload("res://LightningBolt.tscn").instance()
    get_parent().add_child(bullet)
    bullet.add_collision_exception_with(self)
    bullet.global_transform.origin = global_transform.origin
    bullet.look_at(get_parent().get_node("Player").global_transform.origin,Vector3.UP)
    var direction = (get_parent().get_node("Player").global_transform.origin - global_transform.origin).normalized()
    bullet.velocity = direction*200
    #bullet.linear_velocity = direction*200
    #bullet.linear_velocity = Vector3(15,-500,-293)
    #$ShootSound.play()
func collide(direction) -> void: #check for collision with the player
    for i in range(get_slide_count()):
        var collision = get_slide_collision(i)
        if collision != null:
            var body = collision.collider
            if body.has_method("playerHit"):
                body.playerHit(5)
                body.velocity += direction*200
func _on_EndSound_finished() -> void:
    queue_free()
func _on_ShootTimer_timeout() -> void:
    shoot()
