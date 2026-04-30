package main
import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

ENEMY_GRAVITY: f32: 120

ENEMY_AIMING_TRIGGER_DUR : f32 : 0.8
ENEMY_AIMING_SPD: f32: 0.12
ENEMY_AIMING_RADIUS: f32: 20.
ENEMY_AIMING_RELOAD_DUR :f32 : 3.

ENEMY_RANGER_RELOAD_TIME : f32 : 2.
ENEMY_RANGER_TAUNTED_RANGE: f32 : 100.
ENEMY_RANGER_TAUNTED_DUR: f32: .5

ENEMY_MELEE_TAUNTED_RANGE: f32 : 60
ENEMY_MELEE_PULSE_FORCE: f32 : 200
ENEMY_MELEE_ATTACK_TIME: f32 : 0.7
ENEMY_MELEE_PUSH_FORCE: f32: 60
ENEMY_MELEE_TAUNTED_DUR: f32: .8

ENEMY_MOVE_SPEED: f32 : 20
ENEMY_SPAWNER_SIZE: rl.Vector2 : {8, 16}
ENEMY_SPAWN_OFFSET_RANGE : f32 : 25


Enemy_buffes :: struct {

}

Enemy_melee_states :: enum {
    PARTROL,
    TAUNTED,
    ATTACK,
}

Enemy_melee_attack :: struct {
    current: f32,
    max_time : f32,
    direction: bool
}

Enemy_range_states :: enum {
    PATROL,
    TAUNTED,
    RELOAD // Tired
}



Enemy_sniper_targeting_states :: enum {
    RELOAD,
    AIMING,
    TRIGGER
}



Enemy_Body :: struct { 
    size: rl.Vector2,
    position: rl.Vector2,
    vel: rl.Vector2,
    direction : Enemy_directions
}

Enemy_melee:: struct {
    id: f32,
    body: Enemy_Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    on_ground: bool,
    anim_controller: Animation_controller,
    combat_state : Enemy_melee_states,
    taunted_timer : Timer,
    attack: Enemy_melee_attack
}

Enemy_ranger:: struct {
    taunt_range: f32,
    id: f32,
    body: Enemy_Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    on_ground: bool,
    anim_controller: Animation_controller,
    taunted_timer : Timer,
    reload: Timer,
    combat_state : Enemy_range_states

}

Enemy_sniper :: struct  {
    id: f32,
    body: Enemy_Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    on_ground: bool,
    targeting: Enemy_targeting_controller,
    combat_state: Enemy_sniper_targeting_states,

    anim_controller: Animation_controller
    
}

Enemy_status :: enum {
    DEAD,
    ALIVE,
    IS_GRAB
}

Enemy_unit_stats :: struct {
    health_stats: Health_stats,
    dmg: f32,
}

