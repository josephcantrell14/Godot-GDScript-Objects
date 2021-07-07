extends KinematicBody

#Camera
var mouseSensitivity := 12.0
export(NodePath) var head_path
export(NodePath) var cam_path
const FOV := 87.0
var mouse_axis := Vector2()
onready var head : Spatial = get_node(head_path)
onready var cam : Camera = get_node(cam_path)
#Move
var velocity := Vector3()
var direction := Vector3()
var moveAxis := Vector2()
var ads := false
var sprinting := false
const sprintTimeInit : int = 4
var sprintTime : float = sprintTimeInit
var crouched := false
var prone := false
var crouchHeight :float = 0
var proneHeight :float = 0
var proneCrouchHeight :float = 0
var crouchRise := true
var proneRise := true
var cover := false  #taking cover from demons
var scanning := false  #raycast for sighting reactions
#Walk
const FLOOR_NORMAL := Vector3(0,1,0)
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
const gravityVelocity := 68.0
var gravity := gravityVelocity
const walkVelocity := 26
var walkSpeed := walkVelocity
var sprintSpeed := 51
var acceleration := 12
var deacceleration := 20
var jumpHeight := 40
var airControl := .25
var fallHeight := 0.0
#export(float, 0.0, 1.0, 0.05) var airControl = 0.3
#Fly
var flySpeed := 10
var flyAccel := 4
var flying := false
#Stats
var alive := false
var maxHP := 100
var hp := 0
#Positions
const startPosition := Vector3(-286.8,20.7,704) #cabin bed
const frontDoorPosition := Vector3(-251,25,691)
const boxPosition := Vector3(-271.2,70,872.7)

func _ready() -> void:
    cam.fov = FOV
    crouchHeight = $Collision.shape.height - $CollisionCrouch.shape.height
    proneHeight = $Collision.shape.height - $CollisionProne.shape.height
    proneCrouchHeight = $CollisionCrouch.shape.height - $CollisionProne.shape.height
func _input(event: InputEvent) -> void:
    if alive:
        if event is InputEventMouseMotion:
            mouse_axis = event.relative
            cameraRotation()
        elif get_parent().input == 2 and event is InputEventJoypadMotion:
            cameraRotationController()
        if Input.is_action_just_pressed("select"):
            collide()
        elif Input.is_action_just_pressed("flashlight"):
            flashlight()
func _physics_process(delta:float) -> void:
    walk(delta)
    if alive:
        moveAxis.x = Input.get_action_strength("moveForward") - Input.get_action_strength("moveBackward")
        moveAxis.y = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
        if scanning: #scan for reactions
            jumpScare()
        elif Input.is_action_pressed("aim"): #ADS
            ads(delta)
            if $Head/Camera/Flashlight/FlashlightRayCast.enabled:
                flashlightCollide(delta)
        else:
            hipfire(delta)
func start() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    #$Head/Camera.current = true
    walkSpeed = walkVelocity
    velocity = Vector3()
    alive = true
    gravity = gravityVelocity
    fallHeight = 0
    sprintTime = sprintTimeInit
    crouchRise = true
    proneRise = true
    $Head/Camera/RayCast.cast_to = Vector3(0,0,-14)
    if $Head/Camera/Flashlight/FlashlightRayCast.enabled:
        disableFlashlightOverclock()
    if get_parent().debug:
        hp = 100
        maxHP = 100
    else:
        hp = 100
        maxHP = 100
func hipfire(delta: float) -> void:
    cam.set_fov(lerp(cam.fov,FOV,delta*6)) #set camera anyway
    if ads:
        get_parent().get_node("HUD/Reticle").show()
        ads = false
        disableFlashlightOverclock()
func ads(delta: float) -> void:
    if not ads:
        ads = true
        get_parent().get_node("HUD/Reticle").hide()
        if $Head/Camera/Flashlight.visible:
            flashlightOverclock()
        if sprinting and is_on_floor():
            sprinting = false
    else:
        cam.set_fov(lerp(cam.fov,60,delta*6))
