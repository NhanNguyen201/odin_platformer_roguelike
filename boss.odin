package main
import rl "vendor:raylib"


BOSS_SIZE: rl.Vector2 : {80, 80}
BOSS_TELE_DUR: f32 : 1.
BOSS_EXPLOSIONS_SKILL_TRIGGER_TIME : f32 : 1.
BOSS_HP :f32 : 4000
BOSS_DMG: f32 : 50

Boss_level_scene_manager :: struct {
    is_boss_level : bool,
    scene_transition: Timer
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

Boss :: struct {
    stats : Enemy_unit_stats,
    body: Enemy_Body,
    combat_state: Boss_combat_states
}