Enemy_targeting_controller :: struct {
    reload: Timer,
    trigger: Timer,
    target: rl.Vector2,
    current_aiming_point: rl.Vector2,
    aiming_radius: f32
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
                    is_enemy_dead := false
                    found := false
            
            
                    for enemy in game.enemy_side.e_melee {
                        if enemy.id == enemy_spawner.enemy_id  {
                            found = true
                            if enemy.status == .DEAD {
                                is_enemy_dead = true
                                break
                            }
                        } 
                    }
            
                    if is_enemy_dead  || !found {
                        enemy_spawner.re_spawn.time -= dt
            
                        if enemy_spawner.re_spawn.time < 0 {
                            enemy_spawner.re_spawn.time =  enemy_spawner.re_spawn.max_time
                            spawn_enemy(game, enemy_spawner)
                        }
            
                    }
                }
                case .SNIPER: {
                    is_enemy_dead := false
                    found := false
            
            
                    for enemy in game.enemy_side.e_sniper {
                        if enemy.id == enemy_spawner.enemy_id  {
                            found = true
                            if enemy.status == .DEAD {
                                is_enemy_dead = true
                                break
                            }
                        } 
                    }
            
                    if is_enemy_dead  || !found {
                        enemy_spawner.re_spawn.time -= dt
            
                        if enemy_spawner.re_spawn.time < 0 {
                            enemy_spawner.re_spawn.time =  enemy_spawner.re_spawn.max_time
                            spawn_enemy(game, enemy_spawner)
                        }
            
                    }
                }

                case .RANGER: {
                    is_enemy_dead := false
                    found := false
            
            
                    for enemy in game.enemy_side.e_ranger {
                        if enemy.id == enemy_spawner.enemy_id  {
                            found = true
                            if enemy.status == .DEAD {
                                is_enemy_dead = true
                                break
                            }
                        } 
                    }
            
                    if is_enemy_dead  || !found {
                        enemy_spawner.re_spawn.time -= dt
            
                        if enemy_spawner.re_spawn.time < 0 {
                            enemy_spawner.re_spawn.time =  enemy_spawner.re_spawn.max_time
                            spawn_enemy(game, enemy_spawner)
                        }
            
                    }
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

enemies_spawner_draw:: proc(game: Game, dt: f32) {
    spawner_size := rl.Vector2 {13, 13}
    p_sprite := SPRITE_MAP[PORTAL_SPRITE]
    p_sprite_1 := SPRITE_MAP[PORTAL_SPRITE_1]
    p_sprite_2 := SPRITE_MAP[PORTAL_SPRITE_2]
    p_dead_sprite := SPRITE_MAP[PORTAL_DEAD_SPRITE]
    p_dead_sprite_source := rl.Rectangle{x = p_dead_sprite.x, y = p_dead_sprite.y, width = p_dead_sprite.w, height = p_dead_sprite.h}
    for &enemy_spawner in game.enemy_side.enemy_spawners {
        dest := rl.Rectangle {x = enemy_spawner.position.x - spawner_size.x / 2 , y = enemy_spawner.position.y - spawner_size.y / 2, width = spawner_size.x, height = spawner_size.y}
        source_portal := rl.Rectangle {x = p_sprite.x, y = p_sprite.y, width = p_sprite.w, height = p_sprite.h}
        source_portal_1 := rl.Rectangle {x = p_sprite_1.x, y = p_sprite_1.y, width = p_sprite_1.w, height = p_sprite_1.h}
        source_portal_2 := rl.Rectangle {x = p_sprite_2.x, y = p_sprite_2.y, width = p_sprite_2.w, height = p_sprite_2.h}
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
        

        if enemy.status == .ALIVE {


            resolve_enemy_and_bullet(enemy.body, &enemy.stats.health_stats, &game.player_bullets)
            
            taunted_rect := rl.Rectangle{
                x = enemy.body.direction ==.RIGHT ? enemy.body.position.x + enemy.body.size.x / 2  : enemy.body.position.x - enemy.body.size.x / 2  - ENEMY_MELEE_TAUNTED_RANGE,
                y  = enemy.body.position.y - 20, 
                width = ENEMY_MELEE_TAUNTED_RANGE , 
                height = 30
            }

            switch enemy.combat_state {
                case .PARTROL : {
                    enemy.body.vel.x = ENEMY_MOVE_SPEED * (enemy.body.direction == .RIGHT ? 1 : -1)
                    enemy.body.position.x += dt * enemy.body.vel.x 
                    
                    if rl.CheckCollisionPointRec(game.player.body.position, taunted_rect) {
                        behind_cld := false
                        for cld in game.level_data.colliders {
                            if check_collision_line_rect(enemy.body.position, game.player.body.position, cld) {
                                behind_cld = true
                                break
                            }
                        }
                        if !behind_cld  {
                            enemy.taunted_timer.current = enemy.taunted_timer.max_time
    
                            enemy.combat_state = .TAUNTED
                        }
                    }
                    
                
                    
                }
                case .TAUNTED : {
                    enemy.body.direction = game.player.body.position.x - enemy.body.position.x > 0 ? .RIGHT : .LEFT
                    enemy.taunted_timer.current -= dt
                    
                    if enemy.taunted_timer.current > dt  && !rl.CheckCollisionPointRec(game.player.body.position, taunted_rect) {
                        if enemy.taunted_timer.current + 0.5 < enemy.taunted_timer.max_time  {

                            enemy.taunted_timer.current = enemy.taunted_timer.max_time
                            enemy.combat_state = .PARTROL
                        }
                    }
                    if enemy.taunted_timer.current <= 0 {
                        enemy.attack.current = enemy.attack.max_time
                        enemy.attack.direction = game.player.body.position.x - enemy.body.position.x > 0
                        enemy.combat_state = .ATTACK
                    }
                }
                case .ATTACK : {
                    is_flip := enemy.body.direction != .RIGHT 
                    enemy.attack.current -= dt
                    remain_scale := 0.2 + 0.8 * enemy.attack.current / enemy.attack.max_time
                    remain_force :=  ENEMY_MELEE_PULSE_FORCE * remain_scale
                    enemy.body.vel.x =  remain_force * (enemy.attack.direction ? 1 : -1) * dt
                    enemy.body.position.x += enemy.body.vel.x

                    if rl.CheckCollisionRecs(get_body_rect(game.player.body), get_enemy_body_rect(enemy.body)) {
                        player_take_dmg(&game.player.stats.health_stats, game.player.stats.buffes,enemy.stats.dmg)
                        resolve_e_mele_attack(&game.player, enemy, ENEMY_MELEE_PUSH_FORCE * remain_scale, dt)
                    }
                    
                    if enemy.attack.current <= 0 {
                        enemy.taunted_timer.current = enemy.taunted_timer.max_time
                        enemy.combat_state = .PARTROL
                    }
                    for block_collider in game.level_data.colliders {
                        front_rect := rl.Rectangle {
                            x = get_enemy_body_rect(enemy.body).x + (is_flip ? -5 : enemy.body.size.x ),
                            y = get_rect_center(get_enemy_body_rect(enemy.body)).y - 2,
                            width = 5,
                            height = 4
                        }
                        if rl.CheckCollisionRecs(block_collider, front_rect) {
                            enemy.taunted_timer.current = enemy.taunted_timer.max_time
                            enemy.combat_state = .PARTROL

                        }
                    }
                }
            }
            for block_collider in game.level_data.colliders {
                resolve_enemy_horizontal(&enemy.body, block_collider)
            }

        }
        enemy.body.vel.y = min(enemy.body.vel.y + (ENEMY_GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.body.position.y += enemy.body.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_enemy_vertical(&enemy.body, block_collider)
        }


    }
}

Enemy_melees_draw::proc (atlas: rl.Texture2D, game_options: Game_Options, e_melee: ^[dynamic]Enemy_melee, dt: f32) {
    for &enemy in e_melee {
        enemy_rect := rl.Rectangle {x = enemy.body.position.x - enemy.body.size.x / 2, y = enemy.body.position.y - enemy.body.size.y / 2, width = enemy.body.size.x, height = enemy.body.size.y}
        is_flip := enemy.body.direction != .RIGHT
        

        anim := E_melee_animations[enemy.anim_controller.animation_name]

        if enemy.status == .DEAD {
            dead_sprite := SPRITE_MAP[E_MELEE_DEAD_SPRITE]
            rl.DrawTexturePro(
                atlas, 
                get_sprite_source_rect(dead_sprite, is_flip),
                rl.Rectangle {x = enemy.body.position.x, y = enemy.body.position.y, width = enemy.body.size.x, height = enemy.body.size.y},
                enemy.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            if enemy.combat_state == .PARTROL {
                if enemy.anim_controller.animation_name != RUN_ANI {
                    enemy.anim_controller.animation_name = RUN_ANI
                    enemy.anim_controller.current_frame = 0
                    enemy.anim_controller.current_timer = E_melee_animations[RUN_ANI].frame_timer
                }
                draw_animation(atlas, &enemy.anim_controller, anim, E_MELEE_SPRITE, is_flip, enemy_rect, dt)

            } else if enemy.combat_state == .ATTACK {
                if enemy.anim_controller.animation_name != ATTACK_ANI {
                    enemy.anim_controller.animation_name = ATTACK_ANI
                    enemy.anim_controller.current_frame = 0
                    enemy.anim_controller.current_timer = E_melee_animations[ATTACK_ANI].frame_timer
                }
                draw_animation(atlas, &enemy.anim_controller, anim, E_MELEE_SPRITE, is_flip, enemy_rect, dt)
            } else if enemy.combat_state == .TAUNTED {
                
                taunted_sprite := SPRITE_MAP[E_MELEE_TAUNTED_SPRITE]
                taunted_source := get_sprite_source_rect(taunted_sprite, is_flip)
                // taunted_aura_sprte_source := rl.Rectangle {x = taunted_aura_sprite.x, y= taunted_aura_sprite.y, width = taunted_aura_sprite.w, height = taunted_aura_sprite.h}
                // taunted_aura_sprite_dest := rl.Rectangle {x = enemy_rect.x + enemy_rect.width - 10, y = enemy_rect.y - 10, width = 16, height = 16}
                rl.DrawTexturePro(atlas, taunted_source, enemy_rect, {0, 0}, 0, rl.WHITE)
                unit_expression_draw(atlas, SPRITE_MAP[E_TAUNTED_AURA_SPRITE], enemy.body.position + {8, -8})
                // rl.DrawTexturePro(atlas, taunted_aura_sprte_source, taunted_aura_sprite_dest, {0, 0}, 0, rl.WHITE)
                // draw_animation(atlas, &enemy.anim_controller, anim, E_MELEE_SPRITE, is_flip, enemy_rect, dt)
            }
        }


        if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = enemy_rect.x + (enemy.body.size.x / 2)- (full_health_width / 2), y = enemy_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = enemy.stats.health_stats.current_hp / enemy.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
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
       

        if enemy.status == .ALIVE {
            resolve_enemy_and_bullet(enemy.body, &enemy.stats.health_stats, &game.player_bullets)
            if enemy.combat_state == .AIMING {
                enemy.targeting.target = game.player.body.position
                // player_pos := game.player.body.position
                enemy.targeting.current_aiming_point += (enemy.targeting.target - enemy.targeting.current_aiming_point) * dt * ( 1 + ENEMY_AIMING_SPD )
        
                if rl.CheckCollisionPointCircle(game.player.body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                    enemy.targeting.trigger.current = enemy.targeting.trigger.max_time
                    enemy.targeting.current_aiming_point = game.player.body.position
                    enemy.combat_state = .TRIGGER
                }
            } else if enemy.combat_state == .TRIGGER{
                enemy.targeting.trigger.current -= dt
                sprite := SPRITE_MAP[E_SNIPER_PARTICLE_SPRITE]
                sprite_source := get_sprite_source_rect(sprite)
                if enemy.targeting.trigger.current <=0 {
                    if rl.CheckCollisionPointCircle(game.player.body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                        player_take_dmg(&game.player.stats.health_stats, game.player.stats.buffes, enemy.stats.dmg)
                    }
    
                    add_particle(&game.particle_system, Particle {
                        timer = {current = 0.2, max_time = 0.3},
                        position = enemy.targeting.current_aiming_point,
                        sprite_source = sprite_source,
                        is_blur = true,
                        is_scaled = true,
                        size = {32, 32}
                    })
                    enemy.targeting.current_aiming_point = enemy.body.position
    
                    enemy.targeting.reload.current = enemy.targeting.reload.max_time
                    enemy.combat_state = .RELOAD
                }
            } else {
                enemy.targeting.reload.current -= dt
                if enemy.targeting.reload.current <= 0 {
                    enemy.combat_state =.AIMING
                }
            }
        }

        // enemy.body.vel.y = min(enemy.body.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
            
        // enemy.body.position.y += enemy.body.vel.y * dt
        // for block_collider in game.level_data.colliders {
        //     resolve_enemy_vertical(&enemy.body, block_collider)
        // }

    }
}

Enemy_sniper_draw:: proc(atlas: rl.Texture2D, game_options: Game_Options, e_sniper: ^[dynamic]Enemy_sniper, dt: f32) {
    for &enemy in e_sniper {
        enemy_rect := rl.Rectangle {x = enemy.body.position.x - enemy.body.size.x / 2, y = enemy.body.position.y - enemy.body.size.y / 2, width = enemy.body.size.x, height = enemy.body.size.y}
        is_flip := enemy.body.direction != .RIGHT
        

        anim := E_sniper_animations[enemy.anim_controller.animation_name]
        if enemy.status == .DEAD {
            dead_sprite := SPRITE_MAP[E_SINPER_DEAD_SPIPER]
            rl.DrawTexturePro(
                atlas, 
                get_sprite_source_rect(dead_sprite, is_flip),
                rl.Rectangle {x = enemy.body.position.x, y = enemy.body.position.y, width = enemy.body.size.x, height = enemy.body.size.y},
                enemy.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            if abs(enemy.body.vel.x) == 0 {
                if enemy.anim_controller.animation_name != IDLE_ANI {
                    enemy.anim_controller.animation_name = IDLE_ANI
                    enemy.anim_controller.current_frame = 0
                    enemy.anim_controller.current_timer = E_sniper_animations[IDLE_ANI].frame_timer
                }
            }
            draw_animation(atlas, &enemy.anim_controller, anim, E_SNIPER_SPRITE, is_flip, enemy_rect, dt)
        }


        if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = enemy_rect.x + (enemy.body.size.x / 2)- (full_health_width / 2), y = enemy_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = enemy.stats.health_stats.current_hp / enemy.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
        switch enemy.combat_state {
            case .RELOAD : {
                unit_expression_draw(atlas, SPRITE_MAP[E_RELOAD_AURA_SPRITE], enemy.body.position + {8, -8})
            }
            case .AIMING : {
                sprite := SPRITE_MAP[E_SNIPER_AIMING_SPRITE]
                sprite_source := get_sprite_source_rect(sprite)
                sprite_dest := rl.Rectangle {x = enemy.targeting.current_aiming_point.x, y = enemy.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS, height = ENEMY_AIMING_RADIUS}
                rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS / 2, ENEMY_AIMING_RADIUS / 2}, 0, rl.WHITE)
            }
            case .TRIGGER : {
                sprite := SPRITE_MAP[E_SNIPER_TRIGGER_SPRITE]
                sprite_source := get_sprite_source_rect(sprite)
                sprite_scale :f32 = 1. +  0.6 * (enemy.targeting.trigger.current / enemy.targeting.trigger.max_time)
                sprite_dest := rl.Rectangle {x = enemy.targeting.current_aiming_point.x, y = enemy.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS * sprite_scale, height = ENEMY_AIMING_RADIUS * sprite_scale}
                rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS * sprite_scale / 2, ENEMY_AIMING_RADIUS * sprite_scale / 2}, 0, rl.WHITE)
            }
        }
         if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = enemy_rect.x + (enemy.body.size.x / 2)- (full_health_width / 2), y = enemy_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = enemy.stats.health_stats.current_hp / enemy.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
        // rl.DrawCircleV(enemy.targeting.current_aiming_point, enemy.targeting.aiming_radius, rl.RED)
    } 
}
Enemy_ranger_update :: proc (game: ^Game, dt: f32) {
    for i:= len(game.enemy_side.e_ranger) - 1; i >=0; i -= 1 {
         enemy := &game.enemy_side.e_ranger[i]


        if enemy.stats.health_stats.current_hp <= 0 {
            // unordered_remove(&game.Enemy_melees, i)
            enemy.status = .DEAD    
        } 
        if enemy.status == .ALIVE {


            resolve_enemy_and_bullet(enemy.body, &enemy.stats.health_stats, &game.player_bullets)

            switch enemy.combat_state {
                case .PATROL : {
                    under_rect := rl.Rectangle {x = get_rect_center(get_enemy_body_rect(enemy.body)).x - 10, y = enemy.body.position.y + enemy.body.size.y + 2, width = 20, height = 3}
                    front_rect := rl.Rectangle {x = get_rect_center(get_enemy_body_rect(enemy.body)).x + (enemy.body.direction == .RIGHT ? enemy.body.size.x / 2 + 2 : - enemy.body.size.x / 2 - 10 - 2 ), y = enemy.body.position.y + enemy.body.size.y + 2, width = 10, height = 3}
                    for block_collider in game.level_data.colliders {
                        if !rl.CheckCollisionRecs(under_rect, block_collider) do continue
                        if !rl.CheckCollisionRecs(front_rect, block_collider) {
                            enemy.body.direction = enemy.body.direction == .RIGHT ? .LEFT : .RIGHT
                        } 
                    }
                    
                    taunted_rect := rl.Rectangle {width = ENEMY_RANGER_TAUNTED_RANGE, height = 10, x = enemy.body.position.x + (enemy.body.direction == .RIGHT ? enemy.body.size.x / 2 : -enemy.body.size.x / 2 - ENEMY_RANGER_TAUNTED_RANGE), y = enemy.body.position.y - 5}
                    
                    if rl.CheckCollisionPointRec(game.player.body.position, taunted_rect) {
                        behind_cld := false
                        for cld in game.level_data.colliders {
                            if check_collision_line_rect(enemy.body.position, game.player.body.position, cld) {
                                behind_cld = true
                                break
                            }
                        }
                        if !behind_cld  {
                            enemy.taunted_timer.current = enemy.taunted_timer.max_time
                            
                            enemy.combat_state = .TAUNTED
                        }
                    }
                    
                    enemy.body.vel.x = ENEMY_MOVE_SPEED * (enemy.body.direction == .RIGHT ? 1 : -1)
                    enemy.body.position.x += enemy.body.vel.x * dt


                }
                case .TAUNTED : {
                    enemy.taunted_timer.current -= dt 
                    if enemy.taunted_timer.current <= 0 {
                        e_ranger_shoot(&game.enemy_side.enemy_bullets, enemy.body, enemy.stats.dmg)
                        enemy.reload.current = enemy.reload.max_time
                        enemy.combat_state = .RELOAD
                    }
                }

                case .RELOAD : {
                    enemy.reload.current -= dt
                    if enemy.reload.current <= 0 {
                        enemy.combat_state = .PATROL
                    }
                }
            }

             for block_collider in game.level_data.colliders {
                resolve_enemy_horizontal(&enemy.body, block_collider)
            }
        }

        enemy.body.vel.y = min(enemy.body.vel.y + (ENEMY_GRAVITY * dt), MAX_FALL_SPEED)
            
        enemy.body.position.y += enemy.body.vel.y * dt
        for block_collider in game.level_data.colliders {
            resolve_enemy_vertical(&enemy.body, block_collider)
        }
    }
}

