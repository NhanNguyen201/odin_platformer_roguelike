package main

import rl "vendor:raylib"
import "core:fmt"

UI_SHOP_ITEM_SLOT_SIZE : rl.Vector2 : {60, 100}


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
    } else if game.ui_controller.ui_scene == .SHOPPING {
        if rl.IsKeyPressed(.ENTER) {
            load_level(game, game.current_level + 1)

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
        coins_text := fmt.ctprintf("Coins you got : %.0f", game.player.money_coins.val)
        rl.DrawTextPro(game.fonts[FONT_REG], coins_text, {ui_rect.x + 10, ui_rect.y + 10}, 0, 0, 12, 0.1, rl.WHITE)

        shop_open_rect := rl.Rectangle {x = ui_rect.x + 10 , y = ui_rect.y + 25, width = 75, height = 15}
        is_shop_hover := is_ui_component_hover(game.game_options, shop_open_rect)
        ui_box_draw(game.game_sprite_atlas, shop_open_rect, is_shop_hover)
        shop_open_text := fmt.ctprintf("Go shopping :> ")
        rl.DrawTextPro(game.fonts[FONT_BOLD], shop_open_text, {shop_open_rect.x + 5, shop_open_rect.y + 7.5}, {0, 4.5}, 0, 9, 0.1, rl.WHITE)
        if is_shop_hover && rl.IsMouseButtonPressed(.LEFT)  {
            game.ui_controller.ui_scene = .SHOPPING
        }
        next_level_rect := rl.Rectangle {x = get_rect_center(ui_rect).x - UI_NEXT_LEVEL_RECT_SIZE.x / 2, y = ui_rect.y + ui_rect.height - UI_NEXT_LEVEL_RECT_SIZE.y - 10 , width = UI_NEXT_LEVEL_RECT_SIZE.x, height = UI_NEXT_LEVEL_RECT_SIZE.y}
        is_next_level_hover := is_ui_component_hover(game.game_options, next_level_rect)

        ui_box_draw(game.game_sprite_atlas, next_level_rect, is_next_level_hover)


        next_level_text := fmt.ctprintf("Next level")
        measured, font_size, spacing := get_text_to_ui(game.fonts[FONT_REG],next_level_text, 12, 0.1)

        rl.DrawTextPro(game.fonts[FONT_REG], next_level_text, get_rect_center(next_level_rect), measured / 2, 0, font_size, spacing, rl.WHITE)
        if is_next_level_hover && rl.IsMouseButtonPressed(.LEFT)  {
            load_level(game, game.current_level + 1)
        }
    } else if game.ui_controller.ui_scene == .SHOPPING {
        ui_scr_source := get_sprite_source_rect(SPRITE_MAP[UI_SCREEN_SPRITE])
        rl.DrawTexturePro(game.game_sprite_atlas, ui_scr_source, ui_rect, 0, 0, rl.Color {180,180,180, 255})
        current_money := fmt.ctprintf("You got %.0f coins", game.player.money_coins.val)
        rl.DrawTextPro(game.fonts[FONT_BOLD], current_money, {ui_rect.x + 5, ui_rect.y + 5}, 0,0, 12, 0.5, rl.WHITE)
        for i := 0; i < SHOP_ITEM_SLOT_NUM; i += 1 {
            shop_item := game.shop_manager.items[i]
            slot_rect := rl.Rectangle {x = (UI_SHOP_ITEM_SLOT_SIZE.x + UI_BUFF_PICK_PADDING.x * 2) * f32(i) + ui_rect.x + UI_BUFF_PICK_PADDING.x, y = ui_rect.y + UI_BUFF_PICK_PADDING.y, width = UI_SHOP_ITEM_SLOT_SIZE.x, height = UI_SHOP_ITEM_SLOT_SIZE.y}
            rl.DrawRectangleRec(slot_rect, rl.Color {225,225,225,225})
            item_rect := rl.Rectangle {x = slot_rect.x + 2.5, y = slot_rect.y + 2.5, width = 55, height = 55}
            price_text := fmt.ctprintf("%.0f coins", shop_item.price)
            rl.DrawTextPro(game.fonts[FONT_BOLD], price_text, {slot_rect.x + slot_rect.width / 2, item_rect.y + item_rect.height + 5.},{f32(rl.MeasureText(price_text, 10)) / 2, 6}, 0, 10,0.5, rl.BLACK)
            item_tooltip := player_item_slot_draw(game.game_sprite_atlas, Player_item {type = game.shop_manager.items[i].item_type}, item_rect)
            formated_tooltip := fmt.ctprintf(item_tooltip)
            if shop_item.item_status == .SOLD {
                rl.DrawRectangleRec(item_rect, rl.Color{0,0,0, 180})
            }
            rl.DrawTextPro(game.fonts[FONT_REG], formated_tooltip, {item_rect.x, item_rect.y + item_rect.height + 10}, 0, 0, 5, 0.05, rl.BLACK)

            buy_text_rect := rl.Rectangle {x = slot_rect.x + 15, y = slot_rect.y + slot_rect.height - 15, width = 30, height = 12}
            is_text_hovered := is_ui_component_hover(game.game_options, buy_text_rect)
            ui_box_draw(game.game_sprite_atlas, buy_text_rect, is_text_hovered)
            buy_text := fmt.ctprintf("Buy")
            
            rl.DrawTextPro(game.fonts[FONT_REG], buy_text, {buy_text_rect.x + 5, buy_text_rect.y + buy_text_rect.height / 2}, {0, 4}, 0, 8, 0.1, rl.WHITE)
            
            if is_text_hovered && rl.IsMouseButtonPressed(.LEFT) {
                _, bought_err := resolve_buy_item(&game.shop_manager, i, &game.player.pocket_items, &game.player.money_coins)
                switch bought_err {
                    case .INVALID_ACTION : {
                        add_particle(&game.particle_system, {
                            timer ={ max_time = 0.5, current = 0.5},
                            size = {30, 20},
                            vel = {0, -20},
                            position = get_rect_center(buy_text_rect) + {10, -10},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_SHOP_INVALID])

                        })
                    }
                    case .NOT_ENOUGH_COINS : {
                        add_particle(&game.particle_system, {
                            timer ={ max_time = 0.5, current =0.5},
                            size = {30, 20},
                            vel = {0, -20},
                            position = get_rect_center(buy_text_rect) + {10, -10},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_SHOP_NOT_ENOUGH_MONEY])

                        })
                    }
                    case .POCKET_FULL : {
                        add_particle(&game.particle_system, {
                            timer ={ max_time = 0.5, current =0.5},
                            size = {30, 20},
                            vel = {0, -20},
                            position = get_rect_center(buy_text_rect) + {10, -10},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_SHOP_NOT_ENOUGH_MONEY])

                        })
                    }
                    case .SOLD : {
                        add_particle(&game.particle_system, {
                            timer ={ max_time = 0.5, current =0.5},
                            size = {30, 20},
                            vel = {0, -20},
                            position = get_rect_center(buy_text_rect) + {10, -10},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_SHOP_SOLDOUT])

                        })
                    }
                    case .NONE : {
                        add_particle(&game.particle_system, {
                            timer ={ max_time = 0.5, current =0.5},
                            size = {30, 20},
                            vel = {0, -20},
                            position = get_rect_center(buy_text_rect) + {10, -10},
                            sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_SHOP_SUCCESS])

                        })
                    }
                }
            }
        }
        next_level_rect := rl.Rectangle {x = get_rect_center(ui_rect).x - UI_NEXT_LEVEL_RECT_SIZE.x / 2, y = ui_rect.y + ui_rect.height - UI_NEXT_LEVEL_RECT_SIZE.y - 10, width = UI_NEXT_LEVEL_RECT_SIZE.x, height = UI_NEXT_LEVEL_RECT_SIZE.y}
        next_level_text := fmt.ctprintf("Next level")
        is_next_level_hover := is_ui_component_hover(game.game_options, next_level_rect)
        ui_box_draw(game.game_sprite_atlas, next_level_rect, is_next_level_hover)
        measured, font_size, spacing := get_text_to_ui(game.fonts[FONT_REG],next_level_text, 12, 0.1)

        rl.DrawTextPro(game.fonts[FONT_REG], next_level_text, get_rect_center(next_level_rect), measured / 2, 0, font_size, spacing, rl.WHITE)

        if is_next_level_hover && rl.IsMouseButtonPressed(.LEFT) {
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