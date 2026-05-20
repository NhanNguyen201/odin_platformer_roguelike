package main
import "core:reflect"
import rl "vendor:raylib"

Player_action_name :: enum {
    MOVE_LEFT,
    MOVE_RIGHT,
    JUMP,
    MOVE_DOWN,
    SHOOT,
    ITEM_1,
    ITEM_2,
    ITEM_3,
    ITEM_4,
    ITEM_5,
    ITEM_6,
}

Key_binding_error_type :: enum {
    NONE,
    ALREADY_USED
}

Key_binding_error :: struct {
    timer: Timer,
    error_type: Key_binding_error_type
}

Action_key :: struct {
    action_name: Player_action_name,
    key: rl.KeyboardKey
}

Player_key_binding_controller :: struct {
    is_binding : bool,
    is_picking: bool,
    current_action_key : ^Action_key,
    binding_error: Key_binding_error 
}

Player_input_controler :: struct {
    jump: Action_key,
    move_left: Action_key,
    move_right: Action_key,
    move_down: Action_key,
    shoot: Action_key,
    item_1 : Action_key,
    item_2 : Action_key,
    item_3 : Action_key,
    item_4 : Action_key,
    item_5 : Action_key,
    item_6 : Action_key,
}

get_default_input_controler :: proc() -> Player_input_controler {
    return {
        jump = {action_name = .JUMP, key = .W},
        move_down = {action_name = .MOVE_DOWN, key = .S},
        move_left = {action_name = .MOVE_LEFT, key = .A},
        move_right = {action_name = .MOVE_RIGHT, key = .D},
        shoot = {action_name = .SHOOT, key = .K},
        item_1 = {action_name = .ITEM_1, key = .ONE},
        item_2 = {action_name = .ITEM_2, key = .TWO},
        item_3 = {action_name = .ITEM_3, key = .THREE},
        item_4 = {action_name = .ITEM_4, key = .FOUR},
        item_5 = {action_name = .ITEM_5, key = .FIVE},
        item_6 = {action_name = .ITEM_6, key = .SIX},
    }
} 


get_keycode_name:: proc(key: rl.KeyboardKey) -> string {
    return reflect.enum_string(key)
}

get_item_keycode_to_array :: proc (input_ctrl: ^Player_input_controler) -> [PLAYER_ITEM_SLOT_NUMB] ^Action_key {
    return {&input_ctrl.item_1, &input_ctrl.item_2, &input_ctrl.item_3, &input_ctrl.item_4, &input_ctrl.item_5, &input_ctrl.item_6}
}

get_action_key_ref_from_name:: proc(controller: ^Player_input_controler, action_name: Player_action_name) -> ^Action_key {
    key : ^Action_key

    switch(action_name) {
        case .JUMP : key = &controller.jump
        case .MOVE_DOWN : key = &controller.move_down
        case .MOVE_LEFT : key = &controller.move_left
        case .MOVE_RIGHT : key = &controller.move_right
        case .SHOOT : key = &controller.shoot
        case .ITEM_1 : key = &controller.item_1
        case .ITEM_2 : key = &controller.item_2
        case .ITEM_3 : key = &controller.item_3
        case .ITEM_4 : key = &controller.item_4
        case .ITEM_5 : key = &controller.item_5
        case .ITEM_6 : key = &controller.item_6
    }
    return key
}

get_can_bind_key :: proc(controller: Player_input_controler, key : rl.KeyboardKey) -> Key_binding_error_type {
    // type_id := reflect.type(Player_input_controler)
    field_names := reflect.struct_field_names(Player_input_controler)
    for i in 0..<len(field_names) {
        name := field_names[i]
        value := reflect.struct_field_value_by_name(controller, name)
        parsed := value.(Action_key)
        if parsed.key == key {
            return .ALREADY_USED
        }
    }
    // binded_keys := reflect.str
    return .NONE
}