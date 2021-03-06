extends KinematicBody

var walkSpeed := 26
var slowSpeed := 11
const lurchSpeed := 90
var speed := walkSpeed
var velocity := Vector3()
var targetPosition := Vector3()
var previousJunction := Vector3()
var bedroomPosition = Vector3(-315,25,700)

func _ready() -> void: #executed when Shadow is added as a child of the SceneTree object
    set_physics_process(false)
    var difficulty :float= get_parent().get_node("HUD").difficulty/100
    walkSpeed = 26.0*difficulty#+= 8*(difficulty-1)
    slowSpeed = 11.0*difficulty#+= 4*(difficulty-1)
    speed = walkSpeed
func _physics_process(_delta:float) -> void: #runs at a fixed interval of milliseconds
    var direction :Vector3= (targetPosition-global_transform.origin).normalized()
    direction.y = 0
    velocity = direction*speed
    velocity.y = 0
    velocity = move_and_slide(velocity,Vector3.UP)
    if global_transform.origin.x != targetPosition.x: #prevent invalid look_at()
        look_at(targetPosition,Vector3.RIGHT)
    rotation_degrees.x = 90
    #rotation_degrees.y += 180
    collide(direction)
    if speed != lurchSpeed:
        if direction == Vector3():
            if $AnimationPlayer.current_animation == "Walk":
                $AnimationPlayer.stop()
        elif not $AnimationPlayer.is_playing():
            $AnimationPlayer.play("Walk")
        var playerPosition = get_parent().get_node("Player").global_transform.origin
        #if global_transform.origin.distance_to(playerPosition) < 30: #repath to player
        #    seek()
        var spaceState := get_world().direct_space_state
        var collisionObject :Dictionary= spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
        var collision = null
        if collisionObject:
            collision = collisionObject.collider
        if collision:
            #print(str(collision.name.replace("@", "").replace(str(int(collision.name)), "")))
            if collision.is_in_group("Player"):
                seek()
func _on_RaycastTimer_timeout(): #AStar calculations every 5 seconds because of a changing algorithm goal (moving target)
    AStar()
    speed = walkSpeed
func AStar() -> void: #move to the node in a graph with the lowest cost of reaching the goal
    var playerPosition :Vector3= get_parent().get_node("Player").global_transform.origin
    var junctions :Array= get_tree().get_nodes_in_group("junctions")
    if get_parent().get_node("Player").cover:
        previousJunction = targetPosition
        targetPosition = junctions[randi()%len(junctions)].global_transform.origin  #navigate to random junction when player is in cover
        return
    #else:
    #    targetPosition = playerPosition
    var spaceState := get_world().direct_space_state
    var collisionObject :Dictionary= spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
    var collision = null
    if collisionObject:
        collision = collisionObject.collider
    if collision:
        #print(str(collision.name.replace("@", "").replace(str(int(collision.name)), "")))
        if collision.is_in_group("Player"):
            previousJunction = targetPosition
            targetPosition = playerPosition #ignore graph nodes and go straight to player if the player is in sight
            return
        else: #move along graph of nodes until player is in sight
            var bestJunction = Vector3()
            var bestJunctionCost = INF
            for junctionNode in junctions: #check each junction's viability and cost
                var junction = junctionNode.global_transform.origin
                #if junction == targetPosition and junctionDistance < 1:
                    #continue
                var junctionRayCastObject :Dictionary= spaceState.intersect_ray(global_transform.origin,junction,[self])
                if not junctionRayCastObject or not junctionRayCastObject.collider: #if a visible path to junction exists (viable neighbor)
                    var junctionDistance = global_transform.origin.distance_to(junction)
                    var cost :float= junctionDistance + abs(junction.x-playerPosition.x) + abs(junction.z-playerPosition.z)#junction.distance_to(playerPosition) #cost of moving to junction with additional heuristic of linear player z distance
                    if cost < bestJunctionCost:
                        bestJunctionCost = cost
                        bestJunction = junction
                #else:
                    #print("junctionObject: " + str(junctionRayCastObject.collider.name.replace("@", "").replace(str(int(junctionRayCastObject.collider.name)), "")) + str(junctionRayCastObject.position) + " orig: " +  str(global_transform.origin) + " junction: " + str(junction))
            if bestJunction != targetPosition and bestJunction != previousJunction:
                previousJunction = targetPosition
                if bestJunction != previousJunction:
                    targetPosition = bestJunction
    #print("target: " + str(targetPosition))
func seek() -> void: #seek the player
    targetPosition = get_parent().get_node("Player").global_transform.origin
    set_physics_process(true)
    AStar()
    $RaycastTimer.start()
func guard(): #stay still
    set_physics_process(false)
    $RaycastTimer.stop()
func fade() -> void: #fade out of sight
    #print("fade at " + str(global_transform.origin))
    guard()
    hide()
    #$AnimationPlayer.play("fadeOut")
    $CollisionShape.disabled = true
    $Particles.emitting = false
    $Particles2.emitting = false
    $Particles3.emitting = false
    $Particles4.emitting = false
    $Particles5.emitting = false
func appear() -> void: #appear to the player
    show()
    $CollisionShape.set_deferred("disabled",false)
    $Particles.emitting = true
    $Particles2.emitting = true
    $Particles3.emitting = true
    $Particles4.emitting = true
    $Particles5.emitting = true
func point() -> void: #point at the player
    look_at(get_parent().get_node("Player").global_transform.origin,Vector3.UP)
    rotation_degrees.x = 90
    rotation_degrees.y += 180
    $AnimationPlayer.play("Point")
func lurch() -> void: #quickly move toward the player
    speed = lurchSpeed
    targetPosition = get_parent().get_node("Player").global_transform.origin
    look_at(get_parent().get_node("Player").global_transform.origin,Vector3.UP)
    rotation_degrees.x = 90
    rotation_degrees.y += 180
    set_physics_process(true)
func slow() -> void: #slow movement
    if speed != lurchSpeed:
        speed = slowSpeed
func collide(direction) -> void: #check for collisions
    for i in range(get_slide_count()):
        var collision := get_slide_collision(i)
        if collision != null:
            var body := collision.collider
            if body.has_method("playerHit"):
                if speed == lurchSpeed:
                    fade()
                    body.playerHit(99)
                    body.velocity += direction*500
                    body.prone()
                    #body.rotation_degrees.z -= 40
                    #body.get_node("AnimationPlayer").play("FallRise")
                    body.get_node("CrunchSound").volume_db = -11
                    body.get_node("CrunchSound").play()
                    body.fallHeight = 0.0
                else:
                    body.playerHit(75)
                    body.velocity += direction*200
                return
            elif body.is_in_group("doors"):
                body.breakDownDoor()
                return #sound
func _on_AnimationPlayer_animation_finished(anim_name):
    if anim_name == "Point": #lurch after pointing
        lurch()
    elif anim_name == "Lurch": #fade out after lurching
        speed = walkSpeed
        fade()
