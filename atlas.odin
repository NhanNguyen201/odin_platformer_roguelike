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
MINION_SPRITE :: "Minion_sprite"
MINION_DEAD_SPRITE :: "Minion_dead_sprite"
PLAYER_SPRITE :: "Player_sprite"
PORTAL_SPRITE :: "Portal_sprite"
PORTAL_SPRITE_1 :: "Portal_sprite_a1"
PORTAL_SPRITE_2 :: "Portal_sprite_a2"
BULLET_SPRITE :: "Bullet_sprite"
EXPERIENCE_BUFF_SPRITE :: "Experience_sprite"
PLAYER_AVATAR_SPRITE :: "Player_avatar_sprite"
HEALTH_BAR_SPRITE:: "Health_bar_sprite"
HEALTH_BAR_FILL_SPRITE:: "Health_bar_fill_sprite"



SPRITE_MAP := map[string]Sprite_desc {
    KEY_SPRITE = {x = 16, y = 64, w = 16, h = 16 },
    PORTAL_SPRITE = {x = 0, y = 144, w = 32, h = 32},
    PORTAL_SPRITE_1 = {x = 32, y = 144, w = 32, h = 32},
    PORTAL_SPRITE_2 = {x = 64, y = 144, w = 32, h = 32},
    MINION_SPRITE = {x = 0, y = 80, w = 128, h = 32, count = 4},
    MINION_DEAD_SPRITE = {x = 128, y = 80, w = 32, h = 32, count = 4},
    PLAYER_SPRITE = {x = 0, y = 112, w = 128, h = 32, count = 4},
    BULLET_SPRITE = {x = 0, y = 64, w = 16, h = 16},
    EXPERIENCE_BUFF_SPRITE = {x = 32, y = 176, w = 32, h = 32},
    PLAYER_AVATAR_SPRITE = {x = 0, y = 208, w = 64, h = 64},
    HEALTH_BAR_SPRITE = {x = 96, y = 64, w = 48, h = 16},
    HEALTH_BAR_FILL_SPRITE = {x = 144, y = 64, w = 48, h = 16}
}

load_atlas:: proc(game: ^Game) {
    game.game_sprite_atlas = rl.LoadTexture(strings.clone_to_cstring(GAME_ATLAS, context.temp_allocator))
    game.game_background = rl.LoadTexture(strings.clone_to_cstring(GAME_BACKGROUND, context.temp_allocator))
    game.game_cloud_background = rl.LoadTexture(strings.clone_to_cstring(GAME_CLOUD_BACKGROUND, context.temp_allocator))
}