func collide() -> void:
    var collision :Object= $Head/Camera/RayCast.get_collider()
    if collision:
        print(str(collision.name.replace("@", "").replace(str(int(collision.name)), "")))
        if collision.is_in_group("doors"):
            if get_parent().get_node("HUD").storyProgress != 8:
                collision.toggleDoor()
            else:
                collision.get_node("LockedSound").play()
            if collision.is_in_group("door1"):
                if get_parent().get_node("HUD").storyProgress == 0: #key room
                    get_parent().unlockDoor(2)
                elif get_parent().get_node("HUD").storyProgress == 2: #front door
                    get_parent().unlockDoor(1)
        elif collision.is_in_group("lights"):
            collision.get_node("Light").visible = not collision.get_node("Light").visible
        elif collision.is_in_group("books"):
            var spark = preload("res://SparkExplosion.tscn").instance()
            get_parent().add_child(spark)
            spark.global_transform.origin = collision.global_transform.origin
            if collision.is_in_group("book5"):
                get_parent().severedHallwayDoor()
            elif collision.is_in_group("book8"):
                get_parent().snow(3)
            elif collision.is_in_group("book12"):
                get_parent().ending()
            for i in range(1,10):
                var bookString :String= "book" + str(i)
                if collision.is_in_group(bookString):
                    get_parent().get_node("HUD").unlockBook(i)
            collision.hide()
            collision.get_node("Collision").disabled = true
        elif collision.is_in_group("keys"):
            if collision.is_in_group("key1"):
                scanning = true
                $Head/Camera/RayCast.cast_to = Vector3(0,0,-50) #change scanning raycast for jumpscare
                get_parent().keyShadow()
                collision.hide()
func flashlight() -> void:
    $Head/Camera/Flashlight.visible = not $Head/Camera/Flashlight.visible
    if ads:
        flashlightOverclock()
    elif $Head/Camera/Flashlight/FlashlightRayCast.enabled:
        disableFlashlightOverclock()
    $Head/Camera/Flashlight/FlashlightSound.play()
func flashlightOverclock() -> void:
    $Head/Camera/Flashlight.light_energy = 16
    $Head/Camera/Flashlight.spot_angle = 8
    $Head/Camera/Flashlight.spot_range = 160
    $Head/Camera/Flashlight/FlashlightOC.show()
    $Head/Camera/Flashlight/FlashlightRayCast.enabled = true
func flashlightCollide(delta:float) -> void:
    var collision :Object= $Head/Camera/Flashlight/FlashlightRayCast.get_collider()
    if collision:
        if collision.is_in_group("wraiths"):
            collision.slow()
        elif collision.is_in_group("cloud"):
            collision.damaged(delta)
func disableFlashlightOverclock() -> void:
    $Head/Camera/Flashlight.light_energy = 10
    $Head/Camera/Flashlight.spot_angle = 24
    $Head/Camera/Flashlight.spot_range = 80
    $Head/Camera/Flashlight/FlashlightOC.hide()
    $Head/Camera/Flashlight/FlashlightRayCast.enabled = false
func walk(delta: float) -> void:
    direction = Vector3() #Input
    var aim :Basis= get_global_transform().basis
    if moveAxis.x >= 0.5:
        direction -= aim.z
    if moveAxis.x <= -0.5:
        direction += aim.z
    if moveAxis.y <= -0.5:
        direction -= aim.x
    if moveAxis.y >= 0.5:
        direction += aim.x
    direction.y = 0
    direction = direction.normalized()
    var snap: Vector3 #Jump
    if is_on_floor():
        snap = Vector3(0,-1,0)
        if fallHeight > 0:
            if fallHeight > 50:
                #print("fallen: " + str(fallHeight))
                var damage :float= fallHeight-40
                #print("playerHit damage: " + str(damage))
                playerHit(damage) #50-150 fall height
                velocity.y = fallHeight/5
            fallHeight = 0
        if Input.is_action_just_pressed("jump") and not crouched and not prone:
            snap = Vector3()
            velocity.y = jumpHeight
            $JumpSound.play()
        elif Input.is_action_just_pressed("crouch"):
            crouch(delta)
        elif Input.is_action_just_pressed("prone"):
            prone(delta)
    velocity.y -= gravity*delta #Apply Gravity
    var playerSpeed: int #Sprint
    if (Input.is_action_just_pressed("sprint") and canSprint() and moveAxis.x >= 0.5):
        playerSpeed = sprintSpeed
        cam.set_fov(lerp(cam.fov,FOV*1.06,delta*6))
        sprinting = true
    elif sprinting:
        playerSpeed = sprintSpeed
        sprintTime -= delta
        if sprintTime <= 0:
            sprinting = false
            cam.set_fov(lerp(cam.fov,FOV,delta*6))
            sprintTime = 0
            $SprintTimer.start()
            $Head/Camera/ColdBreath.emitting = true
            $BreathSound.play()
        elif not Input.is_action_pressed("moveForward"):
            sprinting = false
            cam.set_fov(lerp(cam.fov,FOV,delta*6))
    else:
        playerSpeed = walkSpeed
        sprintTime += delta
        if sprintTime > sprintTimeInit:
            sprintTime = sprintTimeInit
    var tempVelocity :Vector3= velocity  #Acceleration and Deacceleration
    tempVelocity.y = 0
    var target :Vector3= direction*playerSpeed
    var tempAcceleration: float
    if direction.dot(tempVelocity) > 0:
        tempAcceleration = acceleration
    else:
        tempAcceleration = deacceleration
    if not is_on_floor():
        tempAcceleration *= airControl
    tempVelocity = tempVelocity.linear_interpolate(target,tempAcceleration*delta) #interpolation
    velocity.x = tempVelocity.x
    velocity.z = tempVelocity.z
    if direction.dot(velocity) == 0: #clamping (to stop on slopes)
        var _vel_clamp := 0.25
        if abs(velocity.x) < _vel_clamp:
            velocity.x = 0
        if abs(velocity.z) < _vel_clamp:
            velocity.z = 0
    var moving := move_and_slide_with_snap(velocity,snap,FLOOR_NORMAL,true,4,FLOOR_MAX_ANGLE) #Move
    if is_on_wall():
        velocity = moving
    else:
        velocity.y = moving.y
    fallHeight += delta*abs(velocity.y)
