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
    }
    // Level start
    if game.ui_controller.ui_scene == .START_LEVEL && game.ui_controller.transition_time > 0 { 
        game.ui_controller.transition_time -= dt    
    }
    
    if game.ui_controller.ui_scene == .START_LEVEL && game.ui_controller.transition_time <= 0 {
        game.ui_controller.is_ui_screen = false
        game.game_options.is_paused = false
        game.ui_controller.ui_scene = .NONE
    }
}

game_ui_scene_draw::proc(game: ^Game, dt: f32) {
    ui_x_start := game.player.body.position.x +  + UI_PADDING.x - game.camera.offset.x / 4
    ui_y_start := game.player.body.position.y +  + UI_PADDING.y - game.camera.offset.y / 4

    ui_width := f32(rl.GetScreenWidth() / 4) - UI_PADDING.x / 2 
    ui_height := f32(rl.GetScreenHeight() / 4)  - UI_PADDING.y / 2
    
    ui_rect := rl.Rectangle{x = ui_x_start, y = ui_y_start, width = ui_width, height = ui_height}

    // boss entrance
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE && game.ui_controller.transition_time > 0 {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
    }

    // Level start
    if game.ui_controller.ui_scene == .START_LEVEL && game.ui_controller.transition_time > 0 {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
        start_level_text := fmt.ctprintf("New level start in %.2f", game.ui_controller.transition_time)
        rl.DrawTextPro(game.fonts[FONT_REG], start_level_text, get_rect_center(ui_rect), {20, 10}, 0, 10, 0.2, rl.WHITE)
    }
}