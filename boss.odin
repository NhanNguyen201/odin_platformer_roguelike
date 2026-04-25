package main
import rl "vendor:raylib"
import "core:math"

BOSS_SCENE_TRANSITION_TIME: f32: 1.
BOSS_SIZE: rl.Vector2 : {140, 140}

BOSS_TELE_DUR: f32 : 1.
BOSS_EXPLOSIONS_SKILL_TRIGGER_TIME : f32 : 1.
BOSS_HP :f32 : 4000
BOSS_DMG: f32 : 50
BOSS_IDLE_TIME: f32: 5.
BOSS_ARGO_TIME: f32: 5.
MAX_BOSS_NUMB : int : 2
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
    TELE,
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

Boss :: struct {
    stats : Enemy_unit_stats,
    body: Enemy_Body,
    status: Enemy_status,
    skill_queue: [5] Boss_skill_cast,
    combat_state: Boss_combat_states,
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

boss_update :: proc(boss: ^Boss, player_bullets: ^[dynamic]Bullet, dt: f32)  {
    if boss.status == .ALIVE {
        resolve_enemy_and_bullet(boss.body, &boss.stats.health_stats, player_bullets)

    }
    // boss.body.position.x += 2.5 * math.sin_f32(f32(rl.GetTime()))
    // boss.body.position.y += 2.5 * math.cos_f32(f32(rl.GetTime()))
}

boss_draw :: proc(atlas: rl.Texture2D ,boss: Boss, dt: f32) {
    boss_rect := get_enemy_body_rect(boss.body)
    boss_sprite := SPRITE_MAP[BOSS_BODY_SPRITE]
    boss_body_sprite_source := rl.Rectangle{x = boss_sprite.x, y = boss_sprite.y, width = boss_sprite.w, height = boss_sprite.h}
    rl.DrawTexturePro(atlas, boss_body_sprite_source, boss_rect, 0, 0, rl.WHITE)
    // rl.DrawRectangleRec(boss_rect, rl.Color{255,255,255, 180})

    boss_glass_sprite := SPRITE_MAP[BOSS_GLASS_SPRITE]
    boss_glass_sprite_source := rl.Rectangle{x = boss_glass_sprite.x, y = boss_glass_sprite.y, width = boss_glass_sprite.w, height = boss_glass_sprite.h}
    glass_rect := rl.Rectangle{x = get_rect_center(boss_rect).x - boss_glass_sprite.w / 2, y = get_rect_center(boss_rect).y - boss_glass_sprite.y / 2, width = boss_glass_sprite.w, height = boss_glass_sprite.h }
    glass_rect.y -= 10 * (boss_sprite.h / boss_glass_sprite.h)
    
    rl.DrawTexturePro(atlas, boss_glass_sprite_source, glass_rect,0, 0, rl.WHITE)

    boss_nose_sprite := SPRITE_MAP[BOSS_NOSE_SPRITE]
    boss_nose_sprite_source := rl.Rectangle{x = boss_nose_sprite.x, y = boss_nose_sprite.y, width = boss_nose_sprite.w, height = boss_nose_sprite.h}
    nose_rect := rl.Rectangle{x = get_rect_center(boss_rect).x - boss_nose_sprite.w / 2, y = get_rect_center(boss_rect).y - boss_nose_sprite.y / 2, width = boss_nose_sprite.w, height = boss_nose_sprite.h }
    nose_rect.y += 10 * (boss_sprite.h / boss_nose_sprite.h)
    
    rl.DrawTexturePro(atlas, boss_nose_sprite_source, nose_rect, 0, 0, rl.RED)

    boss_beard_sprite := SPRITE_MAP[BOSS_BEARD_SPRITE]
    boss_beard_sprite_source := rl.Rectangle{x = boss_beard_sprite.x, y = boss_beard_sprite.y, width = boss_beard_sprite.w, height = boss_beard_sprite.h}
    beard_rect := rl.Rectangle{x = get_rect_center(boss_rect).x - boss_beard_sprite.w / 2, y = get_rect_center(boss_rect).y - boss_beard_sprite.y / 2,width = boss_beard_sprite.w, height = boss_beard_sprite.h }
    beard_rect.y += 20 * (boss_sprite.h / boss_beard_sprite.h)
   
    rl.DrawTexturePro(atlas, boss_beard_sprite_source, beard_rect, 0, 0, rl.WHITE)
    

}

spawn_boss :: proc(boss_manager: ^Boss_level_manager)  {
    @static boss_position := rl.Vector2 { 500, 500 }
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
        combat_state = .IDLE
    }
}