func fly(delta: float) -> void:
    direction = Vector3()
    var aim := head.get_global_transform().basis
    if moveAxis.x >= 0.5:
        direction -= aim.z
    if moveAxis.x <= -0.5:
        direction += aim.z
    if moveAxis.y <= -0.5:
        direction -= aim.x
    if moveAxis.y >= 0.5:
        direction += aim.x
    direction = direction.normalized()
    var target :Vector3= direction*flySpeed
    velocity = velocity.linear_interpolate(target,flyAccel*delta)
    velocity = move_and_slide(velocity)
func cameraRotation() -> void:
    if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
        return
    elif mouse_axis.length() > 0:
        var horizontal :float= -mouse_axis.x * (mouseSensitivity/100)
        var vertical :float= -mouse_axis.y * (mouseSensitivity/100)
        mouse_axis = Vector2()
        rotate_y(deg2rad(horizontal))
        head.rotate_x(deg2rad(vertical))
        var temp_rot :Vector3= head.rotation_degrees  #Clamp mouse rotation
        temp_rot.x = clamp(temp_rot.x,-90,90)
        head.rotation_degrees = temp_rot
func cameraRotationController() -> void:
    var horizontal := Input.get_action_strength("lookRight") - Input.get_action_strength("lookLeft")
    var vertical := Input.get_action_strength("lookUp") - Input.get_action_strength("lookDown")
    if get_parent().get_node("HUD/InputMapPopup/Rect/InvertedY/InvertedYCheckbox").pressed:
        vertical *= -1
    if vertical > 0 or horizontal > 0:
        rotate_y(deg2rad(horizontal))
        head.rotate_x(deg2rad(vertical))
        var temp_rot :Vector3= head.rotation_degrees  #Clamp mouse rotation
        temp_rot.x = clamp(temp_rot.x,-90,90)
        head.rotation_degrees = temp_rot
func canSprint() -> bool:
    return (is_on_floor() and $SprintTimer.is_stopped() and not ads and not crouched and not prone)
func crouch(delta=.03) -> void:
    if prone: #crouch from prone
        if proneRise:
            prone = false
            crouched = true
            gravity = gravityVelocity
            walkSpeed = 14
            cam.set_fov(lerp(cam.fov,80,delta*6))
            $CollisionCrouch.disabled = false
            $CollisionProne.disabled = true
            global_transform.origin.y += proneCrouchHeight
    elif not crouched: #crouch from standing
        $Collision.disabled = true
        $CollisionCrouch.disabled = false
        gravity = 130
        walkSpeed = 14
        crouched = true
        cam.set_fov(lerp(cam.fov,80,delta*6))
    elif crouchRise: #stand from crouched
        $Collision.disabled = false
        $CollisionCrouch.disabled = true
        crouched = false
        #$Head.global_transform.origin.y += crouchHeight
        global_transform.origin.y += crouchHeight
        gravity = gravityVelocity
        walkSpeed = walkVelocity
        cam.set_fov(lerp(cam.fov,FOV,delta*6))
