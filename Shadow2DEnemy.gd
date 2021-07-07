extends Area2D

var hp = 350
var level = 0
var teleportDist = 1100
var velocity = 0
var playerPosition = Vector2()
var orientation = 1
var blood = true
const bloodSpread = 20

func _ready():
    playerPosition = get_parent().getPlayerPosition()
    orientation = sign(position.x - playerPosition.x)
    position.x = playerPosition.x + teleportDist
func _process(delta):
    position.x += velocity * delta
func hitByPlayer(damage):
    hp -= damage
    if hp <= 0:
        if level == 0:
            level1()
        else:
            end() #no souls for shadow; it is unkillable
func level1():
    var fire = preload("res://FireExplosion.tscn").instance()
    fire.amount = 35
    fire.lifetime = .9
    fire.scale = Vector2(1.2,1.2)
    fire.position = position
    fire.modulate = Color(0,0,0,1) #black fire
    get_parent().add_child(fire)
    fire.add_to_group("enemies")
    fire.one_shot = true
    fire.emitting = true
    level += 1
    $FadeTimer.stop()
    scale.x = .5
    scale.y = .8
    orientation = sign(position.x - get_parent().getPlayerPosition().x)
    rotation = PI/2 * orientation
    position.y += 206
    velocity = -320*orientation
    modulate.a = .84
    blood = false
    hp = INF
func end():
    $CollisionShape2D.set_deferred("disabled", true)
    $CollisionShape2D2.set_deferred("disabled", true)
    $FadeTimer.start()
    velocity = 0
    hp = 0
    level = -1
    get_parent().addSoul(position,250,.48)
func _on_Shadow_body_entered(body):
    if body.has_method("playerHit"):
        body.playerHit(400, Vector2(0,-800))
        end()
func teleport():
    var fire = preload("res://FireExplosion.tscn").instance()
    fire.amount = 10
    fire.position = position
    fire.lifetime = .6
    fire.scale = Vector2(.9,.9)
    fire.modulate = Color(0,0,0,1)
    get_parent().add_child(fire)
    fire.add_to_group("shadowFire")
    fire.one_shot = true
    fire.emitting = true
    var playerPosition = get_parent().getPlayerPosition()
    var orientation = sign(position.x - playerPosition.x)
    $Sprite.scale.x = orientation
    position.x = playerPosition.x + (-1 * orientation * teleportDist)
    teleportDist -= 75
func _on_FadeTimer_timeout():
    $Sprite.modulate.a -= .12
    if $Sprite.modulate.a <= 0:
        if hp > 0:
            $Sprite.modulate.a = 1
            teleport()
        else:
            queue_free()
