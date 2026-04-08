package main
import rl "vendor:raylib"
import "core:fmt"

UI_PADDING : rl.Vector2 : {15, 15}
UI_BUFF_PICK_PADDING: rl.Vector2 : {5, 40}
UI_BUFF_PICK_SLOT_WIDTH: f32 : 40
UI_BUFF_PICK_SLOT_PADDING: rl.Vector2 : {5, 5}
UI_BUFF_PICK_SLOT_ICON_PADDING: rl.Vector2 : {5, 5}
UI_BUFF_PICK_SIZE : rl.Vector2 :{12, 12}

HEALTH_BAR_SIZE : rl.Vector2: {40, 7}
EXPERIENCE_BAR_SIZE: rl.Vector2: {40, 5}



get_rect_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
    return {rect.x + (rect.width / 2), rect.y + (rect.height / 2) }
}

UI_Controller :: struct {
    is_buff_pick: bool
}

is_ui_component_hover :: proc(game_options: Game_Options, rect : rl.Rectangle) -> bool { 
    return rl.CheckCollisionPointRec(game_options.ui_mouse_pos, rect)
}



player_ui_draw:: proc(game: ^Game) {
    key_atlas_sprite := SPRITE_MAP[KEY_SPRITE]

    key_source := rl.Rectangle{x = key_atlas_sprite.x , y= key_atlas_sprite.y , width = key_atlas_sprite.w , height = key_atlas_sprite.h}


    player := game.player
    
    ui_x_start := player.body.position.x +  + UI_PADDING.x - game.camera.offset.x / 4
    ui_y_start := player.body.position.y +  + UI_PADDING.y - game.camera.offset.y / 4

    ui_width := f32(rl.GetScreenWidth() / 4) - UI_PADDING.x 
    ui_height := f32(rl.GetScreenHeight() / 4)  - UI_PADDING.y
    
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
    rl.DrawRectangleRec(
        rl.Rectangle{x = ui_x_start + 15, y = ui_y_start + HEALTH_BAR_SIZE.y + 2.5, width = EXPERIENCE_BAR_SIZE.x, height = EXPERIENCE_BAR_SIZE.y },
        rl.DARKBLUE
    )
    rl.DrawRectangleRec(
        rl.Rectangle{x = ui_x_start + 15, y = ui_y_start + HEALTH_BAR_SIZE.y + 2.5, width = EXPERIENCE_BAR_SIZE.x * (player.exp_controller.current / player.exp_controller.require.val), height = EXPERIENCE_BAR_SIZE.y },
        rl.WHITE
    )
    if game.game_options.is_paused && game.ui_controller.is_buff_pick {
        rl.DrawRectangle(i32(ui_x_start), i32(ui_y_start), i32 (ui_width), i32(ui_height), rl.Color {184, 226, 217, 160})
        player_buff_picking_scene_draw(game.game_sprite_atlas, ui_rect, &game.game_options, &game.ui_controller, &game.player)
    }

}


