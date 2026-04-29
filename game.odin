#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "core:fmt"

BULLET_BASE_DMG: f32 : 30
GRAVITY: f32: 250
PLAYER_SIZE: rl.Vector2: {12, 12}
PLAYER_MOVE_SPD: f32 : 140
PlAYER_JUMP_VEL: f32: -240
MAX_FALL_SPEED: f32: 150
BULLET_SIZE: rl.Vector2 : {6, 6}
Enemy_melee_SIZE : rl.Vector2 : {15, 15}

LEVEL_GATE_SIZE : rl.Vector2 : {12, 12}


BULLET_DIRECTION :: enum {
    UP, 
    DOWN,
    LEFT,
    RIGHT
}

Enemy_side :: struct {
    e_melee: [dynamic] Enemy_melee,
    e_ranger: [dynamic] Enemy_ranger,
    e_sniper: [dynamic] Enemy_sniper,
    enemy_spawners: [dynamic] Enemy_spawner_pot,
    enemy_bullets: [dynamic] Bullet
} 

Game_Options :: struct {
    cursor_controler: UI_Cursor_Controller,
    is_debug: bool,
    is_paused: bool,
    ui_mouse_pos: rl.Vector2,
    is_hub : bool,
    is_menu: bool,
    is_mini_map: bool,
    is_health_bar: bool
}

FONT_THIN :: "Font_thin"
FONT_REG :: "Font_regular"
FONT_BOLD :: "Font_bold"


Game_Fonts :: map[string] rl.Font 

load_fonts :: proc() -> Game_Fonts {
    reg_font := rl.LoadFont("assets/Roboto-Regular.ttf")
    thin_font := rl.LoadFont("assets/Roboto-Light.ttf")
    bold_font := rl.LoadFont("assets/Roboto-Black.ttf")

    return {
        FONT_REG = reg_font,
        FONT_THIN = thin_font,
        FONT_BOLD = bold_font
    }
}

Game :: struct {
    player: Player,
    particle_system: Particles_systems,
    fonts: Game_Fonts,
    camera: rl.Camera2D,
    current_level: int,
    level_data: Level_data,
    game_options: Game_Options,
    ui_controller: UI_Controller,
    game_sprite_atlas: rl.Texture2D,
    game_background: rl.Texture2D,
    game_cloud_background: rl.Texture2D,
    player_bullets: [dynamic] Bullet,
    enemy_side: Enemy_side,
    boss_manager: Boss_level_manager
}
 



game_init:: proc() -> Game {
    level := 0
    player_level := 0
    game: Game
    player_stats := Player_stats{health_stats = {max_hp = 100, current_hp = 100}, dmg = 25}
    game.current_level = level
    game.player = Player {
        body = Body {
            size = PLAYER_SIZE,
        },
        stats = player_stats,
        bullet_cd = Bullet_Countdown {max_time =  Inittal_bullet_countdown, current_time = Inittal_bullet_countdown},
        exp_controller = Experience_controller {
            current = 0,
            level = player_level,
            require = EXPERIENCE_PER_LEVEL[player_level]
        }
        
    }
    game.ui_controller = {
        is_ui_screen = false,
        ui_scene = .NONE
    }
    rl.HideCursor()
    game.game_options.is_hub = true
    load_atlas(&game)
    load_level(&game, game.current_level)


    return game
}

game_update:: proc(game: ^Game, dt: f32) {
    game.game_options.ui_mouse_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)

    
    if !game.game_options.is_paused {
        player_update(&game.player, game,  game.level_data.colliders[:], dt)
        
        enemies_spawner_update(game, dt)
        Enemy_melees_update(game, dt) 
        Enemy_ranger_update(game, dt)
        Enemy_sniper_update(game, dt)

        for block_collider in game.level_data.colliders {
            resolve_bullet_collider_collision(game, &game.player_bullets, block_collider)
            resolve_bullet_collider_collision(game, &game.enemy_side.enemy_bullets, block_collider)
        }
    
        key_collect(game.player, game)
      
        exp_buff_collect(&game.player, game)
        if game.boss_manager.is_boss_level {
            boss_update(&game.boss_manager.boss, game, dt)
        }
        level_gate_update(game)
        
        bullets_update(game, dt)
    }
    
}

game_post_update:: proc(game: ^Game, dt: f32) {
    
    camera_update(&game.camera, game.player)       
    particles_systems_update(&game.particle_system, dt)

    if game.player.stats.health_stats.current_hp <= 0 {
        game.game_options.is_paused = true
        game.ui_controller.is_ui_screen = true
        game.ui_controller.ui_scene = .GAME_OVER
    }
}

