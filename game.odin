#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "core:fmt"

BULLET_BASE_DMG: f32 : 30
GRAVITY: f32: 250
PLAYER_SIZE: rl.Vector2: {12, 12}
PLAYER_MOVE_SPD: f32 : 140
PlAYER_JUMP_VEL: f32: -240
MAX_FALL_SPEED: f32: 300
BULLET_SIZE: rl.Vector2 : {6, 6}
Enemy_melee_SIZE : rl.Vector2 : {15, 15}

LEVEL_GATE_SIZE : rl.Vector2 : {12, 12}
MONEY_COINS_PER_KEY : f32 : 20

BULLET_DIRECTION :: enum {
    UP, 
    DOWN,
    LEFT,
    RIGHT
}

Enemy_side :: struct {
    enemy_units: [dynamic] Enemy_unit,
    enemy_spawners: [dynamic] Enemy_spawner_pot,
    enemy_bullets: [dynamic] Bullet,
    enemy_stat_buffes: Enemy_buffes
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
    boss_manager: Boss_level_manager,
    shop_manager: Shop_manager,
    level_vendor: Level_vendor,
    slow_motion_manager: Slow_motion
}
 
Slow_motion:: struct {
    is_slow_motion: bool
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
            direction = .RIGHT
        },

        stats = player_stats,
        bullet_cd = Bullet_Countdown {max_time =  Inittal_bullet_countdown, current_time = Inittal_bullet_countdown},
        exp_controller = Experience_controller {
            current = 0,
            level = player_level,
            require = EXPERIENCE_PER_LEVEL[player_level]
        },
        pocket_items = {{type = .HEAL}, {type = .NONE}, {type = .NONE}, {type = .NONE}, {type = .NONE}, {type = .NONE}},
        input_controler = get_default_input_controler()
        
    }
    game.ui_controller.ui_scene = .NONE
    game.game_options.is_hub = true
    rl.HideCursor()
    load_atlas(&game)
    load_level(&game, game.current_level)


    return game
}

game_update:: proc(game: ^Game, dt: f32) {
    game.game_options.ui_mouse_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)

    
    if !game.game_options.is_paused {
        player_update(&game.player, game,  game.level_data.colliders[:], dt)
        
        enemies_spawner_update(game, dt)
        enemy_unit_update(game, dt) 
        

        for block_collider in game.level_data.colliders {
            resolve_bullet_collider_collision(game, &game.player_bullets, block_collider)
            resolve_bullet_collider_collision(game, &game.enemy_side.enemy_bullets, block_collider)
        }
    
        key_collect(game.player, game)
      
        exp_buff_collect(&game.player, game)
        if game.boss_manager.is_boss_level {

            boss_update(&game.boss_manager.boss, game, dt)
            boss_skill_update(&game.boss_manager.boss, game, dt)
        }
        level_gate_update(game)
        level_vendor_update(&game.level_vendor, game.level_data.colliders[:], &game.ui_controller, &game.game_options, game.player.body.position, dt)
        bullets_update(game, dt)

    }
    
}

game_post_update:: proc(game: ^Game, dt: f32) {
    
    camera_update(&game.camera, game.player)       
    particles_systems_update(&game.particle_system, dt)

    if game.player.stats.health_stats.current_hp <= 0 {
        game.game_options.is_paused = true
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
        
        game.game_options.is_paused = !game.game_options.is_paused
    }
    if rl.IsKeyPressed(.SLASH) {
        game.slow_motion_manager.is_slow_motion = !game.slow_motion_manager.is_slow_motion
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
            game.game_options.is_paused = true
            game.ui_controller.ui_scene = .END_LEVEL
            game.ui_controller.transition_time = 0.5
        }
       
    }
}

