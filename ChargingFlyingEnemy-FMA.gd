extends KinematicBody

var speedInit := 10.0
var speed : float
var speedRising := 1
var velocity := Vector3()
var seekRange : int
var seeking := false
var divide := true
var hp := 1.0
var alive := true

func _ready() -> void:
    var difficulty :float= get_tree().get_root().get_node("Main/HUD").difficulty/100
    seekRange = 210.0 + randi()%30 + 50.0*(difficulty-1)
    speedInit += rand_range(0,3)
    speedInit *= difficulty
    speed = speedInit
    hp *= difficulty
func _physics_process(_delta: float) -> void:
    if alive:
        var playerPosition = get_tree().get_root().get_node("Main/Player").global_transform.origin
        var playerDistance = global_transform.origin.distance_to(playerPosition)
        if seeking:
            var spaceState := get_world().direct_space_state #raycast check player's visibility
            var raycastCollisionObject :Dictionary= spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
            var direction := Vector3()
            #print("collision object: " + str(raycastCollisionObject))
            if raycastCollisionObject:
                var collision :Object= raycastCollisionObject.collider
                #print("collided with: " + str(collision))
                if collision and collision.is_in_group("Player"):
                    direction = (playerPosition-global_transform.origin).normalized()
                    speed = speedInit
                else:
                    direction = Vector3(0,1,0) #float up until player is visible
                    speed = speedRising
            else:
                direction = Vector3(0,1,0)
                speed = speedRising
            velocity = move_and_slide(direction*speed,Vector3.UP) #move toward player
            look_at(playerPosition,Vector3.UP)
            for i in range(get_slide_count()): #check direct collisions
                var slideCollision := get_slide_collision(i)
                if slideCollision != null:
                    var body :Object= slideCollision.collider
                    if body.has_method("playerHit"):
                        body.playerHit(50)
                        body.velocity += direction*250
                        body.velocity.y = 0
                        speed /= 5
                        $AttackDelay.start()
        elif playerDistance < seekRange: #move if player is close
            seeking = true
func damaged(damage:float) -> void:
    if alive:
        hp -= damage
        if not $DamagedSound.playing:
            $DamagedSound.play()
        #print(str(damage) + " ; " + str(hp))
        if hp <= 0:
            alive = false
            if divide:
                get_tree().get_root().get_node("Main").cholinergicCloudDivision(global_transform.origin) #spawn two replicas
            $Particles.emitting = false
            $Particles2.emitting = false
            $CollisionShape.disabled = true
            $ExplodeLight.show()
            $EndTimer.start()
func _on_AttackDelay_timeout() -> void:
    speed = speedInit
func _on_EndTimer_timeout() -> void:
    queue_free()



""" Slither left and right algorithm (broken)
func _physics_process(_delta: float) -> void:
    var playerPosition = get_parent().get_parent().get_node("Player").global_transform.origin
    var playerDistance = global_transform.origin.distance_to(playerPosition)
    if seeking:
        var spaceState = get_world().direct_space_state #raycast to player
        var raycastCollisionObject = spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
        var collision = null
        var direction := Vector3()
        if raycastCollisionObject:
            collision = raycastCollisionObject.collider
            if collision and collision.is_in_group("Player"):
                var targetDistance = global_transform.origin.distance_to(targetPosition)
                if targetDistance < 5:
                    playerDirection = (playerPosition-global_transform.origin).normalized()
                    if playerDistance < 25:
                        targetPosition = playerPosition
                        direction = playerDirection
                    else:
                        targetPosition = playerPosition - 50*playerDirection + right*playerDirection.cross(Vector3(0,30,0)) #slither left and right toward player
                        #print("cross product: " + str(right*playerDirection.cross(Vector3.UP)))
                        #print("target: " + str(targetPosition) + " player: " + str(playerPosition))
                        right *= -1
                direction = (targetPosition-global_transform.origin).normalized()
                look_at(targetPosition,Vector3.UP)
        else:
            direction = Vector3(0,1,0) #float up until player is visible
        velocity = move_and_slide(direction*speed,Vector3.UP) #seek target
        \"""for i in range(get_slide_count()): #only check player collisions
            var slideCollision = get_slide_collision(i)
            if slideCollision != null:
                var body = slideCollision.collider
                if body.has_method("playerHit"):
                    body.playerHit(25)
                    body.velocity += direction*40\"""
    elif playerDistance < seekRange:
        seeking = true
"""
