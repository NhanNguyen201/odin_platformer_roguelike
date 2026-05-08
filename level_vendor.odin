package main
import rl "vendor:raylib"
import "core:math/rand"
import "core:slice"
LEVEL_VENDOR_SIZE: rl.Vector2 : {20, 20}
Vendor_enemy_buff :: enum {
    HP,
    ATTACK
}

Level_vendor :: struct {
    active: bool,
    item: Player_item_type,
    enemy_buff: Vendor_enemy_buff,
    body: Body,
    active_range: f32,
    suggest_range: f32
}

refresh_vender :: proc() -> (Player_item_type, Vendor_enemy_buff) {
    items :[3]Player_item_type = {.HEAL, .ATK_DMG, .SPEED}
    return rand.choice(items[:]), rand.choice_enum(Vendor_enemy_buff)
}

level_vendor_update :: proc(vendor_body: ^Body, cld: []rl.Rectangle, ui_controller: ^UI_Controller, player_position: rl.Vector2) {
    for i:= 0; i < len(cld); i+= 1 {
        resolve_vertical(vendor_body, cld[i])
        resolve_horizontal(vendor_body, cld[i])
    }
}