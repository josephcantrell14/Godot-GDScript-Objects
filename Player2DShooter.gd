extends KinematicBody2D

signal end

onready var BulletScene = preload("res://bullet.tscn")
const ShotgunBulletScene = preload("res://ShotgunBlast.tscn")
const LauncherBulletScene = preload("res://launcherBullet.tscn")
const BlastScene = preload("res://Blast.tscn")
const FlameBulletScene = preload("res://FlameBullet.tscn")
const StrikeScene = preload("res://Strike.tscn")
const FlameScene = preload("res://Flame.tscn")

var hp = 0
var maxHP = 100
var equip = 0
var end = false

var life = 1
var weapon = 0
var run = 0
var slowmo = 0
var strike = 0
var flame = 0
var soul = 0
var ascent = 0
var paint = 0
var skin = 1

onready var joystick
onready var joystick2
const joystickDeadzone = 0.4
const gravity = Vector2(0,900)
const floorNormal = Vector2(0,-1)
const slopeStop = 25.0
const minAirTime = 0.1
const sidingChangeSpeed = 10
const pistolVelocity = 2300
const m4Velocity = 1700
const shotgunVelocity = 1200
const launcherVelocity = 900
var walkSpeed = 300
var jumpSpeed = 450
var linearVelocity = Vector2()
var airTime = 0
var floored = false

var shootTime = 99999 #time since last shot
const pistolShootTime = .42
const m4ShootTime = .16
const shotgunShootTime = .36
const launcherShootTime = .4
const railgunShootTime = .45
const fireRifleShootTime = .1

var slowmoUse = false
var slowmoScale = .45
var slowmoWaitTime = 32
var strikeUse = false
var strikeDamage = 275
var strikeWaitTime = 45
var flameUse = false
var flameDamage = 90
var flameWaitTime = 60
var soulDamage = 100
var soulUse = false
var soulWaitTime = 140

func _ready():
    $ui/Joystick.hide()
    $ui/Joystick2.hide()
func start(startPosition):
    if get_parent().input == 1:
        joystick = get_node("ui/Joystick");
        joystick2 = get_node("ui/Joystick2");
        joystick.show()
        joystick2.show()
    if get_parent().get_node("HUD").fps > 0:
        $ui/FPS.show()
    if get_parent().get_node("HUD").scoreAlpha > 0:
        $ui/Score.show()
    position = startPosition
    $Sprite.scale.x = -1
    walkSpeed = 300
    jumpSpeed = 450
    hp = 100
    maxHP = 100
    equip = 0
    end = false
    life = 1
    weapon = 0
    run = 0
    ascent = 0
    slowmo = 0
    slowmoScale = .45
    strike = 0
    strikeDamage = 275
    flame = 0
    flameDamage = 90
    soul = 0
    soulDamage = 100
    $SoulShieldTimer.wait_time = 1
    $SlowmoUseTimer.wait_time = 32
    $StrikeUseTimer.wait_time = 45
    $FlameUseTimer.wait_time = 60
    $SoulShieldUseTimer.wait_time = 140
    slowmoUse = false
    strikeUse = false
    flameUse = false
    soulUse = false
    get_parent().updateLifeBar(hp, maxHP)
    equipPistol()
    $Sprite.set_script(load("res://PlayerSpawnAnimation.gd"))
    $Sprite.set_process(true)
    show()
    $Sprite.show()
