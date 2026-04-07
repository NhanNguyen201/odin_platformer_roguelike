#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

BULLET_BASE_DMG: f32 : 30
GRAVITY: f32: 250
PLAYER_SIZE: rl.Vector2: {12, 12}
PLAYER_MOVE_SPD: f32 : 140
PlAYER_JUMP_VEL: f32: -240
MAX_FALL_SPEED: f32: 300
BULLET_SIZE: rl.Vector2 : {6, 6}
ENEMY_MINION_SIZE : rl.Vector2 : {15, 15}

BULLET_DIRECTION :: enum {
    UP, 
    DOWN,
    LEFT,
    RIGHT
}

GameOptions :: struct {
    is_debug: bool,
    is_paused: bool,
    ui_mouse_pos: rl.Vector2
}

Game :: struct {
    player: Player,
    camera: rl.Camera2D,
    current_level: int,
    level_data: Level_data,
    game_options: GameOptions,
    game_sprite_atlas: rl.Texture2D,
    game_background: rl.Texture2D,
    game_cloud_background: rl.Texture2D,
    player_bullets: [dynamic] Bullet,
    enemy_bullets: [dynamic] Bullet,
    enemy_minions: [dynamic] Enemy_minion,
}




Enemy_minion:: struct {
    id: f32,
    size: rl.Vector2,
    status: Enemy_status,
    stats : Enemy_minion_stats,
    position: rl.Vector2,
    vel: rl.Vector2,
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
    game: Game

    player_stats := Player_stats{health_stats = {max_hp = 100, current_hp = 100}, dmg = 25}


    player_spawn_pos := rl.Vector2{50, 300}
    game.current_level = level
    game.player = Player {
        position = player_spawn_pos,
        spawn_pos = player_spawn_pos,
        size = PLAYER_SIZE,
        stats = player_stats,
        bullet_cd = Bullet_Countdown {max_time =  Inittal_bullet_countdown, current_time = Inittal_bullet_countdown}

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
        game.game_options.is_paused = !game.game_options.is_paused
    }
    
    player_update(&game.player, game,  game.level_data.colliders[:], dt)
    
    enemies_update(game, dt)
    enemy_minions_update(game, dt) 

    for block_collider in game.level_data.colliders {
        resolve_bullet_collider_collision(&game.player_bullets, block_collider)
        resolve_bullet_collider_collision(&game.enemy_bullets, block_collider)
    }

    key_collect(game.player, game)
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
        rl.DrawText(player_bullet_len, i32(game.player.position.x - 20), i32(game.player.position.y -20), 5, rl.BLACK)
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

    player_ui_draw(game^)


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
            dest := rl.Rectangle{x = b.position.x, y= b.position.y , width = exp_sprite.w, height = exp_sprite.h}

            rl.DrawTexturePro(atlas, exp_source, dest, rl.Vector2{exp_sprite.w / 2, exp_sprite.h /2}, 0,rl.WHITE)
        }
    }
}

key_collect:: proc(player: Player, game: ^Game) {
    pr := player_rect(player)
   
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



enemies_update:: proc(game: ^Game, dt: f32) {

    if game.game_options.is_paused {
        return
    }

    for &enemy_spawner in game.level_data.enemy_spawners {
        is_minion_dead := false
        found := false


        for minion in game.enemy_minions {
            if minion.id == enemy_spawner.enemy_id  {
                found = true
                if minion.status == .DEAD {
                    is_minion_dead = true
                    break
                }
            } 
        }

        if is_minion_dead  || !found {
            enemy_spawner.re_spawn.time -= dt

            if enemy_spawner.re_spawn.time < 0 {
                enemy_spawner.re_spawn.time =  enemy_spawner.re_spawn.max_time
                spawn_minion(game, enemy_spawner)
            }

        }

    }

}

enemies_draw:: proc(game: Game) {
    spawner_size := rl.Vector2 {13, 13}
    p_sprite := SPRITE_MAP[PORTAL_SPRITE]
    p_sprite_1 := SPRITE_MAP[PORTAL_SPRITE_1]
    p_sprite_2 := SPRITE_MAP[PORTAL_SPRITE_2]
    for enemy_spawner in game.level_data.enemy_spawners {
        dest := rl.Rectangle {x = enemy_spawner.position.x, y = enemy_spawner.position.y, width = spawner_size.x, height = spawner_size.y}
        source_portal := rl.Rectangle {x = p_sprite.x, y = p_sprite.y, width = p_sprite.w, height = p_sprite.h}
        source_portal_1 := rl.Rectangle {x = p_sprite_1.x, y = p_sprite_1.y, width = p_sprite_1.w, height = p_sprite_1.h}
        source_portal_2 := rl.Rectangle {x = p_sprite_2.x, y = p_sprite_2.y, width = p_sprite_2.w, height = p_sprite_2.h}
        rl.DrawTexturePro(game.game_sprite_atlas, source_portal, dest, {spawner_size.x / 2, spawner_size.y / 2}, 0, rl.WHITE)
        
        dest_1 := dest
        dest_1.y += f32(.25 * math.sin(rl.GetTime() ))
        rl.DrawTexturePro(game.game_sprite_atlas, source_portal_1, dest_1, {spawner_size.x / 2, spawner_size.y / 2 }, 0, rl.WHITE)

        dest_2 := dest
        dest_2.y += f32(.5 * math.cos(rl.GetTime() ))
        rl.DrawTexturePro(game.game_sprite_atlas, source_portal_2, dest_2, {spawner_size.x / 2, spawner_size.y / 2}, 0, rl.WHITE)
        // rl.DrawCircleLinesV(enemy_spawner.position, 4, rl.BLACK)
        if game.game_options.is_debug {
            respawn_ui_height :f32 = 10
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(respawn_ui_height), rl.WHITE)
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(enemy_spawner.re_spawn.time / enemy_spawner.re_spawn.max_time * respawn_ui_height), rl.BLUE)
            
        }
    }


}



