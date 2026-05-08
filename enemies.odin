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
ENEMY_SPAWN_OFFSET_RANGE : f32 : 15

Enemy_spawner_state :: enum {
    EXIST,
    COUNT_DOWN
}
Enemy_directions :: enum {
    LEFT, 
    RIGHT
}

Enemy_types :: enum {
    MELEE,
    RANGER,
    SNIPER
}

Enemy_buffes :: struct {

}



Enemy_attack :: struct {
    current: f32,
    max_time : f32,
    direction: bool
}





Enemy_unit_states :: enum {
    PARTROL,
    TAUNTED,
    ATTACK,
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


Enemy_unit :: struct {
    id: f32,
    enemy_type : Enemy_types,
    body: Enemy_Body,
    status: Enemy_status,
    stats : Enemy_unit_stats,
    on_ground: bool,
    combat_state: Enemy_unit_states,
    taunted_timer : Timer,
    anim_controller: Animation_controller,
    targeting: Enemy_targeting_controller,
    attack: Enemy_attack,
    reload: Timer
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
            
            found := false
            is_enemy_dead := false
            for enemy in game.enemy_side.enemy_units {
                if enemy.id == enemy_spawner.enemy_id  {
                    found = true
                    if enemy.status == .DEAD {
                        is_enemy_dead = true
                        break
                    }
                } 
            }
            
            if is_enemy_dead  || !found {
                enemy_spawner.re_spawn.current -= dt
    
                if enemy_spawner.re_spawn.current < 0 {
                    enemy_spawner.re_spawn.current =  enemy_spawner.re_spawn.max_time
                    spawn_enemy(game, enemy_spawner)
                }
    
            }
               
        }else {
            if enemy_spawner.re_contruct.current < 0 {
                enemy_spawner.re_contruct.current = enemy_spawner.re_contruct.max_time
                enemy_spawner.hp_stats.current_hp = enemy_spawner.hp_stats.max_hp
            }  else {
                enemy_spawner.re_contruct.current -= dt
            }
        }

        

    }

}

enemies_spawner_draw:: proc(atlas: rl.Texture2D, spawners: []Enemy_spawner_pot, is_debug: bool, dt: f32) {
    spawner_size := rl.Vector2 {13, 13}
    p_sprite := SPRITE_MAP[PORTAL_SPRITE]
    p_sprite_1 := SPRITE_MAP[PORTAL_SPRITE_1]
    p_sprite_2 := SPRITE_MAP[PORTAL_SPRITE_2]
  
    p_dead_sprite_source := get_sprite_source_rect(SPRITE_MAP[PORTAL_DEAD_SPRITE])
    for &enemy_spawner in spawners {
        dest := rl.Rectangle {x = enemy_spawner.position.x - spawner_size.x / 2 , y = enemy_spawner.position.y - spawner_size.y / 2, width = spawner_size.x, height = spawner_size.y}
        source_portal := get_sprite_source_rect(p_sprite)
        source_portal_1 := get_sprite_source_rect(p_sprite_1)
        source_portal_2 := get_sprite_source_rect(p_sprite_2)
        anime := Portal_animations[enemy_spawner.anim_controller.animation_name]
        if enemy_spawner.hp_stats.current_hp <= 0 {
            
            rl.DrawTexturePro(atlas,  p_dead_sprite_source, dest, 0, 0, rl.WHITE)
        } else {
            draw_animation(atlas, &enemy_spawner.anim_controller, anime, PORTAL_SPRITE, false, dest, dt)
        }
        dest_1 := dest
        dest_1.y += f32(.75 * math.sin(rl.GetTime() ))
        rl.DrawTexturePro(atlas, source_portal_1, dest_1, {0,0}, 0, rl.WHITE)

        dest_2 := dest
        dest_2.y += f32(.5 * math.cos(rl.GetTime() ))
        rl.DrawTexturePro(atlas, source_portal_2, dest_2, {0, 0}, 0, rl.WHITE)



        if is_debug {
            respawn_ui_height :f32 = 10
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(respawn_ui_height), rl.WHITE)
            rl.DrawRectangle(i32(enemy_spawner.position.x - 20), i32(enemy_spawner.position.y - 5), 5, i32(enemy_spawner.re_spawn.current / enemy_spawner.re_spawn.max_time * respawn_ui_height), rl.BLUE)
            
        }
    }


}

