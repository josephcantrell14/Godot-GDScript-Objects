extends Node

var debug = false
var score = 0
var totalScore = 0 #total score earned across plays
var bestScore = 0

var lastTopWallPosition = null
var lastBottomWallPosition = null

var alerionew = 0 #determines a lair's formation: always start off straight, and then randomized tunnels can occur on subsequent playthroughs
var crescent = 1

func _ready():
    randomize()
    set_process_input(true)
func new_game():
    if debug:
        $HUD.setDNA(100)
    $BGFadeTimer.start()
    $StartSound.play()
    alerionew = 0
    crescent = 1
    score = 0
    $Player.start($StartPosition.position)
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    wall.position = $StartPosition.position
    wall.position.y -= 400
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    #var rand = randi() % 3145
    wall2.position = $StartPosition.position
    wall2.position.y += 400
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    var esi = preload("res://Eye.tscn").instance()
    add_child(esi)
    esi.global_position = Vector2(2591.69,521.737)
    if $HUD.invertedCamera:
        esi.rotation_degrees = 90
    esi.modulate = $HUD.sparkColor
    esi.get_node("Supernova").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.07)
    esi.get_node("Supernova2").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.1)
    esi.get_node("CollectExplosion").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.07)
    $Eye/Supernova.emitting = false
    $Eye/Supernova2.emitting = false
    $AlerionTimer.start()
    $ESiTimer.start()
    $VerticalWallTimer.start()
func _on_Player_end():
    $EndTimer.start()
    if not debug:
        $HUD.gamesPlayed += 1
        $HUD.playTime += int(OS.get_unix_time()-$HUD.startTime)
func _on_EndTimer_timeout():
    game_over()
func game_over():
    $MainMenuCamera.current = true
    $Player.position = Vector2(1422,986)  #next to play button
    $Player/SpriteParticles.emitting = true
    $HUD.showGameOver()
    $HUD.setDNA(totalScore)
    $BackgroundStart.show()
    $AlerionTimer.stop()
    $ESiTimer.stop()
    var walls = get_tree().get_nodes_in_group("walls")
    for wall in walls:  #clear the previous matrix
        wall.queue_free()
    var esis = get_tree().get_nodes_in_group("esis")
    for esi in esis:
        esi.queue_free()
    if score > bestScore:
        bestScore = score
        $HUD.get_node("Custom/BestScore").text = "Most Essence : " + str(bestScore)
    $HUD.setSave()
func _on_AlerionTimer_timeout():
    Alerion()
func _on_ESiTimer_timeout():
    ESi()
    alerionew = randi()%5
    $VerticalWallTimer.start()  #prevent vertical walls on algorithm change
    crescent = 1
func ESi():
    var esi = preload("res://Eye.tscn").instance()
    add_child(esi)
    esi.position = lastTopWallPosition + Vector2(100,400)
    if $HUD.invertedCamera:
        esi.rotation_degrees = 90
    esi.modulate = $HUD.sparkColor
    esi.get_node("Supernova").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.07)
    esi.get_node("Supernova2").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.1)
    esi.get_node("CollectExplosion").modulate = Color($HUD.sparkColor.r,$HUD.sparkColor.g,$HUD.sparkColor.b,.07)
    for eye in get_tree().get_nodes_in_group("esis"):  #clear out of sight esis and walls
        if eye.position.x - $Player.position.x < -2000:
            eye.queue_free()
    for wall in get_tree().get_nodes_in_group("walls"):
        if wall.position.x - $Player.position.x < -1500:
            wall.queue_free()
    if lastTopWallPosition.x - $Player.position.x > 4500:
        $AlerionTimer.stop()
    elif $AlerionTimer.is_stopped():
        $AlerionTimer.start()
func Alerion():  #builds a lair (tunnel, wall, etc.)
    match alerionew:
        0: WallStreet()
        1: SlopeDescent()
        2: SlopeAscent()
        3: CrescentDown()
        4: CrescentUp()
func WallStreet():  #straight line of walls
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    wall.position = lastTopWallPosition + Vector2(100,0)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,0)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    if $VerticalWallTimer.is_stopped():
        var rand = randi()%10
        if rand <= 2:  #top vertical wall
            for i in range(rand):
                var vertWall = preload("res://Wall.tscn").instance()
                add_child(vertWall)
                vertWall.global_position = wall.global_position + Vector2(0,(i+1)*80)
                vertWall.rotation = 90
                vertWall.modulate = $HUD.themeColor
                $VerticalWallTimer.start()
        else:  #try bottom wall
            rand = randi()%10
            if rand <= 2:
                for i in range(rand):
                    var vertWall = preload("res://Wall.tscn").instance()
                    add_child(vertWall)
                    vertWall.global_position = wall2.global_position + Vector2(0,(i+1)*-80)
                    vertWall.rotation = -90
                    vertWall.modulate = $HUD.themeColor
                    $VerticalWallTimer.start()
