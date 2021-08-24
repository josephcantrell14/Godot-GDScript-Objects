extends KinematicBody

#Camera
var mouseSensitivity := 12.0
export(NodePath) var head_path
export(NodePath) var cam_path
const FOV := 87.0
var mouse_axis := Vector2()
onready var head :Spatial= get_node(head_path)
onready var cam :Camera= get_node(cam_path)
#Move
var velocity := Vector3()
var direction := Vector3()
var moveAxis := Vector2()
var immobilized := true
var ads := false
var sprinting := false
const sprintTimeInit :float= 3.7
var sprintTime :float= sprintTimeInit
var crouched := false
var prone := false
var crouchHeight :float= 0
var proneHeight :float= 0
var proneCrouchHeight :float= 0
var crouchRise := true
var proneRise := true
var surface :int= 0 #used for footsteps
var cover := false  #taking cover from demons
var scanning := false  #raycast for sighting reactions
#Walk
const FLOOR_NORMAL := Vector3(0,1,0)
const FLOOR_MAX_ANGLE :float= deg2rad(40.0)
const gravityVelocity := 68.0
var gravity := gravityVelocity
var walkVelocity := 26
var walkSpeed := walkVelocity
var sprintSpeed := 52
var acceleration := 12
var deacceleration := 20
var jumpHeight := 41
var airControl := .25
var fallHeight := 0.0
var flashlightRange := 110
var flashlightOCRange := 220
#export(float, 0.0, 1.0, 0.05) var airControl = 0.3
#Fly
var flySpeed := 10
var flyAccel := 4
var flying := false
#Stats
var alive := false
var maxHP := 100
var hp := 0
var invincible := false
#Positions
const startPosition := Vector3(-286.8,20.7,704) #cabin bed
const frontDoorPosition := Vector3(-254,25,691)
const boxPosition := Vector3(-271.2,70,872.7)

func _ready() -> void:
    cam.fov = FOV
    crouchHeight = $Collision.shape.height - $CollisionCrouch.shape.height
    proneHeight = $Collision.shape.height - $CollisionProne.shape.height
    proneCrouchHeight = $CollisionCrouch.shape.height - $CollisionProne.shape.height
    set_physics_process(false)
func _input(event: InputEvent) -> void:
    if alive:
        if event is InputEventMouseMotion:
            mouse_axis = event.relative
            cameraRotation()
        elif get_parent().input == 2 and event is InputEventJoypadMotion:
            cameraRotationController()
        if Input.is_action_just_pressed("select"):
            select()
        elif Input.is_action_just_pressed("flashlight"):
            flashlight()
func _physics_process(delta:float) -> void:
    if not immobilized:
        var floored :bool= is_on_floor()
        move(delta,floored)
        if alive:
            moveAxis.x = Input.get_action_strength("moveForward") - Input.get_action_strength("moveBackward")
            moveAxis.y = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
            if scanning: #scan for reactions
                jumpScare()
            elif Input.is_action_pressed("aim"): #ADS
                ads(delta,floored)
                if $Head/Camera/Flashlight/FlashlightRayCast.enabled:
                    flashlightCollide(delta)
            else:
                hipfire(delta)
func start() -> void:
    set_physics_process(true)
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
    immobilized = false
    $Head/Camera/RayCast.cast_to = Vector3(0,0,-15)
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
func ads(delta:float, floored:bool) -> void:
    if not ads:
        ads = true
        get_parent().get_node("HUD/Reticle").hide()
        if $Head/Camera/Flashlight.visible:
            flashlightOverclock()
        if sprinting and floored:
            sprinting = false
    else:
        cam.set_fov(lerp(cam.fov,62,delta*6))