enemy_minions_update::proc (game: ^Game, dt: f32) {
    if game.game_options.is_paused {
        return
    }

    for i:= len(game.enemy_minions) - 1; i >=0; i -= 1 {
        enemy := &game.enemy_minions[i]

        direction := enemy.direction

        if enemy.stats.health_stats.current_hp <= 0 {
            // unordered_remove(&game.enemy_minions, i)
            enemy.status = .DEAD    
            continue
        } 


        // turn_rect := rl.Rectangle {
        //     x = direction == .RIGHT ? enemy.position.x + enemy.size.x : enemy.position.x - 5,
        //     y = enemy.position.y + enemy.size.y + 2,
        //     width = 5,
        //     height = 2
        // }

        

        dvel := enemy.vel.x * (direction == .RIGHT ? 1 : -1)

        if abs(enemy.vel.x) > 0 {
            if enemy.anim_controller.animation_name != RUN {
                enemy.anim_controller.animation_name = RUN
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = Minion_animations[RUN].frame_timer
            }
        } else if abs(enemy.vel.x) == 0 {
            if enemy.anim_controller.animation_name != IDLE {
                enemy.anim_controller.animation_name = IDLE
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = Minion_animations[IDLE].frame_timer
            }
        }


        enemy.position.x += dt * dvel 

        for block_collider in game.level_data.colliders {
            resolve_minion_horizontal(enemy, block_collider)
        }

        enemy.vel.y = min(enemy.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.position.y += enemy.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_minion_vertical(enemy, block_collider)
        }


        resolve_enemy_and_bullet(enemy, &game.player_bullets)
    }
}

enemy_take_dmg :: proc(enemy: ^Enemy_minion, bullet: Bullet) {
    enemy.stats.health_stats.current_hp -= bullet.dmg
}

enemy_minions_draw::proc (atlas: rl.Texture2D, is_debug: bool, minions: ^[dynamic]Enemy_minion, dt: f32) {
    for &minion in minions {
        minion_rect := rl.Rectangle {x = minion.position.x - minion.size.x / 2, y = minion.position.y - minion.size.y / 2, width = minion.size.x, height = minion.size.y}
        is_flip := minion.direction == .LEFT
        

        anim := Minion_animations[minion.anim_controller.animation_name]

        if minion.status == .DEAD {
            dead_sprite := SPRITE_MAP[MINION_DEAD_SPRITE]
            rl.DrawTexturePro(
                atlas, 
                rl.Rectangle {x = dead_sprite.x, y= dead_sprite.y, width = dead_sprite.w * (is_flip ? -1 : 1), height = dead_sprite.h},
                rl.Rectangle {x = minion.position.x, y = minion.position.y, width = minion.size.x, height = minion.size.y},
                minion.size / 2,
                0,
                rl.WHITE
            )
        } else {
            draw_animation(atlas, &minion.anim_controller, anim, MINION_SPRITE, is_flip, minion_rect, dt)
        }


        if is_debug {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = minion_rect.x + (minion.size.x / 2)- (full_health_width / 2), y = minion_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = minion.stats.health_stats.current_hp / minion.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
    } 

}

spawn_minion:: proc(game: ^Game, enemy_spawner: Enemy_spawner_pot) {
    stats := Enemy_minion_stats {
        health_stats = {
            max_hp = 100,
            current_hp = 100
        },
        dmg = 25
    }
    found := false

    for &enemy in game.enemy_minions {
        if enemy.id == enemy_spawner.enemy_id {
            found = true

            enemy.status = .ALIVE
            enemy.direction = .RIGHT
            enemy.position = enemy_spawner.position
            enemy.stats = stats
            enemy.size = ENEMY_MINION_SIZE
            enemy.vel = 20

            break
        }
    }

    if !found {
        enemy := Enemy_minion {
            id = enemy_spawner.enemy_id,
            status = .ALIVE,
            position = enemy_spawner.position,
            direction = .RIGHT,
            stats = stats,
            size = ENEMY_MINION_SIZE,
            vel = 20,
        }
        append(&game.enemy_minions, enemy)
    }
}