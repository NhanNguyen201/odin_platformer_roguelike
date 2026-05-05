package main
import rl "vendor:raylib"

Player_controll_destination :: enum {
    SHOOT,
    ITEM_1,
    ITEM_2,
    ITEM_3,
    ITEM_4,
    ITEM_5,
    ITEM_6,
}

Player_input_controller :: struct {
    shoot: rl.KeyboardKey,
    item_1 : rl.KeyboardKey,
    item_2 : rl.KeyboardKey,
    item_3 : rl.KeyboardKey,
    item_4 : rl.KeyboardKey,
    item_5 : rl.KeyboardKey,
    item_6 : rl.KeyboardKey,
}

get_default_input_controller :: proc() -> Player_input_controller {
    return {
        shoot = .ONE,
        item_2 = .TWO,
        item_3 = .THREE,
        item_4 = .FOUR,
        item_5 = .FIVE,
        item_6 = .SIX,
    }
} 

