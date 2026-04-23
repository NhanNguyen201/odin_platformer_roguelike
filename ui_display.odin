package main
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

UI_PADDING : rl.Vector2 : {8, 8}
UI_BUFF_PICK_PADDING: rl.Vector2 : {4, 25}
UI_BUFF_PICK_ROW_HEIGHT :f32: 60 
UI_BUFF_PICK_SLOT_SIZE: rl.Vector2 : {50, 60}
UI_BUFF_PICK_SLOT_PADDING: rl.Vector2 : {4, 4}
UI_BUFF_PICK_SLOT_ICON_PADDING: rl.Vector2 : {3, 5}
UI_BUFF_PICK_SIZE : rl.Vector2 :{12, 12}
UI_BUFF_TITLE_SIZE: f32 : 5
UI_BUFF_DESCRIPTION_SIZE: f32: 4

UI_SKILL_HUB_SIZE: rl.Vector2 : {120, 20} 
UI_SKILL_HUB_PADDING: rl.Vector2 : {2.5, 2.5}
UI_SKILL_HUD_SLOT_SIZE : rl.Vector2: {15, 15}
UI_MINI_MAP_SIZE: rl.Vector2 : {50, 45}
UI_MINI_MAP_MAX_DISTANCE_DRAW: f32: 170
UI_MINI_MAP_CIRCLE_RADIUS: f32 : 20 

UI_PAUSED_SIGN_SIZE : rl.Vector2 : {80, 40}

UI_CURSIR_SIZE : rl.Vector2: { 16 , 16}
UI_UNIT_EXPRESSION_SIZE : rl.Vector2 : {16, 16}

HEALTH_BAR_SIZE : rl.Vector2: {40, 7}
EXPERIENCE_BAR_SIZE: rl.Vector2: {40, 5}

MAX_ATS_BUFF_AMOUNT: f32: 70
MAX_MVSP_BUFF_AMOUNT: f32: 100
MAX_AR_BUFF_AMOUNT: f32: 80


UI_scenes :: enum  {
    NONE,
    BUFFES_PICK,
    MENU,
    BOSS_ENTRANCE,
    END_LEVEL,
    START_LEVEL
}

Buff_detail :: struct {
    sprite: string,
    buff : STAT_BUFF,
    val : f32,
    description: string,
    title: string
}


BUFF_SLOTS :[5]Buff_detail :{
    Buff_detail {buff = .HP, sprite = HP_BUFF_SPRITE, val = 30, title = "Oak Skin", description = "Heal you 25% max HP \nInscrease max HP by 30"},
    Buff_detail {buff = .AD, sprite = AD_BUFF_SPRITE, val = 10, title = "Fire Fist", description = "Increase 10% dmg"},
    Buff_detail {buff = .ATS, sprite = ATS_BUFF_SPRITE, val = 10, title = "Flame Thrower", description = "Shoot 10% faster"},
    Buff_detail {buff = .MVSPD, sprite = MVSP_BUFF_SPRITE, val = 15, title="The Wind", description = "Move 15% faster"},
    Buff_detail {buff = .AR, sprite = AR_BUFF_SPRITE, val = 10, title = "Nut Shell", description = "Reduce damage taken \n by 10%"},
}

get_rect_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
    return {rect.x + (rect.width / 2), rect.y + (rect.height / 2) }
}

UI_Controller :: struct {
    is_ui_screen: bool,
    ui_scene: UI_scenes,
    transition_time: f32
}

UI_Cursor_Controller :: struct {
    draw_cursor : bool,
    current_cursor : UI_Cursor_types
}

UI_Cursor_types :: enum {
    DEFAULT,
    NONE,
    HOVER
}