player_buff_picking_scene_draw:: proc(atlas: rl.Texture2D, ui_rect : rl.Rectangle, game_options: ^Game_Options, ui_controller: ^UI_Controller, player: ^Player) {
    draw_cursor := rl.Vector2 {0, 0}

    inner_rect := rl.Rectangle {x = ui_rect.x + UI_BUFF_PICK_PADDING.x, y = ui_rect.y + UI_BUFF_PICK_PADDING.y, width = ui_rect.width - UI_BUFF_PICK_PADDING.x * 2, height = ui_rect.height - UI_BUFF_PICK_PADDING.y * 2}
    rl.DrawRectangleRec(inner_rect, rl.BLACK)

    slot_rect_1 := rl.Rectangle {x = inner_rect.x + UI_BUFF_PICK_SLOT_PADDING.x, y = inner_rect.y + UI_BUFF_PICK_SLOT_PADDING.y, width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
    rl.DrawRectangleRec(slot_rect_1, rl.WHITE)
    //  Buff 1
    hp_sprite := SPRITE_MAP[HP_BUFF_SPRITE]
    hp_source := rl.Rectangle {x = hp_sprite.x, y= hp_sprite.y, width = hp_sprite.w, height = hp_sprite.h}
    hp_dest := rl.Rectangle {x = slot_rect_1.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect_1.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
    rl.DrawTexturePro(atlas, hp_source, hp_dest, {0, 0}, 0, rl.WHITE)
    pick_buff_handle(game_options, ui_controller, hp_dest, player, .HP, 30.)

    draw_cursor += {slot_rect_1.x + UI_BUFF_PICK_SLOT_WIDTH + UI_BUFF_PICK_SLOT_PADDING.x , slot_rect_1.y}

    slot_rect_2 := rl.Rectangle {x = draw_cursor.x + UI_BUFF_PICK_SLOT_PADDING.x, y = draw_cursor.y , width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
    rl.DrawRectangleRec(slot_rect_2, rl.WHITE)
    //  Buff 2
    ad_sprite := SPRITE_MAP[AD_BUFF_SPRITE]
    ad_source := rl.Rectangle {x = ad_sprite.x, y= ad_sprite.y, width = ad_sprite.w, height = ad_sprite.h}
    ad_dest := rl.Rectangle {x = slot_rect_2.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect_2.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
    rl.DrawTexturePro(atlas, ad_source, ad_dest, {0, 0}, 0, rl.WHITE)
    pick_buff_handle(game_options, ui_controller, ad_dest, player, .AD, 30.)



    draw_cursor += {UI_BUFF_PICK_SLOT_WIDTH + UI_BUFF_PICK_SLOT_PADDING.x * 2, 0}

    slot_rect_3 := rl.Rectangle {x = draw_cursor.x + UI_BUFF_PICK_SLOT_PADDING.x, y = draw_cursor.y , width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
    rl.DrawRectangleRec(slot_rect_3, rl.WHITE)
    //  Buff 3
    ats_sprite := SPRITE_MAP[ATS_BUFF_SPRITE]
    ats_source := rl.Rectangle {x = ats_sprite.x, y= ats_sprite.y, width = ats_sprite.w, height = ats_sprite.h}
    ats_dest := rl.Rectangle {x = slot_rect_3.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect_3.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
    rl.DrawTexturePro(atlas, ats_source, ats_dest, {0, 0}, 0, rl.WHITE)
    pick_buff_handle(game_options, ui_controller, ats_dest, player, .ATS, 30.)

    draw_cursor += { UI_BUFF_PICK_SLOT_WIDTH + UI_BUFF_PICK_SLOT_PADDING.x * 2, 0}


    slot_rect_4 := rl.Rectangle {x = draw_cursor.x + UI_BUFF_PICK_SLOT_PADDING.x, y = draw_cursor.y , width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
    rl.DrawRectangleRec(slot_rect_4, rl.WHITE)
    //  Buff 4
    mvspd_sprite := SPRITE_MAP[MVSP_BUFF_SPRITE]
    mvspd_source := rl.Rectangle {x = mvspd_sprite.x, y= mvspd_sprite.y, width = mvspd_sprite.w, height = mvspd_sprite.h}
    mvspd_dest := rl.Rectangle {x = slot_rect_4.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect_4.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
    rl.DrawTexturePro(atlas, mvspd_source, mvspd_dest, {0, 0}, 0, rl.WHITE)
    pick_buff_handle(game_options, ui_controller, mvspd_dest, player, .MVSPD, 100.)


    draw_cursor += { UI_BUFF_PICK_SLOT_WIDTH + UI_BUFF_PICK_SLOT_PADDING.x * 2, 0}
    slot_rect_5 := rl.Rectangle {x = draw_cursor.x + UI_BUFF_PICK_SLOT_PADDING.x, y = draw_cursor.y , width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
    rl.DrawRectangleRec(slot_rect_5, rl.WHITE)
    //  Buff 5

    ar_sprite := SPRITE_MAP[AR_BUFF_SPRITE]
    ar_source := rl.Rectangle {x = ar_sprite.x, y= ar_sprite.y, width = ar_sprite.w, height = ar_sprite.h}
    ar_dest := rl.Rectangle {x = slot_rect_5.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect_5.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
    rl.DrawTexturePro(atlas, ar_source, ar_dest, {0, 0}, 0, rl.WHITE)
    pick_buff_handle(game_options, ui_controller, ar_dest, player, .AR, 30.)



}

pick_buff_handle :: proc(game_options: ^Game_Options, ui_controller: ^UI_Controller, buff_rect : rl.Rectangle, player: ^Player, buff: STAT_BUFF, amount: f32) {
    if rl.CheckCollisionPointRec(game_options.ui_mouse_pos, buff_rect) {
        if rl.IsMouseButtonDown(.LEFT) {
            switch buff {
                case .HP: player.stats.health_stats.max_hp += amount
                case .AD: player.stats.buffes.damage += amount
                case .ATS: player.stats.buffes.at_spd += amount
                case .AR: player.stats.buffes.armor += amount
                case .MVSPD : player.stats.buffes.mv_spd += amount

            }

            ui_controller.is_buff_pick = false
            game_options.is_paused = false
        }
    }
}