package main
import rl "vendor:raylib"
// import "core:fmt"
import "core:math"

ENEMY_AIMING_TRIGGER_DUR : f32 : 0.8
ENEMY_AIMING_SPD: f32: 0.12
ENEMY_AIMING_RADIUS: f32: 20.
ENEMY_AIMING_MAX_RELOAD :f32 : 3.
ENEMY_TAUNT_RANGE: f32 : 20
ENEMY_SPAWNER_SIZE: rl.Vector2 : {8, 16}

Enemy_sniper_targeting_status :: enum {
    RELOAD,
    AIMING,
    TRIGGER
}

Enemy_aiming_trigger :: struct {
    max_time: f32,
    current: f32
}

Enemy_melee:: struct {
    id: f32,
    body: Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    direction: Enemy_directions,
    on_ground: bool,
    is_flip: bool,
    anim_controller: Animation_controller
}

Enemy_ranger:: struct {
    taunt_range: f32,
    id: f32,
    body: Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    direction: Enemy_directions,
    on_ground: bool,
    is_flip: bool,
    anim_controller: Animation_controller
}

Enemy_sniper :: struct  {
    id: f32,
    body: Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    direction: Enemy_directions,
    on_ground: bool,
    is_flip: bool,
    targeting: Enemy_targeting_controller,
    anim_controller: Animation_controller
    
}

Enemy_status :: enum {
    DEAD,
    ALIVE
}

Enemy_unit_stats :: struct {
    health_stats: Health_stats,
    dmg: f32,
}

Enemy_targeting_controller :: struct {
    status: Enemy_sniper_targeting_status,
    reload: Aming_reload,
    trigger: Enemy_aiming_trigger,
    target: rl.Vector2,
    current_aiming_point: rl.Vector2,
    aiming_radius: f32
}

Aming_reload :: struct {
    max_time: f32,
    current_time: f32
}