enemy_unit_update::proc (game: ^Game, dt: f32) {
    

    for i:= len(game.enemy_side.enemy_units) - 1; i >=0; i -= 1 {
        enemy := &game.enemy_side.enemy_units[i]


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

            switch enemy.enemy_type {
                case .MELEE: {
                    if enemy.combat_state == .PARTROL {
                        enemy.body.vel.x = ENEMY_MOVE_SPEED * (enemy.body.direction == .RIGHT ? 1 : -1)
                        enemy.body.position.x += dt * enemy.body.vel.x 
                        
                        if rl.CheckCollisionPointRec(get_player(game^).body.position, taunted_rect) {
                            behind_cld := false
                            for cld in game.level_data.colliders {
                                if check_collision_line_rect(enemy.body.position, get_player(game^).body.position, cld) {
                                    behind_cld = true
                                    break
                                }
                            }
                            if !behind_cld  {
                                enemy.taunted_timer.current = enemy.taunted_timer.max_time
        
                                enemy.combat_state = .TAUNTED
                            }
                        }
                            
                        
                            
                    } else if enemy.combat_state == .TAUNTED  {
                        enemy.body.direction = get_player(game^).body.position.x - enemy.body.position.x > 0 ? .RIGHT : .LEFT
                        enemy.taunted_timer.current -= dt
                        
                        if enemy.taunted_timer.current > dt  && !rl.CheckCollisionPointRec(get_player(game^).body.position, taunted_rect) {
                            if enemy.taunted_timer.current + 0.5 < enemy.taunted_timer.max_time  {

                                enemy.taunted_timer.current = enemy.taunted_timer.max_time
                                enemy.combat_state = .PARTROL
                            }
                        }
                        if enemy.taunted_timer.current <= 0 {
                            enemy.attack.current = enemy.attack.max_time
                            enemy.attack.direction = get_player(game^).body.position.x - enemy.body.position.x > 0
                            enemy.combat_state = .ATTACK
                        }
                    } else if enemy.combat_state == .ATTACK  {
                        is_flip := enemy.body.direction != .RIGHT 
                        enemy.attack.current -= dt
                        remain_scale := 0.2 + 0.8 * enemy.attack.current / enemy.attack.max_time
                        remain_force :=  ENEMY_MELEE_PULSE_FORCE * remain_scale
                        enemy.body.vel.x =  remain_force * (enemy.attack.direction ? 1 : -1) * dt
                        enemy.body.position.x += enemy.body.vel.x

                        if rl.CheckCollisionRecs(get_body_rect(get_player(game^).body), get_enemy_body_rect(enemy.body)) {
                            player_take_dmg(&game.player.stats.health_stats, get_player(game^).stats.buffes,enemy.stats.dmg)
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
                case .RANGER : {
                    if enemy.combat_state == .PARTROL {
                            under_rect := rl.Rectangle {x = get_rect_center(get_enemy_body_rect(enemy.body)).x - 10, y = enemy.body.position.y + enemy.body.size.y + 2, width = 20, height = 3}
                            front_rect := rl.Rectangle {x = get_rect_center(get_enemy_body_rect(enemy.body)).x + (enemy.body.direction == .RIGHT ? enemy.body.size.x / 2 + 2 : - enemy.body.size.x / 2 - 10 - 2 ), y = enemy.body.position.y + enemy.body.size.y + 2, width = 10, height = 3}
                            for block_collider in game.level_data.colliders {
                                if !rl.CheckCollisionRecs(under_rect, block_collider) do continue
                                if !rl.CheckCollisionRecs(front_rect, block_collider) {
                                    enemy.body.direction = enemy.body.direction == .RIGHT ? .LEFT : .RIGHT
                                } 
                            }
                            
                            taunted_rect := rl.Rectangle {width = ENEMY_RANGER_TAUNTED_RANGE, height = 10, x = enemy.body.position.x + (enemy.body.direction == .RIGHT ? enemy.body.size.x / 2 : -enemy.body.size.x / 2 - ENEMY_RANGER_TAUNTED_RANGE), y = enemy.body.position.y - 5}
                            
                            if rl.CheckCollisionPointRec(get_player(game^).body.position, taunted_rect) {
                                behind_cld := false
                                for cld in game.level_data.colliders {
                                    if check_collision_line_rect(enemy.body.position, get_player(game^).body.position, cld) {
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


                        } else if enemy.combat_state == .TAUNTED {
                            enemy.taunted_timer.current -= dt 
                            if enemy.taunted_timer.current <= 0 {
                                e_ranger_shoot(&game.enemy_side.enemy_bullets, enemy.body, enemy.stats.dmg)
                                enemy.reload.current = enemy.reload.max_time
                                enemy.combat_state = .RELOAD
                            }
                        } else if enemy.combat_state == .RELOAD {
                            enemy.reload.current -= dt
                            if enemy.reload.current <= 0 {
                                enemy.combat_state = .PARTROL
                            }
                        }
                    
                }

                case .SNIPER : {
                    if enemy.combat_state == .AIMING {
                        enemy.targeting.target = get_player(game^).body.position
                        // player_pos := game.player.body.position
                        enemy.targeting.current_aiming_point += (enemy.targeting.target - enemy.targeting.current_aiming_point) * dt * ( 1 + ENEMY_AIMING_SPD )
                
                        if rl.CheckCollisionPointCircle(get_player(game^).body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                            enemy.targeting.trigger.current = enemy.targeting.trigger.max_time
                            enemy.targeting.current_aiming_point = get_player(game^).body.position
                            enemy.combat_state = .TRIGGER
                        }
                    } else if enemy.combat_state == .TRIGGER {
                        enemy.targeting.trigger.current -= dt
                        sprite := SPRITE_MAP[E_SNIPER_PARTICLE_SPRITE]
                        sprite_source := get_sprite_source_rect(sprite)
                        if enemy.targeting.trigger.current <=0 {
                            if rl.CheckCollisionPointCircle(get_player(game^).body.position, enemy.targeting.current_aiming_point, ENEMY_AIMING_RADIUS) {
                                player_take_dmg(&game.player.stats.health_stats, get_player(game^).stats.buffes, enemy.stats.dmg)
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
               
            }
            for block_collider in game.level_data.colliders {
                resolve_enemy_horizontal(&enemy.body, block_collider)
            }

        }

        if enemy.status == .IS_GRAB {
            if len(game.boss_manager.boss.skill_queue) == 0 {
                enemy.status = .ALIVE
            }
            for i:= 0; i < len(game.boss_manager.boss.skill_queue); i += 1{
                skill  := game.boss_manager.boss.skill_queue[i]
                if skill.target.id == enemy.id {
                    enemy.body.position = get_grab_pos(skill.pos_from, skill.pos_destination, skill.timer)
                }
            }
        }

        if enemy.enemy_type != .SNIPER {
            if enemy.status != .IS_GRAB {
                enemy.body.vel.y = min(enemy.body.vel.y + (ENEMY_GRAVITY * dt), MAX_FALL_SPEED)
                    
                enemy.body.position.y += enemy.body.vel.y * dt
                for block_collider in game.level_data.colliders {
                    resolve_enemy_vertical(&enemy.body, block_collider)
                }
            }
        }


    }
}

enemy_unit_draw::proc (atlas: rl.Texture2D, game_options: Game_Options, e_unit: ^[dynamic]Enemy_unit, dt: f32) {
    for &enemy in e_unit {
        enemy_rect := get_enemy_body_rect(enemy.body)
        is_flip := enemy.body.direction != .RIGHT
        

        switch enemy.enemy_type {
            case .MELEE : {
                anim := E_melee_animations[enemy.anim_controller.animation_name]

                if enemy.status == .DEAD {
                    dead_sprite := SPRITE_MAP[E_MELEE_DEAD_SPRITE]
                    rl.DrawTexturePro( atlas, get_sprite_source_rect(dead_sprite, is_flip), enemy_rect, 0, 0, rl.WHITE )
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
            }
            case .RANGER :{
                anim := E_ranger_animations[enemy.anim_controller.animation_name]
      
        
                if enemy.status == .DEAD {
                    dead_sprite := SPRITE_MAP[E_RANGER_DEAD_SPRITE]
                    rl.DrawTexturePro(atlas, get_sprite_source_rect(dead_sprite, is_flip), enemy_rect, 0, 0, rl.WHITE)
                } else {
                    if enemy.combat_state == .PARTROL {
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
            }
            case .SNIPER : {
                anim := E_sniper_animations[enemy.anim_controller.animation_name]
                if enemy.status == .DEAD {
                    dead_sprite := SPRITE_MAP[E_SINPER_DEAD_SPIPER]
                    rl.DrawTexturePro( atlas, get_sprite_source_rect(dead_sprite, is_flip), enemy_rect, 0, 0, rl.WHITE )
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

                if enemy.combat_state == .RELOAD{
                    unit_expression_draw(atlas, SPRITE_MAP[E_RELOAD_AURA_SPRITE], enemy.body.position + {8, -8})
                } else if enemy.combat_state == .AIMING {
                    sprite := SPRITE_MAP[E_SNIPER_AIMING_SPRITE]
                    sprite_source := get_sprite_source_rect(sprite)
                    sprite_dest := rl.Rectangle {x = enemy.targeting.current_aiming_point.x, y = enemy.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS, height = ENEMY_AIMING_RADIUS}
                    rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS / 2, ENEMY_AIMING_RADIUS / 2}, 0, rl.WHITE)
                } else if enemy.combat_state == .TRIGGER  {
                    sprite := SPRITE_MAP[E_SNIPER_TRIGGER_SPRITE]
                    sprite_source := get_sprite_source_rect(sprite)
                    sprite_scale :f32 = 1. +  0.6 * (enemy.targeting.trigger.current / enemy.targeting.trigger.max_time)
                    sprite_dest := rl.Rectangle {x = enemy.targeting.current_aiming_point.x, y = enemy.targeting.current_aiming_point.y, width = ENEMY_AIMING_RADIUS * sprite_scale, height = ENEMY_AIMING_RADIUS * sprite_scale}
                    rl.DrawTexturePro(atlas, sprite_source, sprite_dest, {ENEMY_AIMING_RADIUS * sprite_scale / 2, ENEMY_AIMING_RADIUS * sprite_scale / 2}, 0, rl.WHITE)
                }
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

    for &enemy in game.enemy_side.enemy_units {
        if enemy.id == enemy_spawner.enemy_id {
            found = true

            enemy.status = .ALIVE
       
            enemy.body.direction = .RIGHT
            enemy.stats = stats
            switch enemy.enemy_type {
                case .MELEE: {
                    enemy.body.position = enemy_spawner.position
                    enemy.body.vel = 20
                } 
                case .RANGER: {
                    enemy.body.position = enemy_spawner.position
                    enemy.body.vel = 20

                }
                case .SNIPER: {
                    spawn_offset_angle := rand.float32() * 360
                    spawn_offset := rl.Vector2 {ENEMY_SPAWN_OFFSET_RANGE * math.sin_f32(spawn_offset_angle), ENEMY_SPAWN_OFFSET_RANGE * math.cos_f32(spawn_offset_angle)}

                    enemy.body.position = enemy_spawner.position + spawn_offset
                    enemy.combat_state = .RELOAD
                    enemy.targeting.reload.current = 0.5
                    enemy.targeting.current_aiming_point = enemy_spawner.position + spawn_offset
                    enemy.body.vel = 0
                }
            }
            return
        }
    }
    switch enemy_spawner.enemy_type {
        case .MELEE : {
            enemy := Enemy_unit {
                id = enemy_spawner.enemy_id,
                enemy_type = .MELEE,
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
            append(&game.enemy_side.enemy_units, enemy)
        }
        case .RANGER : {
            enemy := Enemy_unit {
                id = enemy_spawner.enemy_id,
                enemy_type = .RANGER,

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
                combat_state = .PARTROL,
                    
            }
            append(&game.enemy_side.enemy_units, enemy)
        }
        case .SNIPER : {
            spawn_offset_angle := rand.float32() * 360
            spawn_offset := rl.Vector2 {ENEMY_SPAWN_OFFSET_RANGE * math.sin_f32(spawn_offset_angle), ENEMY_SPAWN_OFFSET_RANGE * math.cos_f32(spawn_offset_angle)}
            enemy := Enemy_unit {
                id = enemy_spawner.enemy_id,
                enemy_type = .SNIPER,

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
                    target = get_player(game^).body.position,
                    current_aiming_point = enemy_spawner.position + spawn_offset

                }
            }
            append(&game.enemy_side.enemy_units, enemy)
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


enemy_take_dmg :: proc(health: ^Health_stats, bullet: Bullet) {
    health.current_hp -= bullet.dmg
}
