#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:math/rand"
LEVEL_VENDOR_SIZE: rl.Vector2 : {20, 20}
LEVEL_VENDOR_FALSE_SPEED : f32 : 200

Vendor_enemy_buff :: enum {
    HP,
    ATTACK,
    COOLDOWN,
}

Level_vendor_enemy_buff_tooltips : map[Vendor_enemy_buff] Level_vendor_e_buff_disc = {
    .HP = {discription = "Enemy unit increase\n 15%% max HP", sprite = SPRITE_MAP[LEVEL_VENDOR_E_BUFF_HP_SPRITE]},
    .ATTACK = {discription = "Enemy unit increase\n 15%% attack",sprite = SPRITE_MAP[LEVEL_VENDOR_E_BUFF_ATTACK_SPRITE]},
    .COOLDOWN = {discription = "Enemy unit decrease\n 15%% cooldown skill", sprite = SPRITE_MAP[LEVEL_VENDOR_E_BUFF_COOLDOWN_SPRITE]},
}
Level_vendor_e_buff_disc :: struct {
    discription : string,
    sprite: Sprite_desc
}

Level_vendor :: struct {
    is_disabled: bool,
    item: Player_item_type,
    enemy_buff: Vendor_enemy_buff,
    body: Body,
    suggest_range: f32,
    is_player_near: bool,
    open_range: f32,
    can_open: bool
}

refresh_vender :: proc() -> (Player_item_type, Vendor_enemy_buff) {
    items :[3]Player_item_type = {.HEAL, .ATK_DMG, .SPEED}
    return rand.choice(items[:]), rand.choice_enum(Vendor_enemy_buff)
}

level_vendor_update :: proc(vendor: ^Level_vendor, cld: []rl.Rectangle, ui_controller: ^UI_Controller, game_options: ^Game_Options, player_position: rl.Vector2, dt: f32) {
    if vendor.is_disabled do return 
    vendor.body.position.y += LEVEL_VENDOR_FALSE_SPEED * dt
    for i:= 0; i < len(cld); i+= 1 {
        resolve_vertical(&vendor.body, cld[i])
        resolve_horizontal(&vendor.body, cld[i])
    }   
    player_distance := get_distance(vendor.body.position, player_position)
    vendor.is_player_near = player_distance <= vendor.suggest_range

    vendor.can_open = vendor.is_player_near && player_distance <= vendor.open_range

    if vendor.can_open && rl.IsKeyPressed(.E) && ui_controller.ui_scene == .NONE{
        game_options.is_paused = true
        ui_controller.ui_scene = .VENDOR
    }
}

level_vendor_draw:: proc(atlas: rl.Texture2D, body: Body, disabled: bool, is_near: bool, can_open: bool, dt: f32) {
    body_rect := get_body_rect(body)
    sprite_source := get_sprite_source_rect(SPRITE_MAP[LEVEL_VENDOR_SPRITE])

    rl.DrawTexturePro(atlas, sprite_source, body_rect, 0, 0, disabled ? rl.GRAY : rl.WHITE)
    if !disabled {
        if is_near && !can_open {
            unit_expression_draw(atlas, SPRITE_MAP[LEVEL_VENDOR_NEAR_SPRITE], {32, 16},body.position + {16, -8})
        } else if can_open {
            unit_expression_draw(atlas, SPRITE_MAP[LEVEL_VENDOR_OPEN_SPRITE], {32, 16}, body.position + {16, -8})
        }
    }
}

resolve_accept_vendor_deal :: proc(vendor_item: Player_item_type, vendor_enemy_buff: Vendor_enemy_buff, player: ^Player, enemy_buff_stats: ^Enemy_buffes, particle_system: ^Particles_systems) {
    switch vendor_enemy_buff {
        case .HP : {
            enemy_buff_stats.hp += 15
        }
        case .ATTACK: {
            enemy_buff_stats.attack += 15
        }
        case .COOLDOWN: {
            enemy_buff_stats.cooldown = min(enemy_buff_stats.cooldown + 15, ENEMY_MAX_CD_REDUCE)
        }
    }
    player_pocket_slot, empty_slot_error := get_player_pocket_empty_slot(player.pocket_items)
    if empty_slot_error == .NONE {
        player.pocket_items[player_pocket_slot].type = vendor_item
    } else {
        resolve_using_item({type = vendor_item}, player, particle_system)
    }
}