enemies_spawner_update:: proc(game: ^Game, dt: f32) {

    if game.game_options.is_paused {
        return
    }

    for &enemy_spawner in game.enemy_side.enemy_spawners {
        if enemy_spawner.hp_stats.current_hp > 0 {
            resolve_spawner_and_bullet(&enemy_spawner, &game.player_bullets)
            switch enemy_spawner.enemy_type {
                case .MELEE : {
                    is_minion_dead := false
                    found := false
            
            
                    for minion in game.enemy_side.e_melee {
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
                case .SNIPER: {
                    is_minion_dead := false
                    found := false
            
            
                    for minion in game.enemy_side.e_sniper {
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

                case .RANGER: {

                }
            }

        } else {
            if enemy_spawner.re_contruct.time < 0 {
                enemy_spawner.re_contruct.time = enemy_spawner.re_contruct.max_time
                enemy_spawner.hp_stats.current_hp = enemy_spawner.hp_stats.max_hp
            }  else {
                enemy_spawner.re_contruct.time -= dt
            }
        }

    }

}

enemies_draw:: proc(game: Game, dt: f32) {
    spawner_size := rl.Vector2 {13, 13}
    p_sprite := SPRITE_MAP[PORTAL_SPRITE]
    p_sprite_1 := SPRITE_MAP[PORTAL_SPRITE_1]
    p_sprite_2 := SPRITE_MAP[PORTAL_SPRITE_2]
    p_dead_sprite := SPRITE_MAP[PORTAL_DEAD_SPRITE]
    status_sprite := SPRITE_MAP[PORTAL_STATUS_SPRITE]
    p_dead_sprite_source := rl.Rectangle{x = p_dead_sprite.x, y = p_dead_sprite.y, width = p_dead_sprite.w, height = p_dead_sprite.h}
    for &enemy_spawner in game.enemy_side.enemy_spawners {
        dest := rl.Rectangle {x = enemy_spawner.position.x - spawner_size.x / 2 , y = enemy_spawner.position.y - spawner_size.y / 2, width = spawner_size.x, height = spawner_size.y}
        source_portal := rl.Rectangle {x = p_sprite.x, y = p_sprite.y, width = p_sprite.w, height = p_sprite.h}
        source_portal_1 := rl.Rectangle {x = p_sprite_1.x, y = p_sprite_1.y, width = p_sprite_1.w, height = p_sprite_1.h}
        source_portal_2 := rl.Rectangle {x = p_sprite_2.x, y = p_sprite_2.y, width = p_sprite_2.w, height = p_sprite_2.h}
        source_status := rl.Rectangle {x = status_sprite.x, y = status_sprite.y, width = status_sprite.w, height = status_sprite.h}
        anime := Portal_animations[enemy_spawner.anim_controller.animation_name]
        if enemy_spawner.hp_stats.current_hp <= 0 {
            
            rl.DrawTexturePro(game.game_sprite_atlas,  p_dead_sprite_source, dest, {0,0}, 0, rl.WHITE)
        } else {
            draw_animation(game.game_sprite_atlas, &enemy_spawner.anim_controller, anime, PORTAL_SPRITE, false, dest, dt)
        }
        dest_1 := dest
        dest_1.y += f32(.25 * math.sin(rl.GetTime() ))
        rl.DrawTexturePro(game.game_sprite_atlas, source_portal_1, dest_1, {0,0}, 0, rl.WHITE)

        dest_2 := dest
        dest_2.y += f32(.5 * math.cos(rl.GetTime() ))
        rl.DrawTexturePro(game.game_sprite_atlas, source_portal_2, dest_2, {0, 0}, 0, rl.WHITE)
        // rl.DrawCircleLinesV(enemy_spawner.position, 4, rl.BLACK)

        status_dest := rl.Rectangle {x =  enemy_spawner.position.x, y = enemy_spawner.position.y - 10, width = 12, height = 12}
        rl.DrawTexturePro(game.game_sprite_atlas, source_status, status_dest, {6,6}, 0, enemy_spawner.hp_stats.current_hp <= 0 ? rl.GREEN : rl.RED)


        if game.game_options.is_debug {
            respawn_ui_height :f32 = 10
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(respawn_ui_height), rl.WHITE)
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(enemy_spawner.re_spawn.time / enemy_spawner.re_spawn.max_time * respawn_ui_height), rl.BLUE)
            
        }
    }


}

Enemy_melees_update::proc (game: ^Game, dt: f32) {
    

    for i:= len(game.enemy_side.e_melee) - 1; i >=0; i -= 1 {
        enemy := &game.enemy_side.e_melee[i]


        if enemy.stats.health_stats.current_hp <= 0 {
            // unordered_remove(&game.Enemy_melees, i)
            enemy.status = .DEAD    
        } 
        if abs(enemy.body.vel.x) > 0 {
            if enemy.anim_controller.animation_name != RUN_ANI {
                enemy.anim_controller.animation_name = RUN_ANI
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = E_melee_animations[RUN_ANI].frame_timer
            }
        } else if abs(enemy.body.vel.x) == 0 {
            if enemy.anim_controller.animation_name != IDLE_ANI {
                enemy.anim_controller.animation_name = IDLE_ANI
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = E_melee_animations[IDLE_ANI].frame_timer
            }
        }

        if enemy.status == .ALIVE {
            resolve_enemy_and_bullet(enemy.body, &enemy.stats.health_stats, &game.player_bullets)
            enemy.body.position.x += dt * enemy.body.vel.x 
    
            for block_collider in game.level_data.colliders {
                resolve_minion_horizontal(&enemy.body, block_collider)
            }
        }

        enemy.body.vel.y = min(enemy.body.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.body.position.y += enemy.body.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_minion_vertical(&enemy.body, block_collider)
        }


    }
}

Enemy_melees_draw::proc (atlas: rl.Texture2D, game_options: Game_Options, e_melee: ^[dynamic]Enemy_melee, dt: f32) {
    for &minion in e_melee {
        minion_rect := rl.Rectangle {x = minion.body.position.x - minion.body.size.x / 2, y = minion.body.position.y - minion.body.size.y / 2, width = minion.body.size.x, height = minion.body.size.y}
        is_flip := minion.body.vel.x < 0
        

        anim := E_melee_animations[minion.anim_controller.animation_name]

        if minion.status == .DEAD {
            dead_sprite := SPRITE_MAP[E_MELLY_DEAD_SPRITE]
            rl.DrawTexturePro(
                atlas, 
                rl.Rectangle {x = dead_sprite.x, y= dead_sprite.y, width = dead_sprite.w * (is_flip ? -1 : 1), height = dead_sprite.h},
                rl.Rectangle {x = minion.body.position.x, y = minion.body.position.y, width = minion.body.size.x, height = minion.body.size.y},
                minion.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            draw_animation(atlas, &minion.anim_controller, anim, E_MELEE_SPRITE, is_flip, minion_rect, dt)
        }


        if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = minion_rect.x + (minion.body.size.x / 2)- (full_health_width / 2), y = minion_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = minion.stats.health_stats.current_hp / minion.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
    } 

}

Enemy_sniper_update:: proc(game: ^Game, dt: f32) {
    for i:= len(game.enemy_side.e_sniper) - 1; i >=0; i -= 1 {
        enemy := &game.enemy_side.e_sniper[i]


        if enemy.stats.health_stats.current_hp <= 0 {
            // unordered_remove(&game.Enemy_melees, i)
            enemy.status = .DEAD    
        } 
        if abs(enemy.body.vel.x) > 0 {
            if enemy.anim_controller.animation_name != RUN_ANI {
                enemy.anim_controller.animation_name = RUN_ANI
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = E_melee_animations[RUN_ANI].frame_timer
            }
        } else if abs(enemy.body.vel.x) == 0 {
            if enemy.anim_controller.animation_name != IDLE_ANI {
                enemy.anim_controller.animation_name = IDLE_ANI
                enemy.anim_controller.current_frame = 0
                enemy.anim_controller.current_timer = E_melee_animations[IDLE_ANI].frame_timer
            }
        }

        if enemy.status == .ALIVE {
            resolve_enemy_and_bullet(enemy.body, &enemy.stats.health_stats, &game.player_bullets)

            enemy.body.position.x += dt * enemy.body.vel.x 
    
            for block_collider in game.level_data.colliders {
                resolve_minion_horizontal(&enemy.body, block_collider)
            }
            if enemy.targeting.status == .AIMING {
                enemy.targeting.target = game.player.body.position
                // player_pos := game.player.body.position
                enemy.targeting.current_aiming_point += (enemy.targeting.target - enemy.targeting.current_aiming_point) * dt * ( 1 + ENEMY_AIMING_SPD )
        
                if rl.CheckCollisionPointCircle(game.player.body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                    enemy.targeting.trigger.current = enemy.targeting.trigger.max_time
                    enemy.targeting.current_aiming_point = game.player.body.position
                    enemy.targeting.status = .TRIGGER
                }
            } else if enemy.targeting.status == .TRIGGER{
                enemy.targeting.trigger.current -= dt
                if enemy.targeting.trigger.current <=0 {
                    if rl.CheckCollisionPointCircle(game.player.body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                        game.player.stats.health_stats.current_hp -= enemy.stats.dmg
                    }
    
                    enemy.targeting.current_aiming_point = enemy.body.position
    
                    enemy.targeting.reload.current_time = enemy.targeting.reload.max_time
                    enemy.targeting.status = .RELOAD
                }
            } else {
                enemy.targeting.reload.current_time -= dt
                if enemy.targeting.reload.current_time <= 0 {
                    enemy.targeting.status =.AIMING
                }
            }
        }

        enemy.body.vel.y = min(enemy.body.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.body.position.y += enemy.body.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_minion_vertical(&enemy.body, block_collider)
        }

    }
}

Enemy_sniper_draw:: proc(atlas: rl.Texture2D, game_options: Game_Options, e_sniper: ^[dynamic]Enemy_sniper, dt: f32) {
    for &minion in e_sniper {
        minion_rect := rl.Rectangle {x = minion.body.position.x - minion.body.size.x / 2, y = minion.body.position.y - minion.body.size.y / 2, width = minion.body.size.x, height = minion.body.size.y}
        is_flip := minion.body.vel.x < 0
        

        anim := E_sniper_animations[minion.anim_controller.animation_name]

        if minion.status == .DEAD {
            dead_sprite := SPRITE_MAP[E_SINPER_DEAD_SPIPER]
            rl.DrawTexturePro(
                atlas, 
                rl.Rectangle {x = dead_sprite.x, y= dead_sprite.y, width = dead_sprite.w * (is_flip ? -1 : 1), height = dead_sprite.h},
                rl.Rectangle {x = minion.body.position.x, y = minion.body.position.y, width = minion.body.size.x, height = minion.body.size.y},
                minion.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            draw_animation(atlas, &minion.anim_controller, anim, E_SNIPER_SPRITE, is_flip, minion_rect, dt)
        }


        if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = minion_rect.x + (minion.body.size.x / 2)- (full_health_width / 2), y = minion_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = minion.stats.health_stats.current_hp / minion.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
        switch minion.targeting.status {
            case .RELOAD : {
                sprite := SPRITE_MAP[E_SNIPER_RELOAD_SPRITE]
                sprite_source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
                sprite_dest := rl.Rectangle {x = minion.body.position.x, y = minion.body.position.y - 15, width = 15, height = 15}
                rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {7.5, 7.5}, 0, rl.WHITE)
            }
            case .AIMING : {
                sprite := SPRITE_MAP[E_SNIPER_AIMING_SPRITE]
                sprite_source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
                sprite_dest := rl.Rectangle {x = minion.targeting.current_aiming_point.x, y = minion.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS, height = ENEMY_AIMING_RADIUS}
                rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS / 2, ENEMY_AIMING_RADIUS / 2}, 0, rl.WHITE)
            }
            case .TRIGGER : {
                sprite := SPRITE_MAP[E_SNIPER_TRIGGER_SPRITE]
                sprite_source := rl.Rectangle{x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
                sprite_scale :f32 = 1. +  0.6 * (minion.targeting.trigger.current / minion.targeting.trigger.max_time)
                sprite_dest := rl.Rectangle {x = minion.targeting.current_aiming_point.x, y = minion.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS * sprite_scale, height = ENEMY_AIMING_RADIUS * sprite_scale}
                rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS * sprite_scale / 2, ENEMY_AIMING_RADIUS * sprite_scale / 2}, 0, rl.WHITE)
            }
        }
        // rl.DrawCircleV(minion.targeting.current_aiming_point, minion.targeting.aiming_radius, rl.RED)
    } 
}

