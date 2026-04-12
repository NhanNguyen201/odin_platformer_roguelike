package main
import rl "vendor:raylib"
import "core:math"

ENEMY_AIMING_TRIGGER_DUR : f32 : 0.5 

enemies_update:: proc(game: ^Game, dt: f32) {

    if game.game_options.is_paused {
        return
    }

    for &enemy_spawner in game.enemy_side.enemy_spawners {
        is_minion_dead := false
        found := false


        for minion in game.enemy_side.enemy_minions {
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
    for enemy_spawner in game.enemy_side.enemy_spawners {
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
    

    for i:= len(game.enemy_side.enemy_minions) - 1; i >=0; i -= 1 {
        enemy := &game.enemy_side.enemy_minions[i]

        direction := enemy.direction

        if enemy.stats.health_stats.current_hp <= 0 {
            // unordered_remove(&game.enemy_minions, i)
            enemy.status = .DEAD    
        } 


        // turn_rect := rl.Rectangle {
        //     x = direction == .RIGHT ? enemy.position.x + enemy.size.x : enemy.position.x - 5,
        //     y = enemy.position.y + enemy.size.y + 2,
        //     width = 5,
        //     height = 2
        // }

        

        dvel := enemy.body.vel.x * (direction == .RIGHT ? 1 : -1)

        if abs(enemy.body.vel.x) > 0 {
            if enemy.anim_controller.animation_name != RUN {
                enemy.anim_controller.animation_name = RUN
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = Minion_animations[RUN].frame_timer
            }
        } else if abs(enemy.body.vel.x) == 0 {
            if enemy.anim_controller.animation_name != IDLE {
                enemy.anim_controller.animation_name = IDLE
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = Minion_animations[IDLE].frame_timer
            }
        }

        if enemy.status == .ALIVE {
            resolve_enemy_and_bullet(enemy, &game.player_bullets)
            enemy.body.position.x += dt * dvel 
    
            for block_collider in game.level_data.colliders {
                resolve_minion_horizontal(enemy, block_collider)
            }
        }

        enemy.body.vel.y = min(enemy.body.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.body.position.y += enemy.body.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_minion_vertical(enemy, block_collider)
        }


    }
}

enemy_take_dmg :: proc(enemy: ^Enemy_minion, bullet: Bullet) {
    enemy.stats.health_stats.current_hp -= bullet.dmg
}

enemy_minions_draw::proc (atlas: rl.Texture2D, is_debug: bool, minions: ^[dynamic]Enemy_minion, dt: f32) {
    for &minion in minions {
        minion_rect := rl.Rectangle {x = minion.body.position.x - minion.body.size.x / 2, y = minion.body.position.y - minion.body.size.y / 2, width = minion.body.size.x, height = minion.body.size.y}
        is_flip := minion.direction == .LEFT
        

        anim := Minion_animations[minion.anim_controller.animation_name]

        if minion.status == .DEAD {
            dead_sprite := SPRITE_MAP[MINION_DEAD_SPRITE]
            rl.DrawTexturePro(
                atlas, 
                rl.Rectangle {x = dead_sprite.x, y= dead_sprite.y, width = dead_sprite.w * (is_flip ? -1 : 1), height = dead_sprite.h},
                rl.Rectangle {x = minion.body.position.x, y = minion.body.position.y, width = minion.body.size.x, height = minion.body.size.y},
                minion.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            draw_animation(atlas, &minion.anim_controller, anim, MINION_SPRITE, is_flip, minion_rect, dt)
        }


        if is_debug {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = minion_rect.x + (minion.body.size.x / 2)- (full_health_width / 2), y = minion_rect.y - 7.5, width = full_health_width , height = 2.5}

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

    for &enemy in game.enemy_side.enemy_minions {
        if enemy.id == enemy_spawner.enemy_id {
            found = true

            enemy.status = .ALIVE
            enemy.direction = .RIGHT
            enemy.body.position = enemy_spawner.position
            enemy.stats = stats
            enemy.body.vel = 20

            break
        }
    }

    if !found {
        enemy := Enemy_minion {
            id = enemy_spawner.enemy_id,
            status = .ALIVE,
            body = Body {
                position = enemy_spawner.position,
                size = ENEMY_MINION_SIZE,
                vel = 20,
            },
            direction = .RIGHT,
            stats = stats,
        }
        append(&game.enemy_side.enemy_minions, enemy)
    }
}


