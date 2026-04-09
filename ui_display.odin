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

MAX_ATS_BUFF_AMOUNT: f32: 70
MAX_MVSP_BUFF_AMOUNT: f32: 100
MAX_AR_BUFF_AMOUNT: f32: 80

Buff_detail :: struct {
    sprite: string,
    buff : STAT_BUFF,
    val : f32,
    description: string
}
roboto_font := rl.Font{}
BUFF_SLOTS :[5]Buff_detail :{
    Buff_detail {buff = .HP, sprite = HP_BUFF_SPRITE, val = 30, description = "Heal you 25% max HP \nInscrease max HP by 30"},
    Buff_detail {buff = .AD, sprite = AD_BUFF_SPRITE, val = 10, description = "Increase 10% dmg"},
    Buff_detail {buff = .ATS, sprite = ATS_BUFF_SPRITE, val = 80, description = "Shoot 25% faster"},
    Buff_detail {buff = .MVSPD, sprite = MVSP_BUFF_SPRITE, val = 25, description = "Move 25% faster"},
    Buff_detail {buff = .AR, sprite = AR_BUFF_SPRITE, val = 10, description = "Reduce incoming damage by 10%"},
}

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
    

    key_dest :=  rl.Rectangle {x = get_rect_center(avatar_dest).x, y = get_rect_center(avatar_dest).y + 16 , height = 12, width = 12}
    rl.DrawTexturePro(game.game_sprite_atlas, key_source, key_dest, {key_source.width  / 2 , key_source.height / 2}, 0, rl.WHITE)

    key_text := fmt.ctprintf(":%d/%d", game.level_data.collected_keys, len(game.level_data.keys))
    rl.DrawTextEx(game.fonts[FONT_THIN], key_text, {key_dest.x + 8, key_dest.y - 5}, 7.5, .5, rl.BLACK)
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

    inner_rect := rl.Rectangle {x = ui_rect.x + UI_BUFF_PICK_PADDING.x, y = ui_rect.y + UI_BUFF_PICK_PADDING.y, width = ui_rect.width - UI_BUFF_PICK_PADDING.x * 2, height = ui_rect.height - UI_BUFF_PICK_PADDING.y * 2}
    rl.DrawRectangleRec(inner_rect, rl.BLACK)

    for buff, idx in BUFF_SLOTS {
        slot_rect := rl.Rectangle {x = inner_rect.x + f32(idx) * ( 2 * UI_BUFF_PICK_SLOT_PADDING.x + UI_BUFF_PICK_SLOT_WIDTH) + UI_BUFF_PICK_SLOT_PADDING.x, y = inner_rect.y + UI_BUFF_PICK_SLOT_PADDING.y, width = UI_BUFF_PICK_SLOT_WIDTH, height = inner_rect.height - UI_BUFF_PICK_SLOT_PADDING.y * 2}
        rl.DrawRectangleRec(slot_rect, rl.WHITE)
        //  Buff 1
        sprite := SPRITE_MAP[buff.sprite]
        source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
        dest := rl.Rectangle {x = slot_rect.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
        rl.DrawTexturePro(atlas, source, dest, {0, 0}, 0, rl.WHITE)
        pick_buff_handle(game_options, ui_controller, dest, player, buff.buff, buff.val)
    }
}

pick_buff_handle :: proc(game_options: ^Game_Options, ui_controller: ^UI_Controller, buff_rect : rl.Rectangle, player: ^Player, buff: STAT_BUFF, amount: f32) {
    if rl.CheckCollisionPointRec(game_options.ui_mouse_pos, buff_rect) {
        if rl.IsMouseButtonDown(.LEFT) {
            switch buff {
                case .HP: {
                    player.stats.health_stats.max_hp += amount
                    player.stats.health_stats.current_hp += 0.25 * player.stats.health_stats.max_hp
                }
                case .AD: { 
                    player.stats.buffes.damage += amount
                }
                case .ATS: {
                    if player.stats.buffes.at_spd + amount >= MAX_ATS_BUFF_AMOUNT {
                        player.stats.buffes.at_spd = MAX_ATS_BUFF_AMOUNT
                    } else {
                        player.stats.buffes.at_spd += amount
                    }
                }

                case .AR: {
                     if player.stats.buffes.armor + amount >= MAX_AR_BUFF_AMOUNT {
                        player.stats.buffes.armor = MAX_AR_BUFF_AMOUNT
                    } else {
                        player.stats.buffes.armor += amount
                    }
                }
                case .MVSPD : {
                    if player.stats.buffes.mv_spd + amount >= MAX_MVSP_BUFF_AMOUNT {
                        player.stats.buffes.mv_spd = MAX_MVSP_BUFF_AMOUNT
                    } else {
                        player.stats.buffes.mv_spd += amount
                    }
                }

            }

            ui_controller.is_buff_pick = false
            game_options.is_paused = false
        }
    } 
}