spawn_minion:: proc(game: ^Game, enemy_spawner: Enemy_spawner_pot) {
    stats := Enemy_unit_stats {
        health_stats = {
            max_hp = 100,
            current_hp = 100
        },
        dmg = 25
    }
    found := false
    switch enemy_spawner.enemy_type {
        case .MELEE : {
            for &enemy in game.enemy_side.e_melee {
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
                enemy := Enemy_melee {
                    id = enemy_spawner.enemy_id,
                    status = .ALIVE,
                    body = Body {
                        position = enemy_spawner.position,
                        size = Enemy_melee_SIZE,
                        vel = 20,
                    },
                    direction = .RIGHT,
                    stats = stats,
                }
                append(&game.enemy_side.e_melee, enemy)
            }

        }
        case .SNIPER : {
            for &enemy in game.enemy_side.e_sniper {
                if enemy.id == enemy_spawner.enemy_id {
                    found = true
        
                    enemy.status = .ALIVE
                    enemy.direction = .RIGHT
                    enemy.body.position = enemy_spawner.position
                    enemy.stats = stats
                    enemy.body.vel = 0
        
                    break
                }
            }
        
            if !found {
                enemy := Enemy_sniper {
                    id = enemy_spawner.enemy_id,
                    status = .ALIVE,
                    body = Body {
                        position = enemy_spawner.position + enemy_spawner.spawn_offset,
                        size = Enemy_melee_SIZE,
                        vel = 0,
                    },
                    direction = .RIGHT,
                    stats = stats,
                    targeting = {
                        status = .RELOAD,
                        aiming_radius = ENEMY_AIMING_RADIUS,
                        reload = {
                            current_time = 0.5,
                            max_time = ENEMY_AIMING_MAX_RELOAD
                        },
                        trigger = {
                            current = ENEMY_AIMING_TRIGGER_DUR,
                            max_time = ENEMY_AIMING_TRIGGER_DUR
                        },
                        target = game.player.body.position,
                        current_aiming_point = enemy_spawner.position

                    }
                }
                append(&game.enemy_side.e_sniper, enemy)
            }
        }
        case .RANGER : {

        }
    }
}