game_pre_update:: proc(game: ^Game, dt: f32) {
    scene_manager_update(game, dt)
    if rl.IsKeyPressed(.F2) {
        game.game_options.is_debug = !game.game_options.is_debug
    }
    
    if rl.IsKeyPressed(.H) {
        game.game_options.is_hub = !game.game_options.is_hub
    }
    if rl.IsKeyPressed(.M) {
        game.game_options.is_mini_map = !game.game_options.is_mini_map
    }
    
    if rl.IsKeyPressed(.L){
        if game.ui_controller.is_ui_screen {
            game.ui_controller.is_ui_screen = false
        }
        game.game_options.is_paused = !game.game_options.is_paused
    }
}

level_gate_update :: proc(game: ^Game) {
    

    if game.level_data.collected_keys == len(game.level_data.keys) {
        game.level_data.is_complete = true
    }

    if game.level_data.is_complete {
        gate := rl.Rectangle {x = game.level_data.gate_position.x - LEVEL_GATE_SIZE.x / 2, y = game.level_data.gate_position.y - LEVEL_GATE_SIZE.y / 2, width = LEVEL_GATE_SIZE.x, height = LEVEL_GATE_SIZE.y}
        player_rect := get_body_rect(game.player.body)

        if rl.CheckCollisionRecs(gate, player_rect) {
            load_level(game, game.current_level + 1)
        }
       
    }
}

bullets_draw :: proc(atlas: rl.Texture2D, player_bullets: []Bullet, enemy_bullets : []Bullet)  {
    sprite := SPRITE_MAP[BULLET_SPRITE]
    source := rl.Rectangle {x= sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}

    for bullet in player_bullets {

        b_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x , height = BULLET_SIZE.y}
        rl.DrawTexturePro(atlas, source, b_rect, {0,0}, 0, rl.WHITE)
    }

    for bullet in enemy_bullets {

        b_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x , height = BULLET_SIZE.y}
        rl.DrawTexturePro(atlas, source, b_rect, {0,0}, 0, rl.WHITE)
    }
}