func select() -> void:
    var collision :Object= $Head/Camera/RayCast.get_collider()
    if collision:
        #print(str(collision.name.replace("@", "").replace(str(int(collision.name)), "")))
        if collision.is_in_group("doors"):
            if get_parent().get_node("HUD").storyProgress != 9: #no doors at ending (overcomes random locking glitch)
                collision.toggleDoor()
            else:
                collision.get_node("LockedSound").play()
            if collision.is_in_group("door1"):
                if get_parent().get_node("HUD").storyProgress == 0: #key room
                    get_parent().unlockDoor(2)
                elif get_parent().get_node("HUD").storyProgress == 2: #front door
                    get_parent().unlockDoor(1)
        elif collision.is_in_group("lights"):
            if not collision.is_in_group("flameLight1") and not collision.is_in_group("flameLight2"):
                collision.get_node("Light").visible = not collision.get_node("Light").visible
            elif collision.is_in_group("flameLight1") and not get_parent().flameLight1:
                collision.get_node("Light").show()
                collision.get_parent().get_node("Flame").emitting = true
                get_parent().flameLight1 = true
                if get_parent().flameLight1 and get_parent().flameLight2:
                    get_parent().atticActivateFlameDoor()
            elif collision.is_in_group("flameLight2") and not get_parent().flameLight2:
                collision.get_node("Light").show()
                collision.get_parent().get_node("Flame").emitting = true
                get_parent().flameLight2 = true
                if get_parent().flameLight1 and get_parent().flameLight2:
                    get_parent().atticActivateFlameDoor()
        elif collision.is_in_group("books"):
            var spark = preload("res://SparkExplosion.tscn").instance()
            get_parent().add_child(spark)
            spark.global_transform.origin = collision.global_transform.origin
            if collision.is_in_group("book5"):
                get_parent().severedHallwayDoor()
                $BookSound.play()
            elif collision.is_in_group("book13") and get_parent().get_node("HUD").storyProgress == 10:
                get_parent().outsideFarHoleFlame()
                var interest = get_parent().get_node("Audio/Interest")
                interest.stream = preload("res://Sounds/synthpluck-interest.wav")
                interest.volume_db = -20
                interest.play()
            elif collision.is_in_group("book14") and get_parent().get_node("HUD").storyProgress == 11:
                var cloud = preload("res://CholinergicCloud.tscn").instance()
                get_parent().add_child(cloud)
                cloud.global_transform.origin = Vector3(518,40,-555)
                get_parent().hideHoleIceWall()
                var interest = get_parent().get_node("Audio/Interest")
                interest.stream = preload("res://Sounds/synthpluck-interest-long.wav")
                interest.volume_db = -19
                interest.play()
            #elif collision.is_in_group("book8"):
                #get_parent().snow(15000)
            elif collision.is_in_group("book12"):
                get_parent().ending()
            else:
                $BookSound.play()
            for i in range(1,16): #numBooks+1
                var bookString :String= "book" + str(i)
                if collision.is_in_group(bookString):
                    get_parent().get_node("HUD").unlockBook(i)
                    break
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
    $Head/Camera/Flashlight.spot_range = flashlightOCRange
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
    $Head/Camera/Flashlight.spot_range = flashlightRange
    $Head/Camera/Flashlight/FlashlightOC.hide()
    $Head/Camera/Flashlight/FlashlightRayCast.enabled = false