func SlopeDescent():
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    var slope = 10 + (randi() % 30)
    var rand = 2 + (randi() % slope)  #min slope of 2
    wall.position = lastTopWallPosition + Vector2(100,rand)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,rand)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    if $VerticalWallTimer.is_stopped():
        rand = randi()%25
        if rand <= 2:  #top vertical wall
            for i in range(rand):
                var vertWall = preload("res://Wall.tscn").instance()
                add_child(vertWall)
                vertWall.global_position = wall.global_position + Vector2(0,(i+1)*80)
                vertWall.rotation = 90
                vertWall.modulate = $HUD.themeColor
                $VerticalWallTimer.start()
        else:  #try bottom wall
            rand = randi()%25
            if rand <= 2:
                for i in range(rand):
                    var vertWall = preload("res://Wall.tscn").instance()
                    add_child(vertWall)
                    vertWall.global_position = wall2.global_position + Vector2(0,(i+1)*-80)
                    vertWall.rotation = -90
                    vertWall.modulate = $HUD.themeColor
                    $VerticalWallTimer.start()
func SlopeAscent():
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    var slope = 10 + (randi() % 30)
    var rand = -1 * (2 + (randi() % slope))
    wall.position = lastTopWallPosition + Vector2(100,rand)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,rand)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    if $VerticalWallTimer.is_stopped():
        rand = randi()%25
        if rand <= 2:  #top wall
            for i in range(rand):
                var vertWall = preload("res://Wall.tscn").instance()
                add_child(vertWall)
                vertWall.global_position = wall.global_position + Vector2(0,(i+1)*80)
                vertWall.rotation = 90
                vertWall.modulate = $HUD.themeColor
                $VerticalWallTimer.start()
        else:  #try bottom wall
            rand = randi()%25
            if rand <= 2:
                for i in range(rand):
                    var vertWall = preload("res://Wall.tscn").instance()
                    add_child(vertWall)
                    vertWall.global_position = wall2.global_position + Vector2(0,(i+1)*-80)
                    vertWall.rotation = -90
                    vertWall.modulate = $HUD.themeColor
                    $VerticalWallTimer.start()
func CrescentDown():  #calculate points along a semicircle
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    var slope = .22 + randf()
    wall.position = lastTopWallPosition + Vector2(100,crescent*PI*slope)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,crescent*PI*slope)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    crescent += 1
func CrescentUp():
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    var slope = .22 + randf()
    wall.position = lastTopWallPosition + Vector2(100,-1*crescent*PI*slope)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,-1*crescent*PI*slope)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    crescent += 1
func DNA():
    var wall = preload("res://Wall.tscn").instance()
    add_child(wall)
    var slope = .22 + randf()
    wall.position = lastTopWallPosition + Vector2(100,crescent*PI*slope)
    lastTopWallPosition = wall.position
    wall.modulate = $HUD.themeColor
    var wall2 = preload("res://Wall.tscn").instance()
    add_child(wall2)
    wall2.position = lastBottomWallPosition + Vector2(100,-1*crescent*PI*slope)
    lastBottomWallPosition = wall2.position
    wall2.modulate = $HUD.themeColor
    crescent += 1
func _on_BGFadeTimer_timeout():
    $BackgroundStart.modulate.a -= .05
    if $BackgroundStart.modulate.a <= 0:
        $BackgroundStart.hide()
        $BackgroundStart.modulate.a = 1
        $BGFadeTimer.stop()
func addScore(addition):
    score += addition
    totalScore += addition
    $HUD/ScoreLabel.text = str(score)