bullets_draw :: proc(atlas: rl.Texture2D, player_bullets: []Bullet, enemy_bullets : []Bullet)  {
    sprite := SPRITE_MAP[BULLET_SPRITE]
    source := get_sprite_source_rect(sprite)

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
    colliders := game.level_data.colliders

    rl.DrawTexturePro(game.game_background, {x =0, y= 0, width = f32(game.game_background.width), height= f32(game.game_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.WHITE)
    rl.DrawTexturePro(game.game_cloud_background, {x =0, y= 0, width = f32(game.game_cloud_background.width), height= f32(game.game_cloud_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.RED)
    
    if game.boss_manager.is_boss_level {
        boss_draw(game.game_sprite_atlas, game.boss_manager.boss, dt)
    }

    rl.DrawTextureV(game.level_data.texture, rl.Vector2 {0,0}, rl.WHITE)
    
    if game.game_options.is_debug {
        for cld in colliders {
            rl.DrawRectangleRec(cld, rl.BLACK)
        }
    }

    experience_buff_draw(game.game_sprite_atlas, game.level_data.exp_buffs[:])

    
    level_gate_draw(game.game_sprite_atlas, game.level_data.gate_position, game.level_data.keys[:], game.level_data.collected_keys, game.level_data.is_complete)
    
    enemies_spawner_draw(game.game_sprite_atlas, game.enemy_side.enemy_spawners[:], game.game_options.is_debug, dt)
    
    keypot_draw(game.game_sprite_atlas, game.game_options.is_debug, game.player.body.position, game.level_data.keys[:])
    
    level_vendor_draw(game.game_sprite_atlas, game.level_vendor.body, game.level_vendor.is_disabled, game.level_vendor.is_player_near, game.level_vendor.can_open, dt)

    enemy_unit_draw(game.game_sprite_atlas, game.game_options, &game.enemy_side.enemy_units, dt)
  
    bullets_draw(game.game_sprite_atlas, game.player_bullets[:], game.enemy_side.enemy_bullets[:])
    
    player_draw(game.game_sprite_atlas, &game.player, dt)

    if game.boss_manager.is_boss_level {

        boss_skill_draw(game.game_sprite_atlas, game.boss_manager.boss, dt)
    }

     
    player_ui_draw(game)
    game_ui_scene_draw(game, dt)
    
    render_cursor(game.game_sprite_atlas, game.game_options)
    particls_systems_draw(game.game_sprite_atlas, game.particle_system, dt)
}

level_gate_draw:: proc(atlas: rl.Texture2D, gate_position: rl.Vector2, keys: []Key_pot, key_collected: int, is_level_completed: bool) {
    sprite := SPRITE_MAP[LEVEL_GATE_SPRITE]
    source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
    dest := rl.Rectangle {x = gate_position.x - LEVEL_GATE_SIZE.x / 2, y = gate_position.y - LEVEL_GATE_SIZE.y / 2, width = LEVEL_GATE_SIZE.x, height = LEVEL_GATE_SIZE.y}

    rl.DrawCircle(i32(gate_position.x), i32(gate_position.y), 15, rl.Color{220, 220,220, 180})
    rl.DrawTexturePro(atlas, source, dest, {0,0}, 0, is_level_completed ? rl.WHITE : rl.Color {117, 116, 116, 150})
    
    for i:= 0; i < len(keys); i+= 1 {
        rl.DrawCircle(i32(get_rect_center(dest).x) - i32(7 * (len(keys) - 1) / 2) + i32(i * 7), i32(gate_position.y - 15), 2, i < key_collected ? rl.RED : rl.Color {118, 171, 252, 255})
    } 

}

keypot_draw :: proc(atlas: rl.Texture2D, is_debug: bool, player_pos: rl.Vector2, keys: []Key_pot) {
    key_atlas_sprite := SPRITE_MAP[KEY_SPRITE]
    key_source := get_sprite_source_rect(key_atlas_sprite)
    for key in keys {
        if !key.collected {
            dest := rl.Rectangle{x = key.position.x, y= key.position.y , width = key_atlas_sprite.w, height = key_atlas_sprite.h}

            rl.DrawTexturePro(atlas, key_source, dest, {dest.width / 2, dest.height /2}, 0, key.disabled ? rl.Color{255, 255, 255, 160}  : rl.WHITE)
            if key.disabled {
                unit_expression_draw(atlas, SPRITE_MAP[KEY_DISABLE_AURA_SPRITE], UI_UNIT_EXPRESSION_SIZE, key.position + {8, -8})

            }
        }
    }
}


experience_buff_draw:: proc(atlas: rl.Texture2D, buffs: []Exp_buff) {
    exp_sprite := SPRITE_MAP[EXPERIENCE_BUFF_SPRITE]
    exp_source := get_sprite_source_rect(exp_sprite)

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
            game.player.money_coins.val += MONEY_COINS_PER_KEY
            key.collected = true
            add_particle(&game.particle_system, {
                size = {20, 20},
                position = key.position,
                sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_COIN_PARTICLE_SPRITE]),
                vel = {0, -100},
                is_blur = true,
                is_scaled = true,
                timer = {max_time = 0.5, current = 0.5}


            })
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

    // Ensure we clean up existing memory before overwriting pointers
    clear_game_mem(game)

    game.player.stats.buffes = {}
    game.player.stats = {health_stats = {max_hp = 100, current_hp = 100}, dmg = 25}
    game.player.exp_controller = {
        current = 0,
        level = player_level,
        require = EXPERIENCE_PER_LEVEL[player_level]
    }
    game.player.pocket_items = {{type = .HEAL}, {type = .NONE}, {type = .NONE}, {type = .NONE}, {type = .NONE}, {type = .NONE}}
    game.player.money_coins.val = 0
    game.current_level = start_level
    load_level(game, start_level)
}

drop_game_mem:: proc(game : ^Game) {
    delete(game.enemy_side.enemy_bullets)
    delete(game.player_bullets)
    delete(game.enemy_side.enemy_units)
    delete(game.level_data.colliders)
    delete(game.enemy_side.enemy_spawners)
    delete(game.level_data.keys)
    delete(game.level_data.exp_buffs)
    delete(game.boss_manager.boss.skill_queue)
    delete(game.player.stats.temp_buffes)
    rl.UnloadFont(game.fonts[FONT_BOLD])
    rl.UnloadFont(game.fonts[FONT_REG])
    rl.UnloadFont(game.fonts[FONT_THIN])
    delete(game.fonts)
}

clear_game_mem:: proc(game: ^Game) {
    clear(&game.player_bullets)
    clear(&game.enemy_side.enemy_units)
    clear(&game.level_data.colliders)
    clear(&game.enemy_side.enemy_spawners)
    clear(&game.level_data.keys)
    clear(&game.level_data.exp_buffs)

    delete(game.boss_manager.boss.skill_queue)
    game.boss_manager.boss.skill_queue = nil

    delete(game.player.stats.temp_buffes)
    game.player.stats.temp_buffes = nil
}