game_draw:: proc(game: ^Game, dt: f32) {
    rl.ClearBackground({135,206,235,255})
    colliders := game.level_data.colliders
    player_bullet_len := fmt.ctprintf("Player bullets: %d", len(game.player_bullets))

    rl.DrawTexturePro(game.game_background, {x =0, y= 0, width = f32(game.game_background.width), height= f32(game.game_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.WHITE)
    rl.DrawTexturePro(game.game_cloud_background, {x =0, y= 0, width = f32(game.game_cloud_background.width), height= f32(game.game_cloud_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.RED)
    rl.DrawTextureV(game.level_data.texture, rl.Vector2 {0,0}, rl.WHITE)
    
    if game.game_options.is_debug {
        rl.DrawText(player_bullet_len, i32(game.player.body.position.x - 20), i32(game.player.body.position.y -20), 5, rl.BLACK)
        for cld in colliders {
            rl.DrawRectangle(i32(cld.x), i32(cld.y), i32(cld.width), i32(cld.height), rl.BLACK)
        }
    }

    experience_buff_draw(game.game_sprite_atlas, game.level_data.exp_buffs[:])

    keypot_draw(game.game_sprite_atlas, game.game_options.is_debug, game.player.body.position, game.level_data.keys[:])

    level_gate_draw(game.game_sprite_atlas, game.level_data)
    
    enemies_spawner_draw(game^, dt)
    
    
    Enemy_melees_draw(game.game_sprite_atlas, game.game_options, &game.enemy_side.e_melee, dt)
    Enemy_sniper_draw(game.game_sprite_atlas, game.game_options, &game.enemy_side.e_sniper, dt)
    Enemy_ranger_draw(game.game_sprite_atlas, game.game_options, &game.enemy_side.e_ranger, dt)
    if game.boss_manager.is_boss_level {
        boss_draw(game.game_sprite_atlas, game.boss_manager.boss, &game.particle_system, dt)
    }
    bullets_draw(game.game_sprite_atlas, game.player_bullets[:], game.enemy_side.enemy_bullets[:])
    
    player_draw(&game.player, game^, dt)

    
   
    
    particls_systems_draw(game.game_sprite_atlas, game.particle_system, dt)
    player_ui_draw(game)
    render_cursor(game.game_sprite_atlas, game.game_options)
}

level_gate_draw:: proc(atlas: rl.Texture2D, level_data: Level_data) {
    sprite := SPRITE_MAP[LEVEL_GATE_SPRITE]
    source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
    dest := rl.Rectangle {x = level_data.gate_position.x - LEVEL_GATE_SIZE.x / 2, y = level_data.gate_position.y - LEVEL_GATE_SIZE.y / 2, width = LEVEL_GATE_SIZE.x, height = LEVEL_GATE_SIZE.y}

    rl.DrawCircle(i32(level_data.gate_position.x), i32(level_data.gate_position.y), 15, rl.Color{220, 220,220, 180})
    rl.DrawTexturePro(atlas, source, dest, {0,0}, 0, level_data.is_complete ? rl.WHITE : rl.Color {117, 116, 116, 150})
    
    for i:= 0; i < len(level_data.keys); i+= 1 {
        rl.DrawCircle(i32(get_rect_center(dest).x) - i32(7 * (len(level_data.keys) - 1) / 2) + i32(i * 7), i32(level_data.gate_position.y - 15), 2, i < level_data.collected_keys ? rl.RED : rl.Color {118, 171, 252, 255})
    } 

}

keypot_draw :: proc(atlas: rl.Texture2D, is_debug: bool, player_pos: rl.Vector2, keys: []Key_pot) {
    key_atlas_sprite := SPRITE_MAP[KEY_SPRITE]
    key_source := rl.Rectangle{x = key_atlas_sprite.x, y= key_atlas_sprite.y , width = key_atlas_sprite.w, height = key_atlas_sprite.h}
    for key in keys {
        if !key.collected {
            dest := rl.Rectangle{x = key.position.x, y= key.position.y , width = key_atlas_sprite.w, height = key_atlas_sprite.h}

            rl.DrawTexturePro(atlas, key_source, dest, {dest.width / 2, dest.height /2}, 0, key.disabled ? rl.Color{255, 255, 255, 160}  : rl.WHITE)
            if key.disabled {
                unit_expression_draw(atlas, SPRITE_MAP[KEY_DISABLE_AURA_SPRITE], key.position + {8, -8})

            }
        }
    }
}


experience_buff_draw:: proc(atlas: rl.Texture2D, buffs: []Exp_buff) {
    exp_sprite := SPRITE_MAP[EXPERIENCE_BUFF_SPRITE]
    exp_source := rl.Rectangle {x = exp_sprite.x, y= exp_sprite.y, width = exp_sprite.w, height= exp_sprite.h}

    for b in buffs {
        if !b.collected {
            dest := rl.Rectangle{x = b.position.x, y= b.position.y , width = EXPERIENCE_BUFF_SIZE.x, height = EXPERIENCE_BUFF_SIZE.y}

            rl.DrawTexturePro(atlas, exp_source, dest, rl.Vector2{EXPERIENCE_BUFF_SIZE.x / 2, EXPERIENCE_BUFF_SIZE.y / 2}, 0,rl.WHITE)
        }
    }
}

key_collect:: proc(player: Player, game: ^Game) {
    pr := get_body_rect(player.body)
   
    for &key in game.level_data.keys {
        if key.collected || key.disabled do continue

        key_rect := rl.Rectangle{x = key.position.x - KEY_POT_SIZE.x / 2, y = key.position.y - KEY_POT_SIZE.y / 2, width = KEY_POT_SIZE.x, height = KEY_POT_SIZE.y}
        if !rl.CheckCollisionRecs(pr, key_rect) do continue

        if !key.collected {
            game.level_data.collected_keys += 1

            key.collected = true
        }  
        
    }
}


bullets_update :: proc (game: ^Game, dt: f32) {

    for &bullet in game.player_bullets {
        direction_vel : rl.Vector2

        switch bullet.direction {
            case .UP: direction_vel = {0, -200}
            case .DOWN: direction_vel = {0, 200}
            case .RIGHT: direction_vel = {200, 0}
            case .LEFT: direction_vel = {-200, 0}
            case : direction_vel = {0, 0}
        }

        bullet.position += direction_vel * dt


    }

    for &bullet in game.enemy_side.enemy_bullets {
        direction_vel : rl.Vector2

        switch bullet.direction {
            case .UP: direction_vel = {0, -200}
            case .DOWN: direction_vel = {0, 200}
            case .RIGHT: direction_vel = {200, 0}
            case .LEFT: direction_vel = {-200, 0}
            case : direction_vel = {0, 0}
        }

        bullet.position += direction_vel * dt


    }
}


camera_update :: proc(camera : ^rl.Camera2D, player: Player) {
    camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
    camera.target = player.body.position + PLAYER_SIZE / 2
}

game_restart :: proc(game: ^Game) {
    start_level := 0
    player_level := 0

    game.player.stats.buffes = {}
    game.player.stats = {health_stats = {max_hp = 100, current_hp = 100}, dmg = 25}
    game.player.exp_controller = {
        current = 0,
        level = player_level,
        require = EXPERIENCE_PER_LEVEL[player_level]
    }
    game.current_level = start_level
    load_level(game, start_level)
}