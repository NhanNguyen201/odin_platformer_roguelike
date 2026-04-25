package main

import rl "vendor:raylib"
import "core:fmt"


// in pre update 
scene_manager_update :: proc(game: ^Game, dt: f32 ) {
    // Boss entrance scene update
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE && game.ui_controller.transition_time > 0 { 
        game.ui_controller.transition_time -= dt    
    }
    
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE && game.ui_controller.transition_time <= 0 {
        game.ui_controller.is_ui_screen = false
        game.game_options.is_paused = false
        game.ui_controller.ui_scene = .NONE
        game.boss_manager.boss.status = .ALIVE
    }
    // Level start
    if game.ui_controller.ui_scene == .START_LEVEL  { 
        if game.ui_controller.transition_time > 0 {
            game.ui_controller.transition_time -= dt    

        } else {
            game.ui_controller.is_ui_screen = false
            game.game_options.is_paused = false
            game.ui_controller.ui_scene = .NONE
        }
    }
}

game_ui_scene_draw::proc(game: ^Game, dt: f32) {
    ui_x_start := game.player.body.position.x +  + UI_PADDING.x - game.camera.offset.x / 4
    ui_y_start := game.player.body.position.y +  + UI_PADDING.y - game.camera.offset.y / 4

    ui_width := f32(rl.GetScreenWidth() / 4) - UI_PADDING.x / 2 
    ui_height := f32(rl.GetScreenHeight() / 4)  - UI_PADDING.y / 2
    
    ui_rect := rl.Rectangle{x = ui_x_start, y = ui_y_start, width = ui_width, height = ui_height}

    // boss entrance
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
    }

    // Level start
    if game.ui_controller.ui_scene == .START_LEVEL {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
        start_level_text := fmt.ctprintf("New level start in %.1fs", game.ui_controller.transition_time)
        rl.DrawTextPro(game.fonts[FONT_REG], start_level_text, get_rect_center(ui_rect), {40, 10}, 0, 10, 0.2, rl.WHITE)
    }

    if game.ui_controller.ui_scene == .GAME_OVER {
        sprite := SPRITE_MAP[GAME_OVER_SPRITE]
        restart_text := fmt.ctprintf("Press K to restart")
        sprite_source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
        sprite_dest := rl.Rectangle {x = get_rect_center(ui_rect).x, y = get_rect_center(ui_rect).y, width = sprite.w, height = sprite.h }
        rl.DrawRectangleRec(ui_rect, rl.Color {0, 0, 0, 180})
        rl.DrawTexturePro(game.game_sprite_atlas, sprite_source, sprite_dest, {sprite_dest.width / 2, sprite_dest.height / 2}, 0, rl.WHITE)
        rl.DrawTextPro(game.fonts[FONT_REG], restart_text, {sprite_dest.x  - sprite_dest.width/ 2, sprite_dest.y + sprite_dest.height / 2 + 5}, 0, 0, 12, 0.2, rl.WHITE)
        if rl.IsKeyReleased(.K) {
            game_restart(game)
        }

    }
    if game.ui_controller.ui_scene == .GAME_START {
        sprite := SPRITE_MAP[GAME_START_SPRITE]
        sprite_source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
        sprite_dest := rl.Rectangle {x = get_rect_center(ui_rect).x, y = get_rect_center(ui_rect).y, width = sprite.w, height = sprite.h }
        rl.DrawRectangleRec(ui_rect, rl.Color {0, 0, 0, 180})
        rl.DrawTexturePro(game.game_sprite_atlas, sprite_source, sprite_dest, {sprite_dest.width / 2, sprite_dest.height / 2}, 0, rl.WHITE)
        if rl.IsKeyReleased(.ENTER) {
            game.game_options.is_paused = false
            game.ui_controller.ui_scene = .NONE
            game.ui_controller.is_ui_screen = false
        }
    }
}