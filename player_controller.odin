package main
import "core:reflect"
import rl "vendor:raylib"
Player_control_destination :: enum {
    SHOOT,
    ITEM_1,
    ITEM_2,
    ITEM_3,
    ITEM_4,
    ITEM_5,
    ITEM_6,
}

Player_input_controler :: struct {
    shoot: rl.KeyboardKey,
    item_1 : rl.KeyboardKey,
    item_2 : rl.KeyboardKey,
    item_3 : rl.KeyboardKey,
    item_4 : rl.KeyboardKey,
    item_5 : rl.KeyboardKey,
    item_6 : rl.KeyboardKey,
}

get_default_input_controler :: proc() -> Player_input_controler {
    return {
        shoot = .K,
        item_1 = .ONE,
        item_2 = .TWO,
        item_3 = .THREE,
        item_4 = .FOUR,
        item_5 = .FIVE,
        item_6 = .SIX,
    }
} 


get_input_from_controller :: proc(control_dest: Player_control_destination, p_i_controler : Player_input_controler) -> rl.KeyboardKey {
    key : rl.KeyboardKey

    switch(control_dest) {
        case .SHOOT : key = p_i_controler.shoot
        case .ITEM_1 : key = p_i_controler.item_1
        case .ITEM_2 : key = p_i_controler.item_2
        case .ITEM_3 : key = p_i_controler.item_3
        case .ITEM_4 : key = p_i_controler.item_4
        case .ITEM_5 : key = p_i_controler.item_5
        case .ITEM_6 : key = p_i_controler.item_6
    }
    return key
}

get_keycode_name:: proc(key: rl.KeyboardKey) -> string {
    return reflect.enum_string(key)
}

get_item_keycode_to_array :: proc (input_ctrl: Player_input_controler) -> [PLAYER_ITEM_SLOT_NUMB]rl.KeyboardKey {
    return {input_ctrl.item_1, input_ctrl.item_2, input_ctrl.item_3, input_ctrl.item_4, input_ctrl.item_5, input_ctrl.item_6}
}