func _physics_process(delta):
    airTime += delta
    shootTime += delta
    linearVelocity += delta * gravity
    linearVelocity = move_and_slide(linearVelocity, floorNormal, slopeStop)
    if is_on_floor():
        airTime = 0
    floored = airTime < minAirTime
    var target_speed = 0 #Horizontal Movement
    if get_parent().input == 1: #Touchscreen
        var joy = Vector2()
        joy = joystick.joystick_vector
        if joy.x > joystickDeadzone:
            target_speed += -1
            walkAnim()
        elif joy.x < -joystickDeadzone:
            target_speed +=  1
            walkAnim()
        else:
            stopWalkAnim()
        target_speed *= walkSpeed
        linearVelocity.x = lerp(linearVelocity.x, target_speed, 0.1)
        if floored and joy.y >= .5:
            linearVelocity.y = -jumpSpeed
            walkAnim()
    else: #PC & Controller Horizontal Movement
        if Input.is_action_pressed("moveLeft"):
            target_speed += -1
            walkAnim()
        elif Input.is_action_pressed("moveRight"):
            target_speed +=  1
            walkAnim()
        else:
            stopWalkAnim()
        target_speed *= walkSpeed
        linearVelocity.x = lerp(linearVelocity.x, target_speed, 0.1)
        if floored and Input.is_action_just_pressed("jump"):
            linearVelocity.y = -jumpSpeed
            walkAnim()
        if Input.is_action_pressed("slowmo"):
            slowmo()
        elif Input.is_action_pressed("strike"):
            strike()
        elif Input.is_action_pressed("flame"):
            flame()
        elif Input.is_action_pressed("shield"):
            soulShield()
        elif Input.is_action_just_pressed("prevWeapon"):
            get_parent().get_node("HUD")._on_WeaponLeftButton_pressed()
        elif Input.is_action_just_pressed("nextWeapon"):
            get_parent().get_node("HUD")._on_WeaponRightButton_pressed()
    if get_parent().input == 1: #Mobile shooting
        rotateWeaponTouch()
        shootTouch()
    elif get_parent().input == 2: #Controller
        rotateWeaponController()
        shootController()
    else: #PC
        rotateWeapon()
        shoot()
func walkAnim():
    if not $Sprite/AnimationPlayer.is_playing():
        if skin == 5:
            $Sprite/AnimationPlayer.play("WalkGirl")
        elif skin == 2:
            $Sprite/AnimationPlayer.play("WalkTShirt")
        else:
            $Sprite/AnimationPlayer.play("WalkMan")
func stopWalkAnim():
    if $Sprite/AnimationPlayer.is_playing():
        if $Sprite/AnimationPlayer.current_animation_position <= .4: #reverse walking direction if cleanly possible
            if $Sprite/AnimationPlayer.current_animation == "WalkMan":
                $Sprite/AnimationPlayer.play_backwards("WalkMan")
            elif $Sprite/AnimationPlayer.current_animation == "WalkGirl":
                $Sprite/AnimationPlayer.play_backwards("WalkGirl")
            else:
                $Sprite/AnimationPlayer.play_backwards("WalkTShirt")
        elif $Sprite/AnimationPlayer.current_animation_position > .4 and $Sprite/AnimationPlayer.current_animation_position < 1.2:
            $Sprite/AnimationPlayer.stop()
            setHair(skin)
            $Sprite/LegLeft.rotation_degrees = 0
            $Sprite/LegRight.rotation_degrees = 0
            """if skin < 5: #old algorithm to reset body part positions
                #$Sprite/LegLeft.position = Vector2(-47,131)
                $Sprite/LegLeft.rotation_degrees = 0
                #$Sprite/LegRight.position = Vector2(18,131)
                $Sprite/LegRight.rotation_degrees = 0
            else:
                #$Sprite/LegLeft.position = Vector2(-47.4,130)
                $Sprite/LegLeft.rotation_degrees = 0
                #$Sprite/LegRight.position = Vector2(20.7,130)
                $Sprite/LegRight.rotation_degrees = 0
                #$Sprite/Torso.position = Vector2(-53,60.2)"""
func rotateWeapon():
    var start = $Sprite/RightArm.global_position
    var end = get_global_mouse_position()
    var angle = start.angle_to_point(end)
    if end.x < position.x:
        $Sprite.scale.x = -1
        $Sprite/RightArm/Weapon.scale.x = 1
        angle *= -1
    else:
        $Sprite.scale.x = 1
        angle += PI
    $Sprite/RightArm.rotation = angle
    $Sprite/LeftArm.rotation = angle
func rotateWeaponTouch():
    var joy2 = joystick2.joystick_vector
    var angle = Vector2().angle_to_point(joy2)
    if joy2.x > 0:
        $Sprite.scale.x = -1
        $Sprite/RightArm/Weapon.scale.x = 1
        angle *= -1
        angle += PI
    elif joy2.x < 0:
        $Sprite.scale.x = 1
    $Sprite/RightArm.rotation = angle
    $Sprite/LeftArm.rotation = angle
func rotateWeaponController():
    var joy2 = Vector2(Input.get_action_strength("shootright")-Input.get_action_strength("shootleft"),Input.get_action_strength("shootup")-Input.get_action_strength("shootdown"))
    var angle = Vector2().angle_to_point(joy2)
    if joy2.x > 0:
        $Sprite.scale.x = 1
        $Sprite/RightArm/Weapon.scale.x = 1
        angle *= -1
        angle += PI
    elif joy2.x < 0:
        $Sprite.scale.x = -1
    $Sprite/RightArm.rotation = angle
    $Sprite/LeftArm.rotation = angle
