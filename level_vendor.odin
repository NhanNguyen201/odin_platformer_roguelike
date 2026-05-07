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