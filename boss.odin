package main
import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

BOSS_SCENE_TRANSITION_TIME: f32: 1.
BOSS_SIZE: f32 : 70

BOSS_TELE_DUR: f32 : 1.
BOSS_EXPLOSIONS_SKILL_TRIGGER_TIME : f32 : 1.
BOSS_HP :f32 : 4000
BOSS_DMG: f32 : 50
BOSS_IDLE_TIME: f32: 5.
BOSS_ARGO_TIME: f32: 5.
MAX_BOSS_NUMB : int : 2
BOSS_FIREBALL_FLY_SPD : f32 : 100
Boss_levels : [MAX_BOSS_NUMB] int= {0, 10}

Boss_level_manager :: struct {
    is_boss_level : bool,
    boss: Boss
}

Timer :: struct {
    max_time: f32,
    current: f32
}

Boss_combat_states :: enum {
    IDLE,
    ARGO,
    SKILL_CAST,
    TELE_CAST,
    STUNED,
}

Boss_skill :: enum {
    GRAB,
    EXPLODE,
    FIREBALL,
}

Boss_skill_cast :: struct {
    skill: Boss_skill,
    timer: Timer,
    trigger: Timer,
    area_effect: f32,
    target: Boss_skill_grab_target,
    pos_from : rl.Vector2,
    pos_destination: rl.Vector2
}

Boss_teleportation:: struct {
    count: int,
    timer: Timer
}
Boss :: struct {
    stats : Enemy_unit_stats,
    body: Enemy_Body,
    status: Enemy_status,
    skill_queue: [dynamic] Boss_skill_cast,
    combat_state: Boss_combat_states,
    teleportation: Boss_teleportation,
    state_timer: Timer
}

Boss_skill_grab_target :: struct {
    id: f32,
    enemy_type: Enemy_types
}

get_is_boss_lvl :: proc(curent_lvl : int) -> bool {
    for level in Boss_levels {        
        if level == curent_lvl do return true
    }
    return false
}

get_fireball_position :: proc(skill : Boss_skill_cast, dt: f32) -> rl.Vector2 {
    return skill.pos_from + (skill.pos_destination - skill.pos_from) * BOSS_FIREBALL_FLY_SPD  * (skill.timer.max_time - skill.timer.current) * dt
}

boss_update :: proc(boss: ^Boss, game: ^Game, dt: f32)  {
    if boss.status == .ALIVE {
        resolve_boss_and_bullet(boss.body, &boss.stats.health_stats, &game.player_bullets)
        if boss.combat_state == .IDLE {
            boss.state_timer.current -= dt
            if boss.state_timer.current < 0 {
                boss.state_timer.current = 1.
                boss.combat_state = .ARGO
                boss.body.size = 140
            }
        } else if boss.combat_state == .ARGO {
            
            boss.state_timer.current -= dt
            if boss.state_timer.current < 0 {
                
                append(&boss.skill_queue,  Boss_skill_cast {
                    area_effect = 20.,
                    skill = .EXPLODE,
                    trigger = {current = 1.},
                    timer = { current = 1.5},
                })
                
                append(&boss.skill_queue,  Boss_skill_cast {
                    area_effect = 20.,
                    skill = .FIREBALL,
                    timer = { current = 1.5, max_time = 1.5},
                    trigger = {current = 0.5},
                    
                })
                boss.state_timer.current = 4.
                boss.body.size = 70
                boss.combat_state = .SKILL_CAST
            }
        } else if boss.combat_state == .SKILL_CAST {

            boss.state_timer.current -= dt
            for i:= len(boss.skill_queue) - 1; i  >= 0; i -= 1  {
                skill := &boss.skill_queue[i]
                if skill.skill == .EXPLODE {
                    if skill.trigger.current > 0 {
                        skill.trigger.current -= dt
                        skill.pos_destination = game.player.body.position
                    } 
                    if skill.trigger.current < 0 && skill.timer.current > 0 {
                        skill.timer.current -= dt 
                        if rl.CheckCollisionCircleRec(skill.pos_destination, skill.area_effect, get_body_rect(game.player.body)) {
                            player_take_dmg(&game.player.stats.health_stats, game.player.stats.buffes, 50)
                        }
                    }
                  
                } else if skill.skill == .FIREBALL {
                    if skill.trigger.current > 0 {
                        skill.trigger.current -= dt
                        skill.pos_destination = game.player.body.position
                        skill.pos_from = boss.body.position
                    } 
                    if skill.trigger.current < 0 && skill.timer.current > 0 {
                        skill.timer.current -= dt 
                        // fireball_circle := 
                        fireball_pos := get_fireball_position(skill^, dt)

                        if rl.CheckCollisionCircleRec(fireball_pos, skill.area_effect, get_body_rect(game.player.body)) {
                            player_take_dmg(&game.player.stats.health_stats, game.player.stats.buffes, 50)
                        }
                    }
                    
                }
              
            }
            if boss.state_timer.current < 0 {
                clear(&boss.skill_queue)

                boss.state_timer.current = 2.
                boss.teleportation.timer.current = 0.5
                boss.teleportation.count = 1
                boss.combat_state = .TELE_CAST
            }
        } else if boss.combat_state == .TELE_CAST {
            if boss.teleportation.timer.current > 0 {
                boss.teleportation.timer.current -= dt
            } else {
                if boss.teleportation.count > 0 {
                    boss.teleportation.count -= 1
                    boss.body.position.x = game.level_data.map_size.x * rand.float32()
                    boss.body.position.y = game.level_data.map_size.y * rand.float32()
                }
                boss.state_timer.current -= dt
                if boss.state_timer.current < 0 {
                    boss.state_timer.current = 5.
                    boss.combat_state = .IDLE
                }
            }

        }
    }
    // boss.body.position.x += 2.5 * math.sin_f32(f32(rl.GetTime()))
    // boss.body.position.y += 2.5 * math.cos_f32(f32(rl.GetTime()))
    for i:= len(boss.skill_queue) - 1; i  > 0; i -= 1  { 
        if boss.skill_queue[i].timer.current < 0 {
            unordered_remove(&boss.skill_queue, i)
        } 
    }

}