func shoot():
    match equip:
        0: if shootTime > pistolShootTime and Input.is_action_pressed("shoot"):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                var vector = get_global_mouse_position()-bullet.position
                bullet.velocity = vector/vector.length() * pistolVelocity
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                shootTime = 0
                $Sprite/RightArm/Weapon/Sound.play()
        1: if shootTime > m4ShootTime and Input.is_action_pressed("shoot"):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                var vector = get_global_mouse_position()-bullet.position
                bullet.velocity = vector/vector.length() * m4Velocity
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        2: if shootTime > shotgunShootTime and Input.is_action_pressed("shoot"):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = ShotgunBulletScene.instance()
                var bullet2 = ShotgunBulletScene.instance()
                var bullet3 = ShotgunBulletScene.instance()
                var bullet4 = ShotgunBulletScene.instance()
                get_parent().add_child(bullet)
                get_parent().add_child(bullet2)
                get_parent().add_child(bullet3)
                get_parent().add_child(bullet4)
                var shotgunPosition = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.position = shotgunPosition
                bullet2.position = shotgunPosition + Vector2(-100*$Sprite.scale.x,0)
                bullet3.position = shotgunPosition
                bullet4.position = shotgunPosition
                var vector = get_global_mouse_position() - bullet.position
                var shotVel = vector / vector.length() * shotgunVelocity
                bullet.velocity = shotVel
                bullet2.velocity = shotVel
                bullet3.velocity = shotVel + Vector2(0,-240)
                bullet4.velocity = shotVel + Vector2(0,240)
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                bullet2.rotation = bullet.rotation
                bullet3.rotation = bullet.rotation
                bullet4.rotation = bullet.rotation
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        3: if shootTime > launcherShootTime and Input.is_action_pressed("shoot"):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = LauncherBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                var vector = get_global_mouse_position() - bullet.position
                bullet.velocity = vector / vector.length() * launcherVelocity
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        4: if shootTime > railgunShootTime and Input.is_action_pressed("shoot"):
                var bullet = BlastScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                if $Sprite.scale.x == 1:
                    bullet.scale.y = -1
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        5: if shootTime > fireRifleShootTime and Input.is_action_pressed("shoot"):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = FlameBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                var vector = get_global_mouse_position()-bullet.position
                bullet.velocity = vector/vector.length()*m4Velocity
                bullet.rotation = bullet.position.angle_to_point(get_global_mouse_position())
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
func shootTouch():
    var joy2 = joystick2.joystick_vector
    joy2 *= -1
    match equip:
        0: if shootTime > pistolShootTime and joy2.length() > joystickDeadzone:
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*pistolVelocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                shootTime = 0
                $Sprite/RightArm/Weapon/Sound.play()
                #bullet.add_collision_exception_with(self) # don't want player to collide with bullet
        1: if shootTime > m4ShootTime and joy2.length() > joystickDeadzone:
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*m4Velocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        2: if shootTime > shotgunShootTime and joy2.length() > joystickDeadzone:
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = ShotgunBulletScene.instance()
                var bullet2 = ShotgunBulletScene.instance()
                var bullet3 = ShotgunBulletScene.instance()
                var bullet4 = ShotgunBulletScene.instance()
                get_parent().add_child(bullet)
                get_parent().add_child(bullet2)
                get_parent().add_child(bullet3)
                get_parent().add_child(bullet4)
                var shotgunPosition = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.position = shotgunPosition
                bullet2.position = shotgunPosition + Vector2(-100*$Sprite.scale.x,0)
                bullet3.position = shotgunPosition
                bullet4.position = shotgunPosition
                bullet.velocity = joy2*shotgunVelocity
                bullet2.velocity = bullet.velocity
                bullet3.velocity = bullet.velocity + Vector2(0,-240)
                bullet4.velocity = bullet.velocity + Vector2(0,240)
                bullet.rotation = Vector2().angle_to_point(joy2)
                bullet2.rotation = bullet.rotation
                bullet3.rotation = bullet.rotation
                bullet4.rotation = bullet.rotation
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        3: if shootTime > launcherShootTime and joy2.length() > joystickDeadzone:
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = LauncherBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*launcherVelocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        4: if shootTime > railgunShootTime and joy2.length() > joystickDeadzone:
                var bullet = BlastScene.instance()
                get_parent().add_child(bullet)
                if $Sprite.scale.x == 1:
                    bullet.scale.y = -1
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        5: if shootTime > fireRifleShootTime and joy2.length() > joystickDeadzone:
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = FlameBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*m4Velocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
func shootController():
    rotateWeaponController()
    var joy2 = Vector2(Input.get_action_strength("shootright")-Input.get_action_strength("shootleft"),Input.get_action_strength("shootdown")-Input.get_action_strength("shootup"))
    match equip:
        0: if shootTime > pistolShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*pistolVelocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                shootTime = 0
                $Sprite/RightArm/Weapon/Sound.play()
                #bullet.add_collision_exception_with(self) # don't want player to collide with bullet
        1: if shootTime > m4ShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = BulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*m4Velocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        2: if shootTime > shotgunShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = ShotgunBulletScene.instance()
                var bullet2 = ShotgunBulletScene.instance()
                var bullet3 = ShotgunBulletScene.instance()
                var bullet4 = ShotgunBulletScene.instance()
                get_parent().add_child(bullet)
                get_parent().add_child(bullet2)
                get_parent().add_child(bullet3)
                get_parent().add_child(bullet4)
                var shotgunPosition = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.position = shotgunPosition
                bullet2.position = shotgunPosition + Vector2(-100*$Sprite.scale.x,0)
                bullet3.position = shotgunPosition
                bullet4.position = shotgunPosition
                bullet.velocity = joy2*shotgunVelocity
                bullet2.velocity = bullet.velocity
                bullet3.velocity = bullet.velocity + Vector2(0,-240)
                bullet4.velocity = bullet.velocity + Vector2(0,240)
                bullet.rotation = Vector2().angle_to_point(joy2)
                bullet2.rotation = bullet.rotation
                bullet3.rotation = bullet.rotation
                bullet4.rotation = bullet.rotation
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        3: if shootTime > launcherShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = LauncherBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*launcherVelocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        4: if shootTime > railgunShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                var bullet = BlastScene.instance()
                get_parent().add_child(bullet)
                if $Sprite.scale.x == 1:
                    bullet.scale.y = -1
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
        5: if shootTime > fireRifleShootTime and (Input.is_action_pressed("shootright") or Input.is_action_pressed("shootup") or Input.is_action_pressed("shootleft") or Input.is_action_pressed("shootdown")):
                $Sprite/RightArm/Weapon/Sparks.emitting = true
                var bullet = FlameBulletScene.instance()
                get_parent().add_child(bullet)
                bullet.position = $Sprite/RightArm/Weapon/WeaponPosition.global_position
                bullet.velocity = joy2*m4Velocity
                bullet.rotation = Vector2().angle_to_point(joy2)
                $Sprite/RightArm/Weapon/Sound.play()
                shootTime = 0
