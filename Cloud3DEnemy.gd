extends KinematicBody

var speedInit := 10
var speed := speedInit
var velocity := Vector3()
var seekRange := 0
var seeking := false
var divide := true
var hp := .3
var alive := true

func _ready() -> void: #executed on addition to the scenetree object
    seekRange = 152 + randi()%40
    var difficulty :float= get_parent().get_parent().get_node("HUD").difficulty/100
    speedInit *= difficulty
    speed = speedInit
    hp *= difficulty
func _physics_process(_delta: float) -> void: #executed continually at a fixed time interval
    if alive:
        var playerPosition = get_parent().get_parent().get_node("Player").global_transform.origin
        var playerDistance = global_transform.origin.distance_to(playerPosition)
        if seeking:
            var spaceState := get_world().direct_space_state #raycast check player's visibility
            var raycastCollisionObject :Dictionary= spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
            var direction := Vector3()
            if raycastCollisionObject:
                var collision :Object= raycastCollisionObject.collider
                if collision and collision.is_in_group("Player"):
                    direction = (playerPosition-global_transform.origin).normalized()
            else:
                direction = Vector3(0,1,0) #float up until player is visible
            velocity = move_and_slide(direction*speed,Vector3.UP) #move toward player
            look_at(playerPosition,Vector3.UP)
            for i in range(get_slide_count()): #check direct collisions
                var slideCollision := get_slide_collision(i)
                if slideCollision != null:
                    var body :Object= slideCollision.collider
                    if body.has_method("playerHit"):
                        body.playerHit(25)
                        body.velocity += direction*250
                        speed /= 5
                        $AttackDelay.start()
        elif playerDistance < seekRange: #move if player is close
            seeking = true
func damaged(damage:float) -> void: 
    hp -= damage
    #print(str(damage) + " ; " + str(hp))
    get_parent().get_parent().get_node("HUD/InfoLabel").text = str(damage) + " ; " + str(hp)
    if hp <= 0 and alive:
        alive = false
        if divide:
            get_parent().get_parent().cholinergicCloudDivision(global_transform.origin) #spawn two replicas
        $Particles.emitting = false
        $Particles2.emitting = false
        $CollisionShape.disabled = true
        $ExplodeLight.show()
        $EndTimer.start()
func _on_AttackDelay_timeout() -> void: #executed after AttackDelay timer counts down
    speed = speedInit
func _on_EndTimer_timeout() -> void: #executed after EndTimer counts down (after particles dissipate)
    queue_free()
