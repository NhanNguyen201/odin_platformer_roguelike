package main
import rl "vendor:raylib"
import "core:fmt"

UI_PADDING : rl.Vector2 : {5, 5}
HEALTH_BAR_SIZE : rl.Vector2: {40, 7}

is_ui_component_hover :: proc(game_options: GameOptions, rect : rl.Rectangle) -> bool { 
    return rl.CheckCollisionPointRec(game_options.ui_mouse_pos, rect)
}



player_ui_draw:: proc(game: Game) {
    key_atlas_sprite := SPRITE_MAP[KEY_SPRITE]

    key_source := rl.Rectangle{x = key_atlas_sprite.x , y= key_atlas_sprite.y , width = key_atlas_sprite.w , height = key_atlas_sprite.h}


    player := game.player
    
    ui_x_start := player.position.x +( PLAYER_SIZE.x / 2 ) + UI_PADDING.x - game.camera.offset.x / 4
    ui_y_start := player.position.y + ( PLAYER_SIZE.y / 2 ) + UI_PADDING.y - game.camera.offset.y / 4

    ui_width := f32(rl.GetScreenWidth() / 4) -( PLAYER_SIZE.x / 2 ) - UI_PADDING.x 
    ui_height := f32(rl.GetScreenHeight() / 4) - ( PLAYER_SIZE.y / 2 ) - UI_PADDING.y
    
    ui_rect := rl.Rectangle{x = ui_x_start, y = ui_y_start, width = ui_width, height = ui_height}
    
    pause := fmt.ctprintf("%t", game.game_options.is_paused)
    
    if game.game_options.is_debug {
        rl.DrawRectangleLinesEx(ui_rect, 0.5, rl.WHITE)
        // rl.DrawText(pause, i32(ui_rect.x) + 10, i32(ui_rect.y) + 10, 10, rl.BLACK)
    }
    // Draw keys
    

    avatar_sprite := SPRITE_MAP[PLAYER_AVATAR_SPRITE]
    avatar_size := rl.Vector2{12, 12}
    avatar_source := rl.Rectangle{x = avatar_sprite.x, y= avatar_sprite.y, width = avatar_sprite.w, height = avatar_sprite.h}

    avatar_dest := rl.Rectangle{x = ui_x_start, y= ui_y_start, width = avatar_size.x, height = avatar_size.y}
    rl.DrawTexturePro(game.game_sprite_atlas, avatar_source, avatar_dest, {0,0}, 0, rl.WHITE)

    charactor_ui_rect := rl.Rectangle {x = ui_x_start, y = ui_y_start, width = 50, height = 30}
    
    health_bar_sprite := SPRITE_MAP[HEALTH_BAR_SPRITE]
    health_bar_fill_sprite := SPRITE_MAP[HEALTH_BAR_FILL_SPRITE]

    health_bar_source := rl.Rectangle {x = health_bar_sprite.x , y = health_bar_sprite.y, width = health_bar_sprite.w, height = health_bar_sprite.h}
    health_fill_source := rl.Rectangle {x = health_bar_fill_sprite.x, y = health_bar_fill_sprite.y, width = health_bar_fill_sprite.w * (player.stats.health_stats.current_hp / player.stats.health_stats.current_hp), height = health_bar_fill_sprite.h}


    health_bar_dest := rl.Rectangle {x = ui_x_start + 15 , y = ui_y_start , width = HEALTH_BAR_SIZE.x, height = HEALTH_BAR_SIZE.y}
    health_fill_dest := rl.Rectangle {x = ui_x_start + 15 , y = ui_y_start , width = HEALTH_BAR_SIZE.x * (player.stats.health_stats.current_hp / player.stats.health_stats.current_hp), height = HEALTH_BAR_SIZE.y}
    
    rl.DrawTexturePro(game.game_sprite_atlas, health_bar_source, health_bar_dest, {0, 0}, 0, rl.WHITE)
    rl.DrawTexturePro(game.game_sprite_atlas, health_fill_source, health_fill_dest, {0, 0}, 0, rl.WHITE)
    
    // is_mouse_hover := rl.CheckCollisionPointRec(game.game_options.ui_mouse_pos, charactor_ui_rect)
    

    key_dest :=  rl.Rectangle {x = ui_x_start, y = avatar_dest.y + avatar_dest.height , height = 12, width = 12}
    rl.DrawTexturePro(game.game_sprite_atlas, key_source, key_dest, {0, 0}, 0, rl.WHITE)

    key_text := fmt.ctprintf(":%d/%d", game.level_data.collected_keys, len(game.level_data.keys))
    key_font_size : i32 = 1
    rl.DrawText(key_text, i32(key_dest.x + key_dest.width), i32(key_dest.y + key_dest.height /2 - 3), key_font_size, rl.BLACK)
//     rl.DrawRectangleRec( health_bar_rect, rl.GRAY )
//     rl.DrawRectangleRec(rl.Rectangle {x = health_bar_rect.x, y= health_bar_rect.y, width = (game.player.stats.health_stats.current_hp / game.player.stats.health_stats.max_hp) * health_bar_size.x - 10, height = health_bar_size.y}, rl.RED)
}