func playerHit(damage, translation):
    if $SoulShieldTimer.is_stopped() == true:
        if get_parent().mode != 2:
            hp -= damage
        else:
            hp -= damage/2
        if hp > 0:
            linearVelocity += translation
            $HitSound.play()
            $EndParticles.lifetime = .6
            $EndParticles.emitting = true
            if skin < 5:
                $Sprite/Head.texture = preload("res://Sprites/Characters/Player/PlayerHeadInjured.png")
            else:
                $Sprite/Head.texture = load("res://Sprites/Characters/Player/Girl/HeadInjured.png")
        else:
            #return #invincible!
            hp = 0
            end()
        get_parent().updateLifeBar(hp, maxHP)
func _on_HitSound_finished():
    if skin < 5:
        $Sprite/Head.texture = preload("res://Sprites/Characters/Player/PlayerHead.png")
    else:
        $Sprite/Head.texture = load("res://Sprites/Characters/Player/Girl/Head.png")
func end():
    if end == false:
        hp = 0
        end = true
        emit_signal("end")
        $Sprite.hide()
        $EndSound.play()
        linearVelocity += Vector2(0,-420)
        $EndParticles.lifetime = 1
        $EndParticles.emitting = true
        $ui/Joystick.hide()
        $ui/Joystick2.hide()
        $ui/FPS.hide()
        $ui/Score.hide()
        walkSpeed = 0