func prone(delta=.03) -> void:
    if crouched: #prone from crouched
        crouched = false
        prone = true
        $CollisionCrouch.disabled = true
        $CollisionProne.disabled = false
        global_transform.origin.y -= proneCrouchHeight
        walkSpeed = 8
        cam.set_fov(lerp(cam.fov,75,delta*6))
    elif not prone: #prone from standing
        $CollisionProne.disabled = false
        $Collision.disabled = true
        prone = true
        #$Head.global_transform.origin.y += proneHeight
        gravity = 180
        walkSpeed = 8
        cam.set_fov(lerp(cam.fov,75,delta*6))
    elif proneRise: #stand from prone
        $CollisionProne.disabled = true
        $Collision.disabled = false
        prone = false
        global_transform.origin.y += proneHeight
        gravity = gravityVelocity
        walkSpeed = walkVelocity
        cam.set_fov(lerp(cam.fov,FOV,delta*6))
func canRise(height:float) -> bool:
    var spaceState := get_world().direct_space_state
    var collisionObject :Dictionary= spaceState.intersect_ray($Head/Camera.global_transform.origin,$Head/Camera.global_transform.origin+Vector3(0,height+1.3,0),[self])
    if collisionObject:
        return (collisionObject.collider == null)
    else:
        return true
func playerHit(damage) -> void:
    if alive:
        print("player damage: " + str(damage))
        hp -= damage
        bleed(5*damage + 5)
        if hp > 0:
            $HitSound.play()
            $RecoveryStartTimer.start()
            ###hit accuracy loss?
        else:
            end()
            $EndSound.play()
func end() -> void:
    hp = 0
    velocity = Vector3()
    prone()
    rotation_degrees.z += 40
    alive = false
    get_parent().get_node("Timers/GameOverTimer").start()
func drown() -> void:
    end()
    velocity /= 10
    gravity = 2
    #prone()
    #splash sound?
    #$DrownSound.play() #blow bubbles in bowl of water
func bleed(amount) -> void:
    var lifetime :float= 3 + 3*((float(amount)/500))
    #print(str(amount) + " " + str(lifetime))
    get_parent().get_node("HUD/Blood").show()
    get_parent().get_node("HUD/Blood/Particles").amount = amount
    get_parent().get_node("HUD/Blood/Particles").lifetime = lifetime
    get_parent().get_node("HUD/Blood/Particles").emitting = true
    get_parent().get_node("HUD/Blood/Particles2").amount = amount
    get_parent().get_node("HUD/Blood/Particles2").lifetime = lifetime
    get_parent().get_node("HUD/Blood/Particles2").emitting = true
    #print(str(lifetime) + "s for " + str(amount))
func toBed() -> void: #teleport to bed
    prone()
    global_transform.origin = startPosition
    look_at(get_parent().get_node("House/Decor/NightstandBedroomFront/Lamp/Mesh").global_transform.origin,Vector3.UP)
func toBox() -> void:
    if prone: #stand up
        prone()
    elif crouched:
        crouch()
    global_transform.origin = boxPosition
    look_at(get_tree().get_nodes_in_group("box")[0].get_node("Nightstand/Lamp/Light").global_transform.origin,Vector3.UP)
    get_tree().get_nodes_in_group("box")[0].get_node("Nightstand/Lamp/Light").show()
func toFrontDoor() -> void:
    if prone:
        prone()
    elif crouched:
        crouch()
    global_transform.origin = frontDoorPosition
func _on_SlowmoTimer_timeout():
    Engine.time_scale = 1
func _on_RecoveryTimer_timeout() -> void:
    hp += 25
    if hp >= maxHP:
        get_parent().get_node("HUD/Blood").hide()
        hp = maxHP
        $RecoveryTimer.stop()
func _on_RecoveryStartTimer_timeout() -> void:
    rotation_degrees = Vector3()
    $RecoveryTimer.start() #time it with particles
func jumpScare() -> void:
    var collision :Object= $Head/Camera/RayCast.get_collider()
    if collision:
        if collision.is_in_group("wraiths"): #wraith adrenaline jump-scare
            $Head/Camera/RayCast.cast_to = Vector3(0,0,-14)
            scanning = false
            collision.point()
            Engine.time_scale = .4
            $SlowmoSound.play()
            $SlowmoTimer.start()