Enemy_ranger_draw :: proc(atlas: rl.Texture2D, game_options: Game_Options, e_rangers: ^[dynamic]Enemy_ranger, dt: f32) {
    for &enemy in e_rangers {
        enemy_rect := rl.Rectangle {x = enemy.body.position.x - enemy.body.size.x / 2, y = enemy.body.position.y - enemy.body.size.y / 2, width = enemy.body.size.x, height = enemy.body.size.y}
        is_flip := enemy.body.direction != .RIGHT
        anim := E_ranger_animations[enemy.anim_controller.animation_name]
      
        
        if enemy.status == .DEAD {
            dead_sprite := SPRITE_MAP[E_RANGER_DEAD_SPRITE]
            rl.DrawTexturePro(
                atlas, 
                get_sprite_source_rect(dead_sprite, is_flip),
                rl.Rectangle {x = enemy.body.position.x, y = enemy.body.position.y, width = enemy.body.size.x, height = enemy.body.size.y},
                enemy.body.size / 2,
                0,
                rl.WHITE
            )
        } else {
            if enemy.combat_state == .PATROL {
                if enemy.anim_controller.animation_name != RUN_ANI {
                    enemy.anim_controller.animation_name = RUN_ANI
                    enemy.anim_controller.current_frame = 0
                    enemy.anim_controller.current_timer = E_melee_animations[RUN_ANI].frame_timer
                }
                draw_animation(atlas, &enemy.anim_controller, anim, E_RANGER_SPRITE, is_flip, enemy_rect, dt)

            } else if enemy.combat_state == .TAUNTED {
                taunted_sprite := SPRITE_MAP[E_RANGER_TAUNTED_SPRITE]
                taunted_sprite_source := get_sprite_source_rect(taunted_sprite, is_flip)
                
                rl.DrawTexturePro(atlas, taunted_sprite_source, enemy_rect, 0, 0, rl.WHITE)
                unit_expression_draw(atlas, SPRITE_MAP[E_TAUNTED_AURA_SPRITE], enemy.body.position + {8, -8})

            } else if enemy.combat_state == .RELOAD{
                if enemy.anim_controller.animation_name != RELOAD_ANI {
                    enemy.anim_controller.animation_name = RELOAD_ANI
                    enemy.anim_controller.current_frame = 0
                    enemy.anim_controller.current_timer = E_melee_animations[RELOAD_ANI].frame_timer
                }
                
                draw_animation(atlas, &enemy.anim_controller, anim, E_RANGER_SPRITE, is_flip, enemy_rect, dt)

                unit_expression_draw(atlas, SPRITE_MAP[E_RELOAD_AURA_SPRITE], enemy.body.position + {8, -8})
            }
        }
        if game_options.is_debug || game_options.is_health_bar {
            full_health_width : f32 = 20

            full_health_rect := rl.Rectangle {x = enemy_rect.x + (enemy.body.size.x / 2)- (full_health_width / 2), y = enemy_rect.y - 7.5, width = full_health_width , height = 2.5}

            health_rect := rl.Rectangle {x = full_health_rect.x, y = full_health_rect.y, width = enemy.stats.health_stats.current_hp / enemy.stats.health_stats.max_hp * full_health_width , height = full_health_rect.height}
            rl.DrawRectangleLinesEx(full_health_rect, 0.25, rl.WHITE)
            rl.DrawRectangleRec(health_rect, rl.RED)
        }
    }

}

