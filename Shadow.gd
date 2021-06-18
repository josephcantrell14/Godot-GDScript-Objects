extends KinematicBody

var hunting := false
var velocity := 27
var targetPosition = Vector3()
var previousJunction = Vector3()

func _physics_process(delta): #runs at a fixed interval of milliseconds
    if hunting:
        var targetVector = (targetPosition-global_transform.origin)
        targetVector.y = 0
        var movement = velocity*delta*(targetVector.normalized())
        global_transform.origin += movement
        look_at(targetPosition,Vector3.UP)
        rotation_degrees.x = 90
        if global_transform.origin.distance_to(targetPosition) < 1: #new goal
            AStar()
func _on_RaycastTimer_timeout(): #AStar calculations every 5 seconds because of a changing algorithm goal (moving target)
    AStar()
    var spaceState = get_world().direct_space_state
    var collisionObject = spaceState.intersect_ray(global_transform.origin,global_transform.origin + Vector3(10,10,-5),[self]) #door detection
    var collision = null
    if collisionObject:
        collision = collisionObject.collider
    if collision and collision.is_in_group("doors") and collision.closed:
        collision.breakDownDoor()
func AStar() -> void: #move to the node in a graph with the lowest cost of reaching the goal
    var playerPosition
    var junctions = get_tree().get_nodes_in_group("junctions")
    if get_parent().get_node("Player").cover:
        playerPosition = junctions[randi()%len(junctions)].global_transform.origin  #navigate to random junction when player is in cover
    else:
        playerPosition = get_parent().get_node("Player").global_transform.origin
    var spaceState = get_world().direct_space_state
    var collisionObject = spaceState.intersect_ray(global_transform.origin,playerPosition,[self])
    var collision = null
    if collisionObject:
        collision = collisionObject.collider
    if collision:
        #print(str(collision.name.replace("@", "").replace(str(int(collision.name)), "")))
        if collision.is_in_group("Player"):
            targetPosition = playerPosition #ignore graph nodes and go straight to player if the player is in sight
        else: #move along graph of nodes until player is in sight
            var bestJunction = targetPosition
            var bestJunctionCost = INF
            for junctionNode in junctions: #check each junction's viability and cost
                var junction = junctionNode.global_transform.origin
                var junctionDistance = global_transform.origin.distance_to(junction)
                if junction == targetPosition and junctionDistance < 1:
                    continue
                var junctionRayCastObject = spaceState.intersect_ray(global_transform.origin,junction,[self])
                if not junctionRayCastObject or not junctionRayCastObject.collider: #if a visible path to junction exists (viable neighbor)
                    var cost = junctionDistance + abs(junction.x-playerPosition.x) + abs(junction.z-playerPosition.z)#junction.distance_to(playerPosition) #cost of moving to junction with additional heuristic of linear player distance
                    if cost < bestJunctionCost:
                        bestJunctionCost = cost
                        bestJunction = junction
                #else:
                    #print("junctionObject: " + str(junctionRayCastObject.collider.name.replace("@", "").replace(str(int(junctionRayCastObject.collider.name)), "")) + str(junctionRayCastObject.position) + " orig: " +  str(global_transform.origin) + " junction: " + str(junction))
            if bestJunction != targetPosition:
                previousJunction = targetPosition
                targetPosition = bestJunction
                #print("target: " + str(targetPosition))
func hunt() -> void: #seek the player
    hunting = true
    $RaycastTimer.start()
func guard(): #stay still
    hunting = false
    $RaycastTimer.stop()
func fade() -> void: #fade out of sight
    guard()
    hide()
    $AnimationPlayer.play("fadeOut")
    $CollisionShape.set_deferred("disabled",true)
    $Particles.emitting = false
    $Particles2.emitting = false
    $Particles3.emitting = false
    $Particles4.emitting = false
    $Particles5.emitting = false
func appear() -> void: #appear to the player
    show()
    $CollisionShape.set_deferred("disabled",false)
    AStar()
    $Particles.emitting = true
    $Particles2.emitting = true
    $Particles3.emitting = true
    $Particles4.emitting = true
    $Particles5.emitting = true
func collide(direction) -> void: #check for collision with the player
    for i in range(get_slide_count()):
        var collision = get_slide_collision(i)
        if collision != null:
            var body = collision.collider
            if body.has_method("playerHit"):
                body.playerHit(50)
                body.velocity += direction*200
