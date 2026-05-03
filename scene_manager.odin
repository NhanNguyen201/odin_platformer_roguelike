package main

import rl "vendor:raylib"
import "core:fmt"


// in pre update 
scene_manager_update :: proc(game: ^Game, dt: f32 ) {
    // Boss entrance scene update
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE { 
        if game.ui_controller.transition_time > 0  {
            game.ui_controller.transition_time -= dt    

        } else {
            game.ui_controller.is_ui_screen = false
            game.game_options.is_paused = false
            game.ui_controller.ui_scene = .NONE
            game.boss_manager.boss.status = .ALIVE
        }
    } else if game.ui_controller.ui_scene == .START_LEVEL  { 
        // Level start
        if game.ui_controller.transition_time > 0 {
            game.ui_controller.transition_time -= dt    

        } else {
            game.ui_controller.is_ui_screen = false
            game.game_options.is_paused = false
            game.ui_controller.ui_scene = .NONE
        }
    } else if game.ui_controller.ui_scene == .END_LEVEL {
        if rl.IsKeyPressed(.ENTER) {
            load_level(game, game.current_level + 1)

        }
    } else if game.ui_controller.ui_scene == .GAME_START {
         if rl.IsKeyReleased(.ENTER) {
            game.game_options.is_paused = false
            game.ui_controller.ui_scene = .NONE
            game.ui_controller.is_ui_screen = false
        }
    } else if game.ui_controller.ui_scene == .GAME_OVER {
        if rl.IsKeyReleased(.K) {
            game_restart(game)
        }
    }
}

game_ui_scene_draw::proc(game: ^Game, dt: f32) {
    ui_rect := get_ui_scene_rect(game^)

    // boss entrance
    if game.ui_controller.ui_scene == .BOSS_ENTRANCE {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
    } else if game.ui_controller.ui_scene == .START_LEVEL {
        rl.DrawRectangleRec(ui_rect, rl.BLACK)
        start_level_text := fmt.ctprintf("New level start in %.1fs", game.ui_controller.transition_time)
        rl.DrawTextPro(game.fonts[FONT_REG], start_level_text, get_rect_center(ui_rect), {40, 10}, 0, 10, 0.2, rl.WHITE)
    } else if game.ui_controller.ui_scene == .GAME_OVER {
        sprite := SPRITE_MAP[GAME_OVER_SPRITE]
        restart_text := fmt.ctprintf("Press K to restart")
        sprite_source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
        sprite_dest := rl.Rectangle {x = get_rect_center(ui_rect).x, y = get_rect_center(ui_rect).y, width = sprite.w, height = sprite.h }
        rl.DrawRectangleRec(ui_rect, rl.Color {0, 0, 0, 180})
        rl.DrawTexturePro(game.game_sprite_atlas, sprite_source, sprite_dest, {sprite_dest.width / 2, sprite_dest.height / 2}, 0, rl.WHITE)
        rl.DrawTextPro(game.fonts[FONT_REG], restart_text, {sprite_dest.x  - sprite_dest.width/ 2, sprite_dest.y + sprite_dest.height / 2 + 5}, 0, 0, 12, 0.2, rl.WHITE)
        

    } else if game.ui_controller.ui_scene == .GAME_START {
        sprite := SPRITE_MAP[GAME_START_SPRITE]
        sprite_source := get_sprite_source_rect(sprite)
        sprite_dest := rl.Rectangle {x = get_rect_center(ui_rect).x, y = get_rect_center(ui_rect).y, width = sprite.w, height = sprite.h }
        rl.DrawRectangleRec(ui_rect, rl.Color {0, 0, 0, 180})
        rl.DrawTexturePro(game.game_sprite_atlas, sprite_source, sprite_dest, {sprite_dest.width / 2, sprite_dest.height / 2}, 0, rl.WHITE)
       
    } else if game.ui_controller.ui_scene == .END_LEVEL {
        ui_scr_source := get_sprite_source_rect(SPRITE_MAP[UI_SCREEN_SPRITE])
        rl.DrawTexturePro(game.game_sprite_atlas, ui_scr_source, ui_rect, 0, 0, rl.WHITE)
        coins_text := fmt.ctprintf("Coins you got : %.0f", game.player.money_coins)
        rl.DrawTextPro(game.fonts[FONT_REG], coins_text, {ui_rect.x + 10, ui_rect.y + 10}, 0, 0, 12, 0.1, rl.WHITE)

        shop_open_rect := rl.Rectangle {x = ui_rect.x + 10 , y = ui_rect.y + 25, width = 75, height = 15}
        is_shop_hover := is_ui_component_hover(game.game_options, shop_open_rect)
        ui_box_draw(game.game_sprite_atlas, shop_open_rect)
        shop_open_text := fmt.ctprintf("Go shopping :> ")
        rl.DrawTextPro(game.fonts[FONT_BOLD], shop_open_text, {shop_open_rect.x + 5, shop_open_rect.y + 7.5}, {0, 4.5}, 0, 9, 0.1, rl.WHITE)

        next_level_rect := rl.Rectangle {x = ui_rect.x + ui_rect.width / 2 - 45, y = ui_rect.y + ui_rect.height - 40 , height = 20, width = 50}
        is_next_level_hover := is_ui_component_hover(game.game_options, next_level_rect)

        ui_box_draw(game.game_sprite_atlas, next_level_rect)


        next_level_text := fmt.ctprintf("Next level")
        rl.DrawTextPro(game.fonts[FONT_BOLD], next_level_text, {next_level_rect.x + 5, next_level_rect.y + 10}, {0, 4.5}, 0, 9, 0.1, rl.WHITE  )
        if is_next_level_hover && rl.IsMouseButtonPressed(.LEFT)  {
            load_level(game, game.current_level + 1)
        }
    }
}

get_ui_scene_rect :: proc (game: Game) -> rl.Rectangle {
    ui_x_start := game.player.body.position.x +  + UI_PADDING.x - game.camera.offset.x / 4
    ui_y_start := game.player.body.position.y +  + UI_PADDING.y - game.camera.offset.y / 4

    ui_width := f32(rl.GetScreenWidth() / 4) - UI_PADDING.x / 2 
    ui_height := f32(rl.GetScreenHeight() / 4)  - UI_PADDING.y / 2
    
    return {x = ui_x_start, y = ui_y_start, width = ui_width, height = ui_height}
}