spawn_enemy:: proc(game: ^Game, enemy_spawner: Enemy_spawner_pot) {
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
               
                    enemy.body.position = enemy_spawner.position
                    enemy.body.direction = .RIGHT
                    enemy.stats = stats
                    enemy.body.vel = 20
        
                    break
                }
            }
        
            if !found {
                enemy := Enemy_melee {
                    id = enemy_spawner.enemy_id,
                    status = .ALIVE,
                    body = {
                        position = enemy_spawner.position,
                        size = Enemy_melee_SIZE,
                        direction = .RIGHT,
                        vel = 20,
                    },
                    taunted_timer = {
                        max_time = ENEMY_MELEE_TAUNTED_DUR,
                        current = ENEMY_MELEE_TAUNTED_DUR
                    },
                    attack = {
                        current = ENEMY_MELEE_ATTACK_TIME,
                        max_time = ENEMY_MELEE_ATTACK_TIME,
                    },
                    combat_state = .PARTROL,
                    stats = stats,
                }
                append(&game.enemy_side.e_melee, enemy)
            }

        }
        case .SNIPER : {

            spawn_offset_angle := rand.float32() * 360
            spawn_offset := rl.Vector2 {ENEMY_SPAWN_OFFSET_RANGE * math.sin_f32(spawn_offset_angle), ENEMY_SPAWN_OFFSET_RANGE * math.cos_f32(spawn_offset_angle)}

            for &enemy in game.enemy_side.e_sniper {
                if enemy.id == enemy_spawner.enemy_id {
                    
                    found = true
        
                    enemy.status = .ALIVE
                    enemy.body.position = enemy_spawner.position + spawn_offset
                    enemy.combat_state = .RELOAD
                    enemy.stats = stats
                    enemy.targeting.reload.current = 0.5
                    enemy.targeting.current_aiming_point = enemy_spawner.position + spawn_offset
                    enemy.body.vel = 0
        
                    break
                }
            }
        
            if !found {
                enemy := Enemy_sniper {
                    id = enemy_spawner.enemy_id,
                    status = .ALIVE,
                    body = Enemy_Body {
                        position = enemy_spawner.position + spawn_offset,
                        size = Enemy_melee_SIZE,
                        direction = .RIGHT,
                        vel = 0,
                    },
                 
                    stats = stats,
                    combat_state = .RELOAD,
                    
                    targeting = {
                        aiming_radius = ENEMY_AIMING_RADIUS,
                        reload = {
                            current = 0.5,
                            max_time = ENEMY_AIMING_RELOAD_DUR
                        },
                        trigger = {
                            current = ENEMY_AIMING_TRIGGER_DUR,
                            max_time = ENEMY_AIMING_TRIGGER_DUR
                        },
                        target = game.player.body.position,
                        current_aiming_point = enemy_spawner.position + spawn_offset

                    }
                }
                append(&game.enemy_side.e_sniper, enemy)
            }
        }
        case .RANGER : {
            for &enemy in game.enemy_side.e_ranger {
                if enemy.id == enemy_spawner.enemy_id {
                    
                    found = true
        
                    enemy.status = .ALIVE
                    enemy.body.position = enemy_spawner.position 
                    enemy.stats = stats
                    enemy.body.vel = 20
        
                    break
                }
            }
        
            if !found {
                enemy := Enemy_ranger {
                    id = enemy_spawner.enemy_id,
                    status = .ALIVE,
                    body = Enemy_Body {
                        position = enemy_spawner.position ,
                        size = Enemy_melee_SIZE,
                        vel = 20,
                        direction = .RIGHT
                    },
                    stats = stats,
                    taunted_timer = {
                        max_time = ENEMY_RANGER_TAUNTED_DUR,
                        current = ENEMY_RANGER_TAUNTED_DUR
                    },
                    reload = {
                        current = ENEMY_RANGER_RELOAD_TIME,
                        max_time = ENEMY_RANGER_RELOAD_TIME
                    },
                    combat_state = .PATROL,
                   
                }
                append(&game.enemy_side.e_ranger, enemy)
            }
        }
    }
}

e_ranger_shoot :: proc(enemy_bullet : ^[dynamic]Bullet, enemy_body: Enemy_Body, dmg: f32) {
    append(enemy_bullet, Bullet {
        direction = enemy_body.direction == .RIGHT ? .RIGHT : .LEFT,
        dmg = dmg,
        position = enemy_body.position,
        is_exploded = true
    })
}
