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
ENEMY_MINION_SIZE : rl.Vector2 : {15, 15}

LEVEL_GATE_SIZE : rl.Vector2 : {12, 12}


BULLET_DIRECTION :: enum {
    UP, 
    DOWN,
    LEFT,
    RIGHT
}

Game_Options :: struct {
    is_debug: bool,
    is_paused: bool,
    ui_mouse_pos: rl.Vector2
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
    enemy_bullets: [dynamic] Bullet,
    enemy_minions:[dynamic] Enemy_minion,
}
 



Enemy_minion:: struct {
    id: f32,
    body: Body,
    status: Enemy_status,
    stats : Enemy_minion_stats,
    direction: Enemy_directions,
    on_ground: bool,
    is_flip: bool,
    anim_controller: Animation_controller
}

Enemy_status :: enum {
    DEAD,
    ALIVE
}

Enemy_minion_stats :: struct {
    health_stats: Heath_stats,
    dmg: f32,
}

game_init:: proc() -> Game {
    level := 0
    player_level := 0
    game: Game

    player_stats := Player_stats{health_stats = {max_hp = 100, current_hp = 100}, dmg = 25}
    player_spawn_pos := rl.Vector2{50, 300}
    game.current_level = level
    game.player = Player {
        body = Body {
            position = player_spawn_pos,
            size = PLAYER_SIZE,
        },
        spawn_pos = player_spawn_pos,
        stats = player_stats,
        bullet_cd = Bullet_Countdown {max_time =  Inittal_bullet_countdown, current_time = Inittal_bullet_countdown},
        exp_controller = Experience_controller {
            current = 0,
            level = player_level,
            require = EXPERIENCE_PER_LEVEL[player_level]
        }

    }
    load_atlas(&game)
    load_level(&game, game.current_level)

    return game
}

game_update:: proc(game: ^Game, dt: f32) {
           
    game.game_options.ui_mouse_pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera)

    if rl.IsKeyPressed(.F2) {
        game.game_options.is_debug = !game.game_options.is_debug
    }
    
    if rl.IsKeyPressed(.L){
        if game.ui_controller.is_buff_pick {
            game.ui_controller.is_buff_pick = false
        }
        game.game_options.is_paused = !game.game_options.is_paused
    }
    
    player_update(&game.player, game,  game.level_data.colliders[:], dt)
    
    enemies_update(game, dt)
    enemy_minions_update(game, dt) 

    for block_collider in game.level_data.colliders {
        resolve_bullet_collider_collision(game, &game.player_bullets, block_collider)
        resolve_bullet_collider_collision(game, &game.enemy_bullets, block_collider)
    }

    key_collect(game.player, game)
    // exp_buff_collect()
    exp_buff_collect(&game.player, game)

    level_gate_update(game)

    particles_systems_update(&game.particle_system, dt)



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
    cld_len := fmt.ctprintf("colliders count: %d", len(colliders))
    keys_collected := fmt.ctprintf("key collected count: %d", game.level_data.collected_keys)
    player_bullet_len := fmt.ctprintf("Player bullets: %d", len(game.player_bullets))

    rl.DrawTexturePro(game.game_background, {x =0, y= 0, width = f32(game.game_background.width), height= f32(game.game_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.WHITE)
    rl.DrawTexturePro(game.game_cloud_background, {x =0, y= 0, width = f32(game.game_cloud_background.width), height= f32(game.game_cloud_background.height)}, {x= 0, y= 0, width = game.level_data.map_size.x, height = game.level_data.map_size.y}, {0,0}, 0, rl.RED)
    rl.DrawTextureV(game.level_data.texture, rl.Vector2 {0,0}, rl.WHITE)
    
    if game.game_options.is_debug {
        rl.DrawText(cld_len, 10, 10, 12, rl.BLACK)
        rl.DrawText(keys_collected, 10, 350, 12, rl.BLACK)
        rl.DrawText(player_bullet_len, i32(game.player.body.position.x - 20), i32(game.player.body.position.y -20), 5, rl.BLACK)
        for cld in colliders {
            rl.DrawRectangle(i32(cld.x), i32(cld.y), i32(cld.width), i32(cld.height), rl.BLACK)
        }
    }

    experience_buff_draw(game.game_sprite_atlas, game.level_data.exp_buffs[:])

    keypot_draw(game.game_sprite_atlas,game.level_data.keys[:])

    enemies_draw(game^)
    
    player_draw(&game.player, game^, dt)
    
    
    enemy_minions_draw(game.game_sprite_atlas, game.game_options.is_debug, &game.enemy_minions, dt)

    bullets_draw(game.game_sprite_atlas, game.player_bullets[:], game.enemy_bullets[:])

    particls_systems_draw(game.game_sprite_atlas, game.particle_system, dt)
    level_gate_draw(game.game_sprite_atlas, game.level_data)
    player_ui_draw(game)


}

level_gate_draw:: proc(atlas: rl.Texture2D, level_data: Level_data) {
    sprite := SPRITE_MAP[LEVEL_GATE_SPRITE]
    source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
    dest := rl.Rectangle {x = level_data.gate_position.x - LEVEL_GATE_SIZE.x / 2, y = level_data.gate_position.y - LEVEL_GATE_SIZE.y , width = LEVEL_GATE_SIZE.x, height = LEVEL_GATE_SIZE.y}

    rl.DrawTexturePro(atlas, source, dest, {0, 0}, 0, level_data.is_complete ? rl.WHITE : rl.BLACK)

}

keypot_draw :: proc(atlas: rl.Texture2D, keys: []Key_pot) {
    key_atlas_sprite := SPRITE_MAP[KEY_SPRITE]

    key_source := rl.Rectangle{x = key_atlas_sprite.x, y= key_atlas_sprite.y , width = key_atlas_sprite.w, height = key_atlas_sprite.h}
    for key in keys {
        if !key.collected {
            dest := rl.Rectangle{x = key.position.x, y= key.position.y , width = key_atlas_sprite.w, height = key_atlas_sprite.h}

            rl.DrawTexturePro(atlas, key_source, dest, rl.Vector2{key_atlas_sprite.w / 2, key_atlas_sprite.h /2}, 0,rl.WHITE)
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
        if key.collected do continue

        key_rect := rl.Rectangle{x = key.position.x - KEY_POT_SIZE.x / 2, y = key.position.y - KEY_POT_SIZE.y / 2, width = KEY_POT_SIZE.x, height = KEY_POT_SIZE.y}
        if !rl.CheckCollisionRecs(pr, key_rect) do continue

        if !key.collected {
            game.level_data.collected_keys += 1

            key.collected = true
        }  
        
    }
}