render_cursor :: proc (atlas: rl.Texture2D, game_options: Game_Options) {
    sprite_desc : Sprite_desc
    cursor := game_options.cursor_controler.current_cursor
    if cursor != .NONE  && game_options.cursor_controler.draw_cursor{
        if cursor == .DEFAULT {
            sprite_desc = SPRITE_MAP[UI_CURSIR_SPRITE_1]
            source := rl.Rectangle {x = sprite_desc.x, y = sprite_desc.y, width = sprite_desc.w, height = sprite_desc.h}
            dest := rl.Rectangle {x = game_options.ui_mouse_pos.x, y = game_options.ui_mouse_pos.y, width = UI_CURSIR_SIZE.x, height = UI_CURSIR_SIZE.y}
            rl.DrawTexturePro(atlas, source, dest, {dest.width / 2, dest.height / 2}, 0, rl.WHITE)
        } else if cursor == .HOVER {
            sprite_desc = SPRITE_MAP[UI_CURSIR_SPRITE_2]
            source := rl.Rectangle {x = sprite_desc.x, y = sprite_desc.y, width = sprite_desc.w, height = sprite_desc.h}
            dest := rl.Rectangle {x = game_options.ui_mouse_pos.x, y = game_options.ui_mouse_pos.y, width = UI_CURSIR_SIZE.x, height = UI_CURSIR_SIZE.y}
            rl.DrawTexturePro(atlas, source, dest, {dest.width / 2, dest.height / 2}, 0, rl.WHITE)
        }
    }
}