func move(delta:float, floored:bool) -> void:
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
    if floored:
        snap = Vector3(0,-1,0)
        if fallHeight > 0:
            if fallHeight > 65:
                #print("fallen: " + str(fallHeight))
                var damage :float= (fallHeight-55)/85*100 #55-140 fall height
                #print("playerHit damage: " + str(damage))
                var fallVolume := fallHeight
                if fallVolume > 200:
                    fallVolume = 200
                $CrunchSound.volume_db = -10 + int(7*(fallVolume/140))
                $CrunchSound.play()
                playerHit(damage)
                velocity = Vector3()
            fallHeight = 0
        if Input.is_action_just_pressed("jump") and not crouched and not prone:
            snap = Vector3()
            velocity.y = jumpHeight
            $JumpSound.play()
        elif Input.is_action_just_pressed("crouch"):
            crouch(delta)
        elif Input.is_action_just_pressed("prone"):
            prone(delta)
        else:
            collide()
    velocity.y -= gravity*delta
    var playerSpeed: int
    if (Input.is_action_just_pressed("sprint") and canSprint() and moveAxis.x >= 0.5):
        playerSpeed = sprintSpeed
        cam.set_fov(lerp(cam.fov,FOV*1.06,delta*6))
        sprinting = true
        $AnimationPlayer.playback_speed = 2
        $FootstepsSound.pitch_scale = 1.4
    elif sprinting:
        playerSpeed = sprintSpeed
        sprintTime -= delta
        #$FootstepsSound.pitch_scale = 1.4
        if sprintTime <= 0:
            sprinting = false
            cam.set_fov(lerp(cam.fov,FOV,delta*6))
            sprintTime = 0
            $SprintTimer.start()
            $Head/Camera/ColdBreath.emitting = true
            $BreathSound.play()
            $FootstepsSound.pitch_scale = 1
            $AnimationPlayer.playback_speed = 1
        elif not Input.is_action_pressed("moveForward") or crouched or prone:
            sprinting = false
            cam.set_fov(lerp(cam.fov,FOV,delta*6))
            $FootstepsSound.pitch_scale = 1
            $AnimationPlayer.playback_speed = 1
    else:
        playerSpeed = walkSpeed
        sprintTime += delta
        #$FootstepsSound.pitch_scale = 1
        #$AnimationPlayer.playback_speed = 1
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
    if not floored:
        tempAcceleration *= airControl
        $FootstepsSound.stop()
    tempVelocity = tempVelocity.linear_interpolate(target,tempAcceleration*delta) #interpolation
    velocity.x = tempVelocity.x
    velocity.z = tempVelocity.z
    if direction.dot(velocity) == 0: #clamping (to stop on slopes)
        var _vel_clamp := 0.25
        if abs(velocity.x) < _vel_clamp:
            velocity.x = 0
        if abs(velocity.z) < _vel_clamp:
            velocity.z = 0
    var moving := move_and_slide_with_snap(velocity,snap,FLOOR_NORMAL,true,1,FLOOR_MAX_ANGLE) #Move
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
func collide() -> void: #KinematicBody collider collision
    if velocity.length() >= .2 and not prone:
        if not $AnimationPlayer.is_playing():
            if crouched:
                $AnimationPlayer.playback_speed = .54
            else:
                $AnimationPlayer.playback_speed = 1
            $AnimationPlayer.play("ViewBob")
        for i in range(get_slide_count()):
            var collision := get_slide_collision(i)
            if collision != null:
                if crouched:
                    $FootstepsSound.volume_db = -25
                else:
                    $FootstepsSound.volume_db = -16
                #var collisionDistance := global_transform.origin.y-collision.position.y
                var body := collision.collider
                if body.is_in_group("wood"):
                    if surface != 0:
                        surface = 0
                        $FootstepsSound.stream = preload("res://Sounds/footsteps.wav")
                    if not $FootstepsSound.is_playing():
                        $FootstepsSound.play()
                    return
                elif body.is_in_group("rock"):
                    if surface != 1:
                        surface = 1
                        $FootstepsSound.stream = preload("res://Sounds/footsteps.wav") #change
                    if not $FootstepsSound.is_playing():
                        $FootstepsSound.play()
                    return
                elif body.is_in_group("snow"):
                    if surface != 2:
                        surface = 2
                        $FootstepsSound.stream = preload("res://Sounds/footsteps-snow.wav") #change
                    if not $FootstepsSound.is_playing():
                        $FootstepsSound.play()
                    return
    else:
        $FootstepsSound.stop()
        if $AnimationPlayer.is_playing():
            $AnimationPlayer.stop()
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
            $AnimationPlayer.playback_speed = .6
    elif not crouched: #crouch from standing
        $Collision.disabled = true
        $CollisionCrouch.disabled = false
        gravity = 130
        walkSpeed = 14
        crouched = true
        cam.set_fov(lerp(cam.fov,80,delta*6))
        $AnimationPlayer.playback_speed = .6
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
    if alive and not invincible:
        invincible = true
        $InvincibleTimer.start()
        hp -= damage
        bleed(4.8*damage + 5)
        if hp > 0:
            $HitSound.play()
            $RecoveryStartTimer.start()
            ###hit accuracy loss?
        else:
            end()
            $EndSound.play()
func _on_InvincibleTimer_timeout() -> void:
    invincible = false
func end() -> void:
    hp = 0
    #velocity = Vector3()
    if not prone:
        prone()
    #rotation_degrees.z += 40
    alive = false
    get_parent().get_node("Timers/GameOverTimer").start()
func drown() -> void:
    if alive:
        end()
        velocity = Vector3(0,velocity.y/5,0)
        if velocity.y > 0:
            velocity.y = -2
        gravity = 2
        $DrownSound.play()
func bleed(amount) -> void:
    if amount > 480:
        amount = 480
    var lifetime :float= 3 + 3*((float(amount)/480))
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
    if not prone:
        prone()
    global_transform.origin = startPosition
    look_at(get_parent().get_node("House/Decor/NightstandBedroomFront/Lamp/Mesh").global_transform.origin,Vector3.UP)
func toBox() -> void:
    if prone: #stand up
        prone()
    elif crouched:
        crouch()
    global_transform.origin = boxPosition
    velocity = Vector3()
    look_at(global_transform.origin + Vector3(2,0,0),Vector3.UP)
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
    #rotation_degrees = Vector3()
    $RecoveryTimer.start() #time it with particles
func jumpScare() -> void:
    var collision :Object= $Head/Camera/RayCast.get_collider()
    if collision:
        if collision.is_in_group("wraiths"): #wraith adrenaline jump-scare
            scanning = false
            $Head/Camera/RayCast.cast_to = Vector3(0,0,-14)
            collision.point()
            Engine.time_scale = .4
            $SlowmoSound.play()
            $SlowmoTimer.start()
