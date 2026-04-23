#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:strings"

GAME_ATLAS: string : "assets/platform_shooter.png"
GAME_BACKGROUND: string : "assets/map_images/level_1_bg.png"
GAME_CLOUD_BACKGROUND: string : "assets/map_images/level_1_bg_cloud.png"

Sprite_desc :: struct {
    x: f32,
    y: f32, 
    w: f32,
    h: f32,
    
    count : int
}



KEY_SPRITE :: "Key_sprite"
KEY_DISABLE_AURA_SPRITE :: "Key_disable_aura_sprite"
E_MELEE_SPRITE :: "E_melee_sprite"
E_MELEE_TAUNTED_SPRITE :: "E_melle_taunted_sprite"
E_MELEE_DEAD_SPRITE :: "E_melee_dead_sprite"
E_SNIPER_SPRITE :: "E_sniper_sprite"
E_SINPER_DEAD_SPIPER :: "E_sniper_dead_sprite"
E_SNIPER_TRIGGER_SPRITE :: "E_sniper_targeting_sprite"
E_SNIPER_AIMING_SPRITE :: "E_sniper_aiming_sprite"
E_SNIPER_RELOAD_SPRITE :: "E_sniper_reload_sprite"
E_SNIPER_PARTICLE_SPRITE :: "E_sniper_particle_sprite"
E_TAUNTED_AURA_SPRITE :: "E_taunted_aura_sprite"
E_RELOAD_AURA_SPRITE :: "E_reload_aura_sprite"
E_RANGER_SPRITE :: "E_ranger_sprite"
E_RANGER_DEAD_SPRITE :: "E_ranger_dead_sprite"
E_RANGER_TAUNTED_SPRITE :: "E_ranger_taunted_sprite"
PLAYER_SPRITE :: "Player_sprite"
PORTAL_SPRITE :: "Portal_sprite"
PORTAL_DEAD_SPRITE :: "Portad_dead_sprite"
PORTAL_SPRITE_1 :: "Portal_sprite_a1"
PORTAL_SPRITE_2 :: "Portal_sprite_a2"
BULLET_SPRITE :: "Bullet_sprite"
EXPERIENCE_BUFF_SPRITE :: "Experience_sprite"
PLAYER_AVATAR_SPRITE :: "Player_avatar_sprite"
HEALTH_BAR_SPRITE:: "Health_bar_sprite"
HEALTH_BAR_FILL_SPRITE:: "Health_bar_fill_sprite"

HP_BUFF_SPRITE :: "Hp_buff_sprite"
AD_BUFF_SPRITE :: "Ad_buff_sprite"
ATS_BUFF_SPRITE :: "Ats_buff_sprite"
MVSP_BUFF_SPRITE :: "Mvspd_buff_sprite"
AR_BUFF_SPRITE :: "Ar_buff_sprite"
PARTICLE_SPRITE :: "Particle_sprite"
LEVEL_GATE_SPRITE :: "Level_gate_sprite"
SHOOT_SKILL_SPRITE :: "Shoot_skill_sprite"
MINI_MAP_ARROW_SPRITE :: "Minimap_arrow_sprite"
PAUSED_SIGN_SPRITE :: "Paused_sign_sprite"
GAME_OVER_SPRITE :: "Game_over_sprite"
GAME_START_SPRITE :: "Game_start_sprite"
UI_CURSIR_SPRITE_1 :: "Ui_cursor_sprite_1"
UI_CURSIR_SPRITE_2 :: "Ui_cursor_sprite_2"