render_temp_cursor :: proc(atlas: rl.Texture2D, sprite_desc : Sprite_desc,  game_options: Game_Options) {
    source := rl.Rectangle {x = sprite_desc.x, y = sprite_desc.y, width = sprite_desc.w, height = sprite_desc.h}
    dest := rl.Rectangle {x = game_options.ui_mouse_pos.x, y = game_options.ui_mouse_pos.y, width = UI_CURSIR_SIZE.x, height = UI_CURSIR_SIZE.y}
    rl.DrawTexturePro(atlas, source, dest, {dest.width / 2, dest.height / 2}, 0, rl.WHITE)
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

    ui_width := f32(rl.GetScreenWidth() / 4) - UI_PADDING.x / 2 
    ui_height := f32(rl.GetScreenHeight() / 4)  - UI_PADDING.y / 2
    
    ui_rect := rl.Rectangle{x = ui_x_start, y = ui_y_start, width = ui_width, height = ui_height}
    
    pause := fmt.ctprintf("%t", game.game_options.is_paused)
    
    if game.game_options.is_debug {
        rl.DrawRectangleLinesEx(ui_rect, 0.5, rl.WHITE)
        state_text := fmt.ctprintf("Paused :%t, \n is_ui : %t, \n is_buff_pick: %t", game.game_options.is_paused, game.ui_controller.is_ui_screen, game.ui_controller.ui_scene == .BUFFES_PICK) 
        rl.DrawTextPro(game.fonts[FONT_REG], state_text, {ui_x_start + ui_width - 150, ui_y_start + ui_height - 50}, 0,0, 6, 0.32, rl.WHITE)
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
    health_fill_source := rl.Rectangle {x = health_bar_fill_sprite.x, y = health_bar_fill_sprite.y, width = health_bar_fill_sprite.w * (player.stats.health_stats.current_hp / player.stats.health_stats.max_hp), height = health_bar_fill_sprite.h}


    health_bar_dest := rl.Rectangle {x = ui_x_start + 15 , y = ui_y_start , width = HEALTH_BAR_SIZE.x, height = HEALTH_BAR_SIZE.y}
    health_fill_dest := rl.Rectangle {x = ui_x_start + 15 , y = ui_y_start , width = HEALTH_BAR_SIZE.x * (player.stats.health_stats.current_hp / player.stats.health_stats.max_hp), height = HEALTH_BAR_SIZE.y}
    
    rl.DrawTexturePro(game.game_sprite_atlas, health_bar_source, health_bar_dest, {0, 0}, 0, rl.WHITE)
    rl.DrawTexturePro(game.game_sprite_atlas, health_fill_source, health_fill_dest, {0, 0}, 0, rl.WHITE)
    hp_text := fmt.ctprintf(" %.0f / %.0f", player.stats.health_stats.current_hp, player.stats.health_stats.max_hp)

    rl.DrawTextEx(game.fonts[FONT_REG], hp_text, {health_bar_dest.x + 2, health_bar_dest.y + 1}, 5, 0.2, rl.WHITE)
    // is_mouse_hover := rl.CheckCollisionPointRec(game.game_options.ui_mouse_pos, charactor_ui_rect)
    

    key_dest :=  rl.Rectangle {x = get_rect_center(avatar_dest).x, y = get_rect_center(avatar_dest).y + 16 , height = 12, width = 12}
    rl.DrawTexturePro(game.game_sprite_atlas, key_source, key_dest, {key_source.width  / 2 , key_source.height / 2}, 0, rl.WHITE)

    key_text := fmt.ctprintf(":%d/%d", game.level_data.collected_keys, len(game.level_data.keys))
    rl.DrawTextEx(game.fonts[FONT_BOLD], key_text, {key_dest.x + 8, key_dest.y - 5}, 8, .5, rl.WHITE)
    
    // Draw experience
    rl.DrawRectangleRec(
        rl.Rectangle{x = ui_x_start + 15, y = ui_y_start + HEALTH_BAR_SIZE.y + 1, width = EXPERIENCE_BAR_SIZE.x, height = EXPERIENCE_BAR_SIZE.y },
        rl.WHITE
    )
    rl.DrawRectangleRec(
        rl.Rectangle{x = ui_x_start + 15, y = ui_y_start + HEALTH_BAR_SIZE.y + 1, width = EXPERIENCE_BAR_SIZE.x * (player.exp_controller.current / player.exp_controller.require.val), height = EXPERIENCE_BAR_SIZE.y },
        rl.Color {247, 161, 56, 220}
    )
    lvl_text := fmt.ctprintf("Level %d : %d / %d", player.exp_controller.level + 1, i32(player.exp_controller.current), i32(player.exp_controller.require.val))
    rl.DrawTextEx(game.fonts[FONT_REG], lvl_text, {ui_x_start + 17, ui_y_start + HEALTH_BAR_SIZE.y + 1}, 5, 0.1, rl.BLACK)
    rl.DrawRectangleLinesEx(
        rl.Rectangle{x = ui_x_start + 15, y = ui_y_start + HEALTH_BAR_SIZE.y + 1, width = EXPERIENCE_BAR_SIZE.x, height = EXPERIENCE_BAR_SIZE.y },
        0.5,
        rl.BLACK
    )
    if game.game_options.is_mini_map {
        mini_map_draw(game.game_sprite_atlas, ui_rect, game.level_data, player.body)
    }

    if game.ui_controller.is_ui_screen && game.ui_controller.ui_scene == .BUFFES_PICK {
        rl.DrawRectangle(i32(ui_x_start), i32(ui_y_start), i32 (ui_width), i32(ui_height), rl.Color {184, 226, 217, 160})
        player_buff_picking_scene_draw(game.game_sprite_atlas, game.fonts ,ui_rect, &game.game_options, &game.ui_controller, &game.player)
    }
    if game.game_options.is_hub {
        skill_hud_draw(game.game_sprite_atlas, ui_rect, player)
    }
    if game.game_options.is_paused && !game.ui_controller.is_ui_screen {
        paused_sign_draw(game.game_sprite_atlas, ui_rect)
    }

    
}


player_buff_picking_scene_draw:: proc(atlas: rl.Texture2D, fonts: map[string] rl.Font, ui_rect : rl.Rectangle, game_options: ^Game_Options, ui_controller: ^UI_Controller, player: ^Player) {
    buff_picking_text := fmt.ctprintf("Please pick a buff for you")
    choose_text := fmt.ctprintf("Choose")


    inner_rect := rl.Rectangle {x = ui_rect.x + UI_BUFF_PICK_PADDING.x, y = ui_rect.y + UI_BUFF_PICK_PADDING.y, width = ui_rect.width - UI_BUFF_PICK_PADDING.x * 2, height = ui_rect.height - UI_BUFF_PICK_PADDING.y * 2}
    rl.DrawRectangleRec(inner_rect, rl.BLACK)
    rl.DrawTextPro(fonts[FONT_REG], buff_picking_text, {inner_rect.x + 15, inner_rect.y + 5}, {0, 0}, 0, 12, 0.25, rl.WHITE)
    col_width := 2 * UI_BUFF_PICK_SLOT_PADDING.x + UI_BUFF_PICK_SLOT_SIZE.x
    items_per_row := math.floor_f32(inner_rect.width / col_width)

    for buff, idx in BUFF_SLOTS {
        row := math.floor_f32(f32(idx) / items_per_row)
        col := idx % int(items_per_row)

        slot_rect := rl.Rectangle {x = inner_rect.x + f32(col) * col_width + UI_BUFF_PICK_SLOT_PADDING.x, y = inner_rect.y + f32(row) *  UI_BUFF_PICK_ROW_HEIGHT + UI_BUFF_PICK_SLOT_PADDING.y + UI_BUFF_PICK_PADDING.y, width = UI_BUFF_PICK_SLOT_SIZE.x, height = UI_BUFF_PICK_SLOT_SIZE.y}
        rl.DrawRectangleRec(slot_rect, rl.Color{255, 255, 255, 180})
        //  Buff 1
        sprite := SPRITE_MAP[buff.sprite]
        source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
        dest := rl.Rectangle {x = slot_rect.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x, y = slot_rect.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y, width = UI_BUFF_PICK_SIZE.x, height = UI_BUFF_PICK_SIZE.y}
        rl.DrawTexturePro(atlas, source, dest, {0, 0}, 0, is_ui_component_hover(game_options^, dest) ? rl.RED : rl.WHITE)

        rl.DrawTextEx(fonts[FONT_BOLD], fmt.ctprintf(buff.title), {slot_rect.x + UI_BUFF_PICK_SLOT_ICON_PADDING.x +  UI_BUFF_PICK_SIZE.x + 2, slot_rect.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y +  UI_BUFF_PICK_SIZE.y / 2  - UI_BUFF_TITLE_SIZE / 2}, UI_BUFF_TITLE_SIZE, 0.25, rl.BLACK)

        rl.DrawTextEx(fonts[FONT_REG], fmt.ctprint(buff.description), {slot_rect.x + 2, slot_rect.y + UI_BUFF_PICK_SLOT_ICON_PADDING.y +  UI_BUFF_PICK_SIZE.y + 2}, UI_BUFF_DESCRIPTION_SIZE, 0.1, rl.BLACK)
        
        pick_rect := rl.Rectangle {x = get_rect_center(slot_rect).x - 10, y = slot_rect.y + slot_rect.height - 15, width = 20, height = 10}
        rl.DrawRectangleRec(pick_rect, is_ui_component_hover(game_options^, pick_rect) ? rl.BLUE : rl.WHITE)
        rl.DrawTextPro(fonts[FONT_REG], choose_text, {pick_rect.x + 3, pick_rect.y + 3}, {0, 0}, 0, 5, 0.01, rl.BLACK)

        if rl.CheckCollisionPointRec(game_options.ui_mouse_pos, pick_rect) {
            if rl.IsMouseButtonDown(.LEFT) {
                pick_buff_handle(game_options, ui_controller, player, buff.buff, buff.val)

            }
        }


        // is_hover := is_ui_component_hover(game_options^, slot_rect)
        // if is_hover {
        //     if game_options.cursor_controler.current_cursor != .HOVER {
        //         // game_options.cursor_controler.current_cursor = .HOVER
        //         render_temp_cursor(atlas, SPRITE_MAP[UI_CURSIR_SPRITE_2], game_options^)
        //     }
        // } 

    }
}

pick_buff_handle :: proc(game_options: ^Game_Options, ui_controller: ^UI_Controller, player: ^Player, buff: STAT_BUFF, amount: f32) {
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

    ui_controller.is_ui_screen = false
    game_options.is_paused = false
    ui_controller.ui_scene = .NONE
}



skill_hud_draw :: proc(atlas: rl.Texture2D, ui_rect: rl.Rectangle, player: Player) {
    bullet_cd := player.bullet_cd

    shoot_sprite := SPRITE_MAP[SHOOT_SKILL_SPRITE]

    hud_rect := rl.Rectangle{x = ui_rect.x + ui_rect.width / 2 - UI_SKILL_HUB_SIZE.x / 2, y = ui_rect.y + ui_rect.height - UI_SKILL_HUB_SIZE.y, width = UI_SKILL_HUB_SIZE.x, height = UI_SKILL_HUB_SIZE.y}
    rl.DrawRectangleRec(hud_rect, rl.Color{200,200,200, 200})
    
    shoot_source := rl.Rectangle{ x = shoot_sprite.x, y = shoot_sprite.y, height = shoot_sprite.h, width = shoot_sprite.w}
    shoot_dest := rl.Rectangle { x = hud_rect.x + UI_SKILL_HUB_PADDING.x, y = hud_rect.y + UI_SKILL_HUB_PADDING.y, height = UI_SKILL_HUD_SLOT_SIZE.x, width = UI_SKILL_HUD_SLOT_SIZE.y}

    rl.DrawTexturePro(atlas, shoot_source, shoot_dest, {0, 0}, 0, rl.WHITE)
    rl.DrawRectangleLinesEx(shoot_dest, 0.5, rl.BLACK)

    rl.DrawRectangleRec(rl.Rectangle{x = shoot_dest.x, y = shoot_dest.y + (bullet_cd.max_time - bullet_cd.current_time) / bullet_cd.max_time * shoot_dest.height, height = bullet_cd.current_time / bullet_cd.max_time * shoot_dest.height, width = shoot_dest.width}, rl.Color {0, 0, 0, 180 })

}

mini_map_draw ::proc (atlas: rl.Texture2D, ui_rect: rl.Rectangle, level_data: Level_data, player: Body) {
    mini_map_rect := rl.Rectangle {x = ui_rect.x + ui_rect.width - UI_MINI_MAP_SIZE.x, y = ui_rect.y , width = UI_MINI_MAP_SIZE.x, height = UI_MINI_MAP_SIZE.y}
    mini_map_center: rl.Vector2 = get_rect_center(mini_map_rect)
    arrow_sprite := SPRITE_MAP[MINI_MAP_ARROW_SPRITE]
    arrow_source := rl.Rectangle {x = arrow_sprite.x, y= arrow_sprite.y, width = arrow_sprite.w, height = arrow_sprite.h}
    rl.DrawRectangleRec(mini_map_rect, rl.Color{200, 200, 200, 180})
    player_icon_size : f32 = 4
    item_icon_size : f32 = 1
    rl.DrawRectanglePro(
        rl.Rectangle{ x = mini_map_center.x, y= mini_map_center.y, width = player_icon_size, height = player_icon_size},
        {player_icon_size / 2, player_icon_size / 2},
        45, 
        rl.Color{12,12, 255, 180}
    )
    rl.DrawCircleLinesV(mini_map_center, UI_MINI_MAP_CIRCLE_RADIUS, rl.BLACK)
    for key in level_data.keys {
        if !key.collected {
            distance := get_distance(player.position, key.position)
            if distance < UI_MINI_MAP_MAX_DISTANCE_DRAW {
                mini_map_key_distance : f32 = distance / UI_MINI_MAP_MAX_DISTANCE_DRAW * UI_MINI_MAP_CIRCLE_RADIUS
                icon_pos : rl.Vector2 = {
                    mini_map_center.x + mini_map_key_distance * (key.position - player.position).x / distance,
                    mini_map_center.y + mini_map_key_distance * (key.position - player.position).y / distance
                } 
                rl.DrawCircleV(icon_pos, item_icon_size, rl.RED)
            } else {
                angle := math.atan2_f32((key.position - player.position).y,  (key.position - player.position).x) * (180. / math.PI)
                icon_pos : rl.Vector2 = {
                    mini_map_center.x + UI_MINI_MAP_CIRCLE_RADIUS * (key.position - player.position).x / distance,
                    mini_map_center.y + UI_MINI_MAP_CIRCLE_RADIUS * (key.position - player.position).y / distance
                } 
                arrow_dest := rl.Rectangle{x = icon_pos.x, y = icon_pos.y, width = 10, height = 10}
                rl.DrawTexturePro(atlas, arrow_source, arrow_dest, {arrow_dest.width / 2, arrow_dest.height /2}, angle + 90, rl.RED)
                // rl.DrawCircleV(icon_pos, key_icon_size, rl.RED)

            }
        }
    }
    for exp in level_data.exp_buffs {
        if !exp.collected {
            distance := get_distance(player.position, exp.position)
            if distance < UI_MINI_MAP_MAX_DISTANCE_DRAW {
                mini_map_exp_distance : f32 = distance / UI_MINI_MAP_MAX_DISTANCE_DRAW * UI_MINI_MAP_CIRCLE_RADIUS
                icon_pos : rl.Vector2 = {
                    mini_map_center.x + mini_map_exp_distance * (exp.position - player.position).x / distance,
                    mini_map_center.y + mini_map_exp_distance * (exp.position - player.position).y / distance
                } 
                rl.DrawCircleV(icon_pos, item_icon_size, rl.YELLOW)
            } else {
                angle := math.atan2_f32((exp.position - player.position).y,  (exp.position - player.position).x) * (180. / math.PI)
                icon_pos : rl.Vector2 = {
                    mini_map_center.x + UI_MINI_MAP_CIRCLE_RADIUS * (exp.position - player.position).x / distance,
                    mini_map_center.y + UI_MINI_MAP_CIRCLE_RADIUS * (exp.position - player.position).y / distance
                } 
                arrow_dest := rl.Rectangle{x = icon_pos.x, y = icon_pos.y, width = 10, height = 10}
                rl.DrawTexturePro(atlas, arrow_source, arrow_dest, {arrow_dest.width / 2, arrow_dest.height /2}, angle + 90, rl.YELLOW)
                // rl.DrawCircleV(icon_pos, key_icon_size, rl.RED)

            }
        }
    }

    gate_distance := get_distance(player.position, level_data.gate_position)
    if gate_distance < UI_MINI_MAP_MAX_DISTANCE_DRAW {
        mini_map_gate_distance : f32 = gate_distance / UI_MINI_MAP_MAX_DISTANCE_DRAW * UI_MINI_MAP_CIRCLE_RADIUS
        icon_pos : rl.Vector2 = {
            mini_map_center.x + mini_map_gate_distance * (level_data.gate_position - player.position).x / gate_distance,
            mini_map_center.y + mini_map_gate_distance * (level_data.gate_position - player.position).y / gate_distance
        } 
        rl.DrawCircleV(icon_pos, item_icon_size, rl.BLUE)
    } else {
        angle := math.atan2_f32((level_data.gate_position - player.position).y,  (level_data.gate_position - player.position).x) * (180. / math.PI)
        icon_pos : rl.Vector2 = {
            mini_map_center.x + UI_MINI_MAP_CIRCLE_RADIUS * (level_data.gate_position - player.position).x / gate_distance,
            mini_map_center.y + UI_MINI_MAP_CIRCLE_RADIUS * (level_data.gate_position - player.position).y / gate_distance
        } 
        arrow_dest := rl.Rectangle{x = icon_pos.x, y = icon_pos.y, width = 10, height = 10}
        rl.DrawTexturePro(atlas, arrow_source, arrow_dest, {arrow_dest.width / 2, arrow_dest.height /2}, angle + 90, rl.BLUE)
        // rl.DrawCircleV(icon_pos, key_icon_size, rl.RED)

    }
}

paused_sign_draw:: proc(atlas: rl.Texture2D, ui_rect: rl.Rectangle) {
    sprite := SPRITE_MAP[PAUSED_SIGN_SPRITE]
    sign_source := rl.Rectangle {x = sprite.x, y = sprite.y, width = sprite.w, height = sprite.h}
    sign_dest := rl.Rectangle { x = get_rect_center(ui_rect).x - UI_PAUSED_SIGN_SIZE.x / 2, y = ui_rect.y + ui_rect.height - UI_PAUSED_SIGN_SIZE.y - 20., width = UI_PAUSED_SIGN_SIZE.x, height = UI_PAUSED_SIGN_SIZE.y}
    rl.DrawTexturePro(atlas, sign_source, sign_dest, {0, 0}, 0, rl.WHITE)
}

get_distance:: proc(b1: rl.Vector2, b2: rl.Vector2) -> f32 {
    return math.sqrt_f32(math.pow_f32(b2.x - b1.x, 2) + math.pow_f32(b2.y - b1.y, 2))
}

unit_expression_draw:: proc(atlas: rl.Texture2D, sprite_desc: Sprite_desc, position: rl.Vector2) {
    sprite_source := rl.Rectangle {x = sprite_desc.x, y= sprite_desc.y, width = sprite_desc.w, height = sprite_desc.h}
    sprite_dest := rl.Rectangle {x = position.x, y= position.y, width = UI_UNIT_EXPRESSION_SIZE.x, height = UI_UNIT_EXPRESSION_SIZE.y}
    rl.DrawTexturePro(atlas, sprite_source, sprite_dest, get_rect_size(sprite_dest) / 2, 0, rl.WHITE)
}

get_rect_size :: proc(rect: rl.Rectangle) -> rl.Vector2 {
    return {rect.width, rect.height}
}

