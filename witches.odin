package main
import rl "vendor:raylib"
import "core:math/rand"
import "core:math"
WITCH_CAST_RADIUS : f32 : 50
WITCH_HEAL_TICK : f32 :0.3
WITCH_ENEMY_ATK_TICK : f32: 0.7
GOOD_WTICH_COOLDOWN : f32 : 7.
GOOD_WITCH_CAST_TIME: f32 : 3.
BAD_WTICH_COOLDOWN : f32 : 5.
BAD_WITCH_CAST_TIME: f32 : 3.
Witch_state :: enum {
    RELOAD,
    BLESS,
}

Witch_tpye :: enum {
    GOOD,
    BAD
} 

Witch :: struct {
    is_active: bool,
    type: Witch_tpye,
    state: Witch_state,
    body: Body,
    reload: Timer,
    cast_timer: Timer,
    cast_position: rl.Vector2,
    spell_tick_timer: Timer
}

witch_update :: proc(witch: ^Witch, game: ^Game, dt: f32) {
    player := get_player(game^)
    if witch.state == .RELOAD {
        witch.reload.current -= dt
        if witch.reload.current <= 0 {
            if witch.type == .GOOD {
                witch.cast_position = player.body.position
            } else {
                e_unit := rand.choice(game.enemy_side.enemy_units[:])
                witch.cast_position = e_unit.body.position
            }
            witch.cast_timer.current = witch.cast_timer.max_time
            witch.spell_tick_timer.current = witch.spell_tick_timer.max_time
            witch.state = .BLESS
        }
    } else  if witch.state == .BLESS {
        witch.cast_timer.current -= dt
        if witch.type == .GOOD {
            if get_distance(player.body.position, witch.cast_position) < WITCH_CAST_RADIUS {
                witch.spell_tick_timer.current -= dt 
                if witch.spell_tick_timer.current < 0 {
                    game.player.stats.health_stats.current_hp = min(player.stats.health_stats.current_hp + 3, player.stats.health_stats.max_hp)
                    add_particle(&game.particle_system, {
                        is_blur = true,
                        is_scaled = true,
                        sprite_count = 1,
                        position = player.body.position,
                        timer =make_timer_from(0.5),
                        size = {12,12},
                        sprite_source = get_sprite_source_rect(SPRITE_MAP[GET_HEAL_SPRITE]),
                        vel = {10 * math.sin_f32(game.game_options.game_time), -40}
            
                    })
                    witch.spell_tick_timer.current = witch.spell_tick_timer.max_time
                } 
            }
        } else {
            for e_unit in game.enemy_side.enemy_units {
                if get_distance(e_unit.body.position, witch.cast_position) < WITCH_CAST_RADIUS {
                    witch.spell_tick_timer.current -= dt 
                    break
                }
            }
            if witch.spell_tick_timer.current <= 0 {
                for &e_unit in game.enemy_side.enemy_units {
                    if get_distance(e_unit.body.position, witch.cast_position) < WITCH_CAST_RADIUS && e_unit.status == .ALIVE {
                        e_unit.stats.dmg += 1
                        add_particle(&game.particle_system, {
                            is_blur = true,
                            is_scaled = true,
                            sprite_count = 1,
                            position = e_unit.body.position,
                            timer =make_timer_from(0.5),
                            size = {12,12},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[GET_ATK_SPRITE]),
                            vel = {10 * math.sin_f32(game.game_options.game_time), -40}
                
                        })
                    }
                }
                witch.spell_tick_timer.current = witch.spell_tick_timer.max_time
            }
        }

        if witch.cast_timer.current <= 0 {
            witch.reload.current = witch.reload.max_time
            witch.state = .RELOAD
        }
    }
}

witch_bless_draw :: proc(atlas: rl.Texture2D, witch: Witch) {

    if witch.state == .BLESS {
        if witch.type == .GOOD {
            rl.DrawTexturePro(atlas, get_sprite_source_rect(SPRITE_MAP[GOOD_WTICH_BUFF_SPRITE]), rl.Rectangle {x = witch.cast_position.x - WITCH_CAST_RADIUS, y = witch.cast_position.y - WITCH_CAST_RADIUS, width = WITCH_CAST_RADIUS * 2,  height= WITCH_CAST_RADIUS * 2}, 0, 0, rl.WHITE)
        } else {
            rl.DrawTexturePro(atlas, get_sprite_source_rect(SPRITE_MAP[BAD_WTICH_BUFF_SPRITE]), rl.Rectangle {x = witch.cast_position.x - WITCH_CAST_RADIUS, y = witch.cast_position.y - WITCH_CAST_RADIUS, width = WITCH_CAST_RADIUS * 2,  height= WITCH_CAST_RADIUS * 2}, 0, 0, rl.WHITE)
        }
    }
}

witch_draw :: proc(atlas: rl.Texture2D, witch: Witch, source_rect: rl.Rectangle, witch_rect: rl.Rectangle) {
    if witch.state == .BLESS {
        rl.DrawTexturePro(atlas, get_sprite_source_rect(SPRITE_MAP[WITCH_AURA_SPRITE]), witch_rect, 0, 0, witch.type == .GOOD ? rl.Color{40,240,40, 160} : rl.Color{ 50,50,50, 160})
    }
    witch_draw_rect := rl.Rectangle {x = witch_rect.x + 2, y = witch_rect.y + 2, width = witch_rect.width - 4, height = witch_rect.height - 4}
    rl.DrawTexturePro(atlas, source_rect, witch_draw_rect, 0, 0, rl.WHITE)
    if witch.state == .RELOAD {
        new_source_rec := rl.Rectangle {x = source_rect.x, y = source_rect.y + source_rect.height * (witch.reload.max_time - witch.reload.current) / witch.reload.max_time, width = source_rect.width, height =source_rect.height * (witch.reload.current / witch.reload.max_time)}
        over_rect := rl.Rectangle {x = witch_draw_rect.x, y = witch_draw_rect.y + witch_draw_rect.height * (witch.reload.max_time - witch.reload.current) / witch.reload.max_time, width = witch_draw_rect.width, height = witch_draw_rect.height * (witch.reload.current / witch.reload.max_time)}
        rl.DrawTexturePro(atlas, new_source_rec, over_rect, 0, 0, rl.Color {100,100,100, 200})

    }
}