SPRITE_MAP := map[string]Sprite_desc {
    KEY_SPRITE = {x = 16, y = 64, w = 16, h = 16 },
    KEY_DISABLE_AURA_SPRITE = {x =288, y = 176, w = 32, h = 32},
    PORTAL_SPRITE = {x = 0, y = 144, w = 96, h = 32, count = 3},
    PORTAL_DEAD_SPRITE = {x = 96, y = 144, w = 32, h = 32},
    PORTAL_SPRITE_1 = {x = 128, y = 144, w = 32, h = 32},
    PORTAL_SPRITE_2 = {x = 160, y = 144, w = 32, h = 32},
    //
    E_TAUNTED_AURA_SPRITE = {x = 224, y = 176, w =32, h= 32},
    E_RELOAD_AURA_SPRITE = {x = 256, y = 176, w =32, h= 32},
    // Enemy melee
    E_MELEE_SPRITE = {x = 0, y = 368, w = 432, h = 48, count = 9},
    E_MELEE_TAUNTED_SPRITE = {x = 144, y = 416, w = 48, h = 48},
    E_MELEE_DEAD_SPRITE = {x = 0, y = 416, w = 48, h = 48, count = 1},
    // Enemy sniper
    E_SNIPER_SPRITE = {x= 0, y= 320, w = 96, h = 48, count = 2},
    E_SINPER_DEAD_SPIPER = {x = 48, y = 416, w = 48, h = 48},
    E_SNIPER_AIMING_SPRITE = {x = 192, y = 144, w = 32, h =32},
    E_SNIPER_TRIGGER_SPRITE = {x = 224,y = 144, w = 32, h =32},
    E_SNIPER_RELOAD_SPRITE = {x = 256, y = 144, w = 32, h =32},
    E_SNIPER_PARTICLE_SPRITE = {x = 96, y = 176, w = 32, h = 32},

    // Enemy ranger
    E_RANGER_SPRITE = {x = 0, y = 272, w = 384, h = 48, count = 8},
    E_RANGER_DEAD_SPRITE = {x = 96, y = 416, w = 48, h = 48},
    E_RANGER_TAUNTED_SPRITE = {x = 384, y = 272, w = 48, h = 48},

    PLAYER_SPRITE = {x = 0, y = 112, w = 160, h = 32, count = 5},
    BULLET_SPRITE = {x = 0, y = 64, w = 16, h = 16},
    EXPERIENCE_BUFF_SPRITE = {x = 32, y = 176, w = 32, h = 32},
    PLAYER_AVATAR_SPRITE = {x = 0, y = 208, w = 64, h = 64},

    HEALTH_BAR_SPRITE = {x = 112, y = 64, w = 48, h = 16},
    HEALTH_BAR_FILL_SPRITE = {x = 160, y = 64, w = 48, h = 16},

    HP_BUFF_SPRITE = {x = 32, y = 64, w = 16, h = 16},
    AD_BUFF_SPRITE = {x = 80, y = 64, w = 16, h = 16},
    ATS_BUFF_SPRITE = {x = 64, y = 64, w = 16, h = 16},
    MVSP_BUFF_SPRITE = {x = 48, y = 64, w = 16, h = 16},
    AR_BUFF_SPRITE = {x = 96, y = 64, w = 16, h = 16},
    PARTICLE_SPRITE = {x = 64, y = 176, w = 32, h = 32},
    LEVEL_GATE_SPRITE = {x = 0, y = 176, w = 32, h = 32},
    SHOOT_SKILL_SPRITE = {x = 128, y = 176, w = 32, h = 32},
    MINI_MAP_ARROW_SPRITE = {x = 256, y = 144, w = 32, h = 32},
    PAUSED_SIGN_SPRITE = {x = 0, y = 464, w = 96, h = 48},
    UI_CURSIR_SPRITE_1 = {x = 0, y = 80, w = 16, h = 16},
    UI_CURSIR_SPRITE_2 = {x = 16, y = 80, w = 16, h = 16},
    GAME_OVER_SPRITE = {x = 0, y = 512, w = 144, h = 96},
    GAME_START_SPRITE = {x = 144, y = 512, w = 144, h = 96},
}

load_atlas:: proc(game: ^Game) {
    game.game_sprite_atlas = rl.LoadTexture(strings.clone_to_cstring(GAME_ATLAS, context.temp_allocator))
    game.game_background = rl.LoadTexture(strings.clone_to_cstring(GAME_BACKGROUND, context.temp_allocator))
    game.game_cloud_background = rl.LoadTexture(strings.clone_to_cstring(GAME_CLOUD_BACKGROUND, context.temp_allocator))
}