func upgradeLife():
    life += 1
    hp = 100 * life
    maxHP = 100 * life
    get_parent().updateLifeBar(hp, maxHP)
func upgradeWeapon():
    weapon += 1
    if weapon == 1:
        equipM4()
        get_parent().get_node("HUD/WeaponRightButton").show()
        get_parent().get_node("HUD/WeaponLeftButton").show()
    elif weapon == 2:
        equipShotgun()
    elif weapon == 3:
        equipLauncher()
    elif weapon == 4:
        equipRailgun()
    elif weapon == 5:
        equipFireRifle()
    get_parent().get_node("HUD").setWeaponDamages(weapon)
func upgradeRun():
    run += 1
    walkSpeed = 300 + run*50
func upgradeSlowmo():
    slowmo += 1
    _on_SlowmoUseTimer_timeout()
    $SlowmoUseTimer.stop()
    _on_RechargeTimer_timeout()
    if slowmo == 2:
        slowmoWaitTime = 30
        $SlowmoUseTimer.wait_time = slowmoWaitTime
        slowmoScale = .4
    elif slowmo == 3:
        slowmoWaitTime = 28
        $SlowmoUseTimer.wait_time = slowmoWaitTime
        slowmoScale = .35
    elif slowmo == 4:
        slowmoWaitTime = 26
        $SlowmoUseTimer.wait_time = slowmoWaitTime
        slowmoScale = .3
    elif slowmo == 5:
        slowmoWaitTime = 23
        $SlowmoUseTimer.wait_time = slowmoWaitTime
        slowmoScale = .25
    elif slowmo == 6:
        slowmoWaitTime = 20
        $SlowmoUseTimer.wait_time = slowmoWaitTime
        slowmoScale = .2
func upgradeStrike():
    strike += 1
    _on_StrikeUseTimer_timeout()
    $StrikeUseTimer.stop()
    _on_RechargeTimer_timeout()
    if strike == 2:
        strikeDamage = 600
        strikeWaitTime = 41
        $StrikeUseTimer.wait_time = strikeWaitTime
    elif strike == 3:
        strikeDamage = 1000
        strikeWaitTime = 37
        $StrikeUseTimer.wait_time = strikeWaitTime
    elif strike == 4:
        strikeDamage = 1600
        strikeWaitTime = 33
        $StrikeUseTimer.wait_time = strikeWaitTime
    elif strike == 5:
        strikeDamage = 2500
        strikeWaitTime = 28
        $StrikeUseTimer.wait_time = strikeWaitTime
    elif strike == 6:
        strikeDamage = 4200
        strikeWaitTime = 23
        $StrikeUseTimer.wait_time = strikeWaitTime
func upgradeFlame():
    flame += 1
    _on_FlameUseTimer_timeout()
    $FlameUseTimer.stop()
    _on_RechargeTimer_timeout()
    if flame == 2:
        flameDamage = 200
        flameWaitTime = 55
        $FlameUseTimer.wait_time = flameWaitTime
    elif flame == 3:
        flameDamage = 350
        flameWaitTime = 50
        $FlameUseTimer.wait_time = flameWaitTime
    elif flame == 4:
        flameDamage = 525
        flameWaitTime = 45
        $FlameUseTimer.wait_time = flameWaitTime
    elif flame == 5:
        flameDamage = 750
        flameWaitTime = 39
        $FlameUseTimer.wait_time = flameWaitTime
    elif flame == 6:
        flameDamage = 1100
        flameWaitTime = 32
        $FlameUseTimer.wait_time = flameWaitTime
func upgradeSoulShield():
    soul += 1
    _on_SoulShieldUseTimer_timeout()
    $SoulShieldUseTimer.stop()
    _on_RechargeTimer_timeout()
    if soul == 2:
        $SoulShieldTimer.wait_time = 2
    elif soul == 3:
        soulWaitTime = 120
        $SoulShieldUseTimer.wait_time = soulWaitTime
    elif soul == 4:
        $SoulShieldTimer.wait_time = 3
    elif soul == 5:
        soulWaitTime = 100
        $SoulShieldUseTimer.wait_time = soulWaitTime
    elif soul == 6:
        $SoulShieldTimer.wait_time = 4
func upgradeAscent():
    ascent += 1
    jumpSpeed = 450 + 90*ascent
    #if alpha: #story mode has better jump upgrades
        #jumpSpeed += 112*ascent
    #if ascent == 2:
func equipPistol():
    equip = 0
    setPaint(get_parent().get_node("HUD").paintChoice,paint)
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/pistol.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -6
    $Sprite/RightArm/Weapon/Sparks.position = Vector2(28,-36)
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(6,-36)
    $Sprite/RightArm/Weapon.position = Vector2(234,-4)
func equipM4():
    equip = 1
    setPaint(get_parent().get_node("HUD").paintChoice,paint)
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/m4.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -7
    $Sprite/RightArm/Weapon/Sparks.position = Vector2(80,-26)
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(85,-27)
    $Sprite/RightArm/Weapon.position = Vector2(255,-3)
func equipShotgun():
    equip = 2
    setPaint(get_parent().get_node("HUD").paintChoice,paint)
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/shotgun.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -8
    $Sprite/RightArm/Weapon/Sparks.position = Vector2(122,-24)
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(100,-24)
    $Sprite/RightArm/Weapon.position = Vector2(230,-20)
func equipLauncher():
    equip = 3
    setPaint(get_parent().get_node("HUD").paintChoice,paint)
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/rpg.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -7
    $Sprite/RightArm/Weapon/Sparks.position = Vector2(172,-22)
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(150,-22)
    $Sprite/RightArm/Weapon.position = Vector2(183,-12)
func equipRailgun():
    equip = 4
    setPaint(get_parent().get_node("HUD").paintChoice,paint)
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/laser.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -7
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(80,-22)
    $Sprite/RightArm/Weapon.position = Vector2(210,-4)
func equipFireRifle():
    equip = 5
    $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/fireRifle.png")
    $Sprite/RightArm/Weapon/Sound.stream = load("res://Sounds/fireRifle.wav")
    $Sprite/RightArm/Weapon/Sound.volume_db = -5
    $Sprite/RightArm/Weapon/Sparks.position = Vector2(102,-26)
    $Sprite/RightArm/Weapon/WeaponPosition.position = Vector2(80,-26)
    $Sprite/RightArm/Weapon.position = Vector2(220,-10)
func slowmo():
    if slowmoUse:
        Engine.time_scale = slowmoScale
        $SlowmoTimer.start()
        slowmoUse = false
        $SlowmoSound.play()
        $SlowmoUseTimer.start()
        get_parent().get_node("HUD/SlowmoButton").modulate.a = .2
        get_parent().get_node("HUD/SlowmoButton/Glow").hide()
func _on_SlowMoTimer_timeout():
    Engine.time_scale = 1
func strike():
    if strikeUse:
        var strike = StrikeScene.instance()
        get_parent().call_deferred("add_child",strike)
        strike.position = Vector2(position.x, 410)
        strike.damage = strikeDamage
        $StrikeSound.play()
        strikeUse = false
        $StrikeUseTimer.start()
        get_parent().get_node("HUD/StrikeButton").modulate.a = .2
        get_parent().get_node("HUD/StrikeButton/Glow").hide()
func flame():
    if flameUse:
        var flame = FlameScene.instance()
        get_parent().call_deferred("add_child",flame)
        flame.position = position
        flame.velocity = Vector2(1000 * $Sprite.scale.x,0)
        flame.damage = flameDamage
        $FlameSound.play()
        flameUse = false
        $FlameUseTimer.start()
        get_parent().get_node("HUD/FlameButton").modulate.a = .2
        get_parent().get_node("HUD/FlameButton/Glow").hide()
func soulShield():
    if soulUse:
        soulUse = false
        $SoulShield.emitting = true
        $SoulShieldTimer.start()
        get_parent().get_node("HUD/ShieldButton").modulate.a = .2
        get_parent().get_node("HUD/ShieldButton/Glow").hide()
        $SoulShieldCollider/CollisionShape2DSoul.set_deferred("disabled", false)
func _on_SoulShieldCollider_area_entered(area):
    if area.has_method("hitByPlayer"):
        area.hitByPlayer(soulDamage*soul)
func _on_SoulShieldTimer_timeout():
    $SoulShield.emitting = false
    $SoulShieldCollider/CollisionShape2DSoul.set_deferred("disabled", true)
    $SoulShieldUseTimer.start()