boss_draw :: proc(atlas: rl.Texture2D ,boss: Boss, particle_sys: ^Particles_systems, dt: f32) {
    boss_rect := rl.Rectangle{ boss.body.position.x -  boss.body.size.x , boss.body.position.y -  boss.body.size.y , boss.body.size.x * 2, boss.body.size.y * 2}
    boss_sprite := SPRITE_MAP[BOSS_BODY_SPRITE]
    boss_body_sprite_source := rl.Rectangle{x = boss_sprite.x, y = boss_sprite.y, width = boss_sprite.w, height = boss_sprite.h}
    rl.DrawTexturePro(atlas, boss_body_sprite_source, boss_rect, 0, 0, rl.WHITE)
    // rl.DrawCircleV(boss.body.position, boss.body.size.x, rl.Color{255,255,255, 180})

    boss_glass_sprite := SPRITE_MAP[BOSS_GLASS_SPRITE]
    boss_glass_sprite_source := rl.Rectangle{x = boss_glass_sprite.x, y = boss_glass_sprite.y, width = boss_glass_sprite.w, height = boss_glass_sprite.h}
    glass_rect := rl.Rectangle{x = get_rect_center(boss_rect).x , y = get_rect_center(boss_rect).y , width = boss_glass_sprite.w, height = boss_glass_sprite.h }
    glass_rect.y -= 10 * (boss_sprite.h / boss_glass_sprite.h)
    
    rl.DrawTexturePro(atlas, boss_glass_sprite_source, glass_rect, get_rect_size(glass_rect) / 2, 0, rl.WHITE)

    boss_nose_sprite := SPRITE_MAP[BOSS_NOSE_SPRITE]
    boss_nose_sprite_source := rl.Rectangle{x = boss_nose_sprite.x, y = boss_nose_sprite.y, width = boss_nose_sprite.w, height = boss_nose_sprite.h}
    nose_rect := rl.Rectangle{x = get_rect_center(boss_rect).x, y = get_rect_center(boss_rect).y , width = boss_nose_sprite.w, height = boss_nose_sprite.h }
    nose_rect.y += 10 * (boss_sprite.h / boss_nose_sprite.h)
    
    rl.DrawTexturePro(atlas, boss_nose_sprite_source, nose_rect, get_rect_size(nose_rect) / 2, 0, rl.WHITE)

    boss_beard_sprite := SPRITE_MAP[BOSS_BEARD_SPRITE]
    boss_beard_sprite_source := rl.Rectangle{x = boss_beard_sprite.x, y = boss_beard_sprite.y, width = boss_beard_sprite.w, height = boss_beard_sprite.h}
    beard_rect := rl.Rectangle{x = get_rect_center(boss_rect).x , y = get_rect_center(boss_rect).y ,width = boss_beard_sprite.w, height = boss_beard_sprite.h }
    beard_rect.y += 20 * (boss_sprite.h / boss_beard_sprite.h)
   
    rl.DrawTexturePro(atlas, boss_beard_sprite_source, beard_rect, get_rect_size(beard_rect) / 2, 0, rl.WHITE)
    
    if boss.combat_state == .SKILL_CAST {
        for skill in boss.skill_queue {
            if skill.skill == .EXPLODE {
                if skill.trigger.current > 0 {
                    rl.DrawCircleV(skill.pos_destination, skill.area_effect, rl.YELLOW)
                }
                if skill.trigger.current < 0 && skill.timer.current > 0 {
                    // rl.DrawCircleV(skill.pos_destination, skill.area_effect, rl.BLACK)
                    add_particle(particle_sys, Particle {
                        timer ={ max_time = skill.timer.max_time, current = skill.timer.current },
                        position = skill.pos_destination,
                        sprite_source = rl.Rectangle {x = 192, y =176, width = 32, height = 32}
                    })
                }
            } else if skill.skill == .FIREBALL {
                if skill.trigger.current > 0 {
                    rl.DrawCircleV(skill.pos_destination, skill.area_effect, rl.YELLOW)
                }   
                if skill.trigger.current < 0 && skill.timer.current > 0 {
                    fireball_pos := get_fireball_position(skill, dt)
                    rl.DrawCircleV(fireball_pos, skill.area_effect, rl.BLACK)
                }
            }
        }
    }
}

spawn_boss :: proc(boss_manager: ^Boss_level_manager)  {
    @static boss_position := rl.Vector2 { 500, 360 }
    boss_manager.boss = {
        body = {
            position = boss_position,
            size = BOSS_SIZE,
            vel = 0,
            direction = .RIGHT
        },
        status = .DEAD,
        stats = {
            dmg = BOSS_DMG,
            health_stats = {
                max_hp = BOSS_HP,
                current_hp = BOSS_HP
            }
        },
        combat_state = .IDLE,
        state_timer = {
            current = 5.
        }
    }
}