func setThemeColor(color):
    $BackgroundStart.modulate = color
    $HUD/Custom/Title["custom_colors/font_color"] = color
    $HUD/Popup/Title["custom_colors/font_color"] = color
    $HUD/GeneralOptionsHUD/Title["custom_colors/font_color"] = color
    $HUD/InputMapPopup/Title["custom_colors/font_color"] = color
    $HUD/Custom/BG["custom_styles/disabled"].border_color = color
    $HUD/Custom/ThemeColorButton["custom_styles/normal"].bg_color = color
    $HUD/Custom/CloseCustom["custom_styles/normal"].bg_color = color
    $HUD/GeneralOptionsHUD/GeneralClose["custom_styles/normal"].bg_color = color
    $HUD/InputMapPopup/CloseInputMapPopup["custom_styles/normal"].bg_color = color
    $HUD/InputMapPopup/MoveForward["custom_styles/normal"].border_color = color
    $HUD/InputMapPopup/MoveBackward["custom_styles/normal"].border_color = color
    $HUD/InputMapPopup/Pause["custom_styles/normal"].border_color = color
    $HUD/InputMapPopup/DefaultInputButton["custom_styles/normal"].border_color = color
    $HUD/Popup/Yes["custom_styles/normal"].border_color = color
    $HUD/Popup/No["custom_styles/normal"].border_color = color
    $HUD/Popup/ClosePopup["custom_styles/normal"].bg_color = color
    $HUD/GeneralOptionsHUD/VolumeSlider.modulate = color
    $HUD/GeneralOptionsHUD/ResolutionSlider.modulate = color
    $HUD/GeneralOptionsHUD/UISlider.modulate = color
    $HUD/GeneralOptionsHUD/Fullscreen/FullscreenCheckbox.modulate = color
    $HUD/GeneralOptionsHUD/CameraRotate/CheckboxCameraRotate.modulate = color
func setSparkColor(color):
    $Player.modulate = color
    $HUD/Custom/XP.modulate = color
    $HUD/ScoreLabel.modulate = color
    $HUD/PauseButton.modulate = color
    $HUD/Custom/Progress.modulate = color
    $HUD/Custom/BestScore.modulate = color
    $HUD/Custom/SparkColorButton["custom_styles/normal"].bg_color = color
    $HUD/StartButton["custom_styles/hover"].border_color = color
    $HUD/StartButton["custom_styles/pressed"].border_color = color
    $HUD/InstructionsButton["custom_styles/hover"].border_color = color
    $HUD/InstructionsButton["custom_styles/pressed"].border_color = color
    $HUD/QuitButton["custom_styles/hover"].border_color = color
    $HUD/QuitButton["custom_styles/pressed"].border_color = color
    $HUD/CustomButton["custom_styles/hover"].border_color = color
    $HUD/CustomButton["custom_styles/pressed"].border_color = color
    $HUD/Custom/GeneralOptionsButton["custom_styles/hover"].border_color = color
    $HUD/Custom/GeneralOptionsButton["custom_styles/pressed"].border_color = color
    $HUD/GeneralOptionsHUD/InputMap["custom_styles/hover"].border_color = color
    $HUD/GeneralOptionsHUD/InputMap["custom_styles/pressed"].border_color = color
    $HUD/InputMapPopup/MoveForward["custom_styles/hover"].border_color = color
    $HUD/InputMapPopup/MoveForward["custom_styles/pressed"].border_color = color
    $HUD/InputMapPopup/MoveBackward["custom_styles/hover"].border_color = color
    $HUD/InputMapPopup/MoveBackward["custom_styles/pressed"].border_color = color
    $HUD/InputMapPopup/Pause["custom_styles/hover"].border_color = color
    $HUD/InputMapPopup/Pause["custom_styles/pressed"].border_color = color
    $HUD/InputMapPopup/DefaultInputButton["custom_styles/hover"].border_color = color
    $HUD/InputMapPopup/DefaultInputButton["custom_styles/pressed"].border_color = color
    $HUD/Popup/Yes["custom_styles/hover"].border_color = color
    $HUD/Popup/No["custom_styles/pressed"].border_color = color
    $HUD/Custom/CloseCustom["custom_styles/hover"].border_color = color
    $HUD/Custom/CloseCustom["custom_styles/pressed"].border_color = color
    $HUD/GeneralOptionsHUD/GeneralClose["custom_styles/hover"].border_color = color
    $HUD/GeneralOptionsHUD/GeneralClose["custom_styles/pressed"].border_color = color
    $HUD/InputMapPopup/CloseInputMapPopup["custom_styles/hover"].border_color = color
    $HUD/InputMapPopup/CloseInputMapPopup["custom_styles/pressed"].border_color = color
    $HUD/Popup/ClosePopup["custom_styles/hover"].border_color = color
    $HUD/Popup/ClosePopup["custom_styles/pressed"].border_color = color