func setHair(hair):
    skin = hair
    if hair < 5:
        $Sprite/Hair2.texture = null
        $Sprite/Head.texture = load("res://Sprites/Characters/Player/PlayerHead.png")
        $Sprite/Head.position = Vector2(-13.2,-133)
        $Sprite/LeftArm.position = Vector2(-63,-49)
        $Sprite/RightArm.position = Vector2(-69,-62)
        $Sprite/LegLeft.texture = load("res://Sprites/Characters/Player/Anime/Leg.png")
        $Sprite/LegLeft.position = Vector2(-47,131)
        $Sprite/LegRight.texture = load("res://Sprites/Characters/Player/Anime/Leg.png")
        $Sprite/LegRight.position = Vector2(18,131)
        $Sprite/Torso.z_index = 1
    if hair == 1:
        if get_parent().get_node("HUD").hairTheme[3] == -1:
            $Sprite/Hair.texture = load("res://Sprites/Characters/Player/Anime/Hair3.png")
            $Sprite/Hair.modulate = Color(1,1,1,1)
        else:
            $Sprite/Hair.texture = load("res://Sprites/Characters/Player/Anime/Hair2.png")
        $Sprite/Hair.position = Vector2(-6.2,-174.6)
        #$Sprite.offset = Vector2(1,98)
        $Sprite/Torso.texture = load("res://Sprites/Characters/Player/Anime/suit.png")
        $Sprite/Torso.position = Vector2(-20.6,-2.7)
        $Sprite/LeftArm.texture = load("res://Sprites/Characters/Player/Anime/Arm.png")
        $Sprite/RightArm.texture = load("res://Sprites/Characters/Player/Anime/Arm.png")
    elif hair == 2:
        $Sprite/Hair.texture = load("res://Sprites/Characters/Player/T-Shirt/Cap.png")
        $Sprite/Hair.modulate = Color(1,1,1,1)
        $Sprite/Hair.position = Vector2(-43,-190)
        #$Sprite.offset = Vector2(8,110)
        $Sprite/Torso.texture = load("res://Sprites/Characters/Player/T-Shirt/TShirt.png")
        $Sprite/Torso.position = Vector2(-9,23)
        $Sprite/LeftArm.texture = load("res://Sprites/Characters/Player/T-Shirt/ArmTShirt.png")
        $Sprite/RightArm.texture = load("res://Sprites/Characters/Player/T-Shirt/ArmTShirt.png")
        $Sprite/LegLeft.texture = load("res://Sprites/Characters/Player/T-Shirt/LegLeft.png")
        $Sprite/LegRight.texture = load("res://Sprites/Characters/Player/T-Shirt/LegRight.png")
        $Sprite/LegLeft.position = Vector2(-33,155)
        $Sprite/LegRight.position = Vector2(37,154)
    elif hair == 3:
        $Sprite/Hair.texture = load("res://Sprites/Characters/Player/King/crown.png")
        $Sprite/Hair.modulate = Color(1,1,1,1)
        $Sprite/Hair.position = Vector2(-16,-196)
        #$Sprite.offset = Vector2(1,98)
        $Sprite/Torso.texture = load("res://Sprites/Characters/Player/King/coat.png")
        $Sprite/Torso.position = Vector2(-5,56)
        $Sprite/LeftArm.texture = load("res://Sprites/Characters/Player/King/Arm.png")
        $Sprite/RightArm.texture = load("res://Sprites/Characters/Player/King/Arm.png")
    elif hair == 4:
        if get_parent().get_node("HUD").hairTheme[3] == -1:
            $Sprite/Hair.texture = load("res://Sprites/Characters/Player/Anime/Hair3.png")
            $Sprite/Hair.modulate = Color(1,1,1,1)
        else:
            $Sprite/Hair.texture = load("res://Sprites/Characters/Player/Anime/Hair2.png")
        $Sprite/Hair.position = Vector2(-6.2,-174.6)
        #$Sprite.offset = Vector2(1,98)
        $Sprite/Torso.texture = load("res://Sprites/Characters/Player/Ablaze/Ablaze.png")
        $Sprite/Torso.position = Vector2(-46,55)
        $Sprite/LeftArm.texture = load("res://Sprites/Characters/Player/Ablaze/Arm.png")
        $Sprite/RightArm.texture = load("res://Sprites/Characters/Player/Ablaze/Arm.png")
    elif hair == 5:
        $Sprite/Hair.texture = load("res://Sprites/Characters/Player/Girl/Hair.png")
        $Sprite/Hair2.texture = load("res://Sprites/Characters/Player/Girl/Hair2.png")
        if get_parent().get_node("HUD").hairTheme[3] == -1:
            $Sprite/Hair.modulate = Color(1,0,.78,1)
            $Sprite/Hair2.modulate = Color(1,0,.78,1)
        $Sprite/Hair.position = Vector2(-58,-142)
        $Sprite/Hair2.position = Vector2(-52.6,-132.5)
        $Sprite/Head.texture = load("res://Sprites/Characters/Player/Girl/Head.png")
        $Sprite/Head.position = Vector2(.6,-158.5)
        #$Sprite.offset = Vector2(1,98)
        $Sprite/Torso.texture = load("res://Sprites/Characters/Player/Girl/Torso.png")
        $Sprite/Torso.position = Vector2(-53,56.2)
        $Sprite/Torso.z_index = 0
        $Sprite/LeftArm.texture = load("res://Sprites/Characters/Player/Girl/Arm.png")
        $Sprite/LeftArm.position = Vector2(-38,-57.8)
        $Sprite/RightArm.texture = load("res://Sprites/Characters/Player/Girl/Arm.png")
        $Sprite/RightArm.position = Vector2(-42,-79.8)
        $Sprite/LegLeft.texture = load("res://Sprites/Characters/Player/Girl/Leg.png")
        $Sprite/LegLeft.position = Vector2(-77,130)
        $Sprite/LegRight.texture = load("res://Sprites/Characters/Player/Girl/Leg.png")
        $Sprite/LegRight.position = Vector2(-9,130)
