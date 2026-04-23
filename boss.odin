package main
import rl "vendor:raylib"

BOSS_SCENE_TRANSITION_TIME: f32: 1.
BOSS_SIZE: rl.Vector2 : {80, 80}
BOSS_TELE_DUR: f32 : 1.
BOSS_EXPLOSIONS_SKILL_TRIGGER_TIME : f32 : 1.
BOSS_HP :f32 : 4000
BOSS_DMG: f32 : 50

MAX_BOSS_NUMB : int : 2
Boss_levels : [MAX_BOSS_NUMB] int= {3, 10}

Boss_level_scene_manager :: struct {
    is_boss_level : bool,
    boss: Boss
}

Timer :: struct {
    max_time: f32,
    current: f32
}

Boss_combat_states :: enum {
    IDLE,
    FURIOUS,
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
    target: Boss_skill_grab_target,
    pos_from : rl.Vector2,
    pos_destination: rl.Vector2
}

Boss :: struct {
    stats : Enemy_unit_stats,
    body: Enemy_Body,
    combat_state: Boss_combat_states,
    skill_queue : [5] Boss_skill_cast
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

boss_update :: proc()  {

}

boss_draw :: proc() {

}