func setPaint(paintChoice,paint):
    self.paint = paint
    if paintChoice == 0:
        BulletScene = load("res://bullet.tscn")
        match equip:
            0: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/pistol.png")
            1: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/M4.png")
            2: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/shotgun.png")
            3: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/launcher.png")
            4: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/railgun.png")
    elif paintChoice == 1:
        if paint >= 1:
            BulletScene = load("res://bulletGold.tscn")
            match equip:
                0: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/pistolGold.png")
                1: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/AssaultRifle.png")
                2: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/shotgunGold.png")
                3: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/launcher-gold.png")
                4: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/railgun-gold.png")
    elif paintChoice == 2:
        if paint >= 2:
            BulletScene = load("res://bulletScaled.tscn")
            match equip:
                0: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/pistolScaled.png")
                1: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/M4Scaled.png")
                2: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/shotgunScaled.png")
                3: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/launcherScaled.png")
                4: $Sprite/RightArm/Weapon/WeaponSprite.texture = load("res://Sprites/Characters/railgunScaled.png")
func _on_SlowmoUseTimer_timeout():
    get_parent().get_node("HUD").slowmoTextureOn()
    slowmoUse = true
func _on_StrikeUseTimer_timeout():
    get_parent().get_node("HUD").strikeTextureOn()
    strikeUse = true
func _on_FlameUseTimer_timeout():
    get_parent().get_node("HUD").flameTextureOn()
    flameUse = true
func _on_SoulShieldUseTimer_timeout():
    get_parent().get_node("HUD").soulTextureOn()
    soulUse = true
func _on_RechargeTimer_timeout():
    var alpha
    if not $SlowmoUseTimer.is_stopped():
        alpha = 1 - ($SlowmoUseTimer.time_left/slowmoWaitTime)
        if alpha < .2:
            alpha = .2
        get_parent().get_node("HUD/SlowmoButton").modulate.a = alpha
    else:
        get_parent().get_node("HUD/SlowmoButton").modulate.a = 1
    if not $FlameUseTimer.is_stopped():
        alpha = 1 - ($FlameUseTimer.time_left/flameWaitTime)
        if alpha < .2:
            alpha = .2
        get_parent().get_node("HUD/FlameButton").modulate.a = alpha
    else:
        get_parent().get_node("HUD/FlameButton").modulate.a = 1
    if not $StrikeUseTimer.is_stopped():
        alpha = 1 - ($StrikeUseTimer.time_left/strikeWaitTime)
        if alpha < .2:
            alpha = .2
        get_parent().get_node("HUD/StrikeButton").modulate.a = alpha
    else:
        get_parent().get_node("HUD/StrikeButton").modulate.a = 1
    if not $SoulShieldUseTimer.is_stopped():
        alpha = 1 - ($SoulShieldUseTimer.time_left/soulWaitTime)
        if alpha < .2:
            alpha = .2
        get_parent().get_node("HUD/ShieldButton").modulate.a = alpha
    else:
        get_parent().get_node("HUD/ShieldButton").modulate.a = 1
