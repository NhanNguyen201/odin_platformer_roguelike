package main

import rl "vendor:raylib"
import "core:fmt"
import "core:encoding/json"
import "core:os"
import "core:strings"
import "core:math/rand"
Enemy_spawner_status :: enum {
    EXIST,
    COUNT_DOWN
}
Enemy_directions :: enum {
    LEFT, 
    RIGHT
}

BACKGROUND_LAYER: int : 0
VISIBLE_LAYER_LOW: int : 1
VISIBLE_LAYER_MIDLE: int: 2
VISIBLE_LAYER_HIGH:int: 3
FORGROUND_LAYER:int: 4
COLLIDER_LAYER:int: 5
EXP_LAYER:int: 6
KEY_CONTAINER_LAYER:int: 7
ENEMY_SPAWNERS_LAYER:int: 8
GATE_LAYER:int: 9

KEY_POT_SIZE :: rl.Vector2 {10,10}

Level:: struct {
    level_size : rl.Vector2,
    map_image : string,
    map_data: string
}

Level_data :: struct {
    image: string,
    collected_keys: int,
    texture: rl.Texture2D,
    map_size: rl.Vector2,
    gate_position: rl.Vector2,
    colliders: [dynamic] rl.Rectangle,
    keys: [dynamic] Key_pot,
    enemy_spawners: [dynamic] Enemy_spawner_pot,
    exp_buffs: [dynamic] Exp_buff
}

Exp_buff :: struct {
    position: rl.Vector2,
    collected: bool
}

Key_pot :: struct {
    position: rl.Vector2,
    collected: bool,
}


Enemy_spawner_pot :: struct {
    hp_stats: Heath_stats,
    position: rl.Vector2,
    destination: rl.Vector2,
    re_contruct: Enemy_reconstruct,
    re_spawn: Enemy_respawn,
    enemy_id: f32
}

Enemy_reconstruct :: struct {
    max_time: f32,
    time: f32
}

Enemy_respawn:: struct {
    max_time: f32,
    time: f32,
    status: Enemy_spawner_status
}

Heath_stats :: struct {
    max_hp: f32,
    current_hp: f32
}

Enemy :: struct {
    id: f32,
    hp_stats: Heath_stats,
    dmg: f32,
    direction: Enemy_directions
}

Designed_Level : []Level = {
    Level {
        level_size = rl.Vector2 {800, 560},
        map_image = "assets/map_images/map_1.png",
        map_data = "assets/map_tiles/map_1.json"
    },
}



get_level_data::proc (lvl: int) -> Level {
    level_data : Level
    switch lvl {
        case 0: level_data =  Designed_Level[0]
        case 1: level_data = Designed_Level[0]
    }
    return level_data
}

load_level :: proc(game: ^Game, lvl: int)  {
    level := get_level_data(lvl)

    game.level_data.map_size = level.level_size
    game.level_data.image = level.map_image
    game.level_data.texture = rl.LoadTexture(strings.clone_to_cstring(level.map_image, context.temp_allocator))

    data, ok := os.read_entire_file_from_filename(level.map_data)

    if !ok {
        fmt.eprintln("Failed to parse the json file.")

        return
    }
    defer delete(data)

    json_data, err := json.parse(data)

    if err != .None {
        fmt.eprintln("Failed to parse the json file.")
        fmt.eprintln("Error:", err)
        return
    }
    defer json.destroy_value(json_data)
    

    object_data := json_data.(json.Object)
    layer_data := object_data["layers"].(json.Array)

    // Collider layer handling
    colliders_wrapper := layer_data[COLLIDER_LAYER]
    colliders_data := colliders_wrapper.(json.Object)["objects"].(json.Array)


    for cld  in colliders_data {
        parsed := cld.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        w := f32(parsed["width"].(json.Float))
        h := f32(parsed["height"].(json.Float))
        append(&game.level_data.colliders, rl.Rectangle{x = x, y = y, width = w, height = h})
    }

    // Collider keys handling
    keys_container_wrapper := layer_data[KEY_CONTAINER_LAYER]
    keys_container := keys_container_wrapper.(json.Object)["objects"].(json.Array)

    for key in keys_container {
        parsed := key.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        // key_pos := rl.Vector2 {x_pos, y_pos} 
        append(&game.level_data.keys,  Key_pot{ position = {x, y}})
    }

    enemy_spawners_wrapper := layer_data[ENEMY_SPAWNERS_LAYER]
    enemy_spawners := enemy_spawners_wrapper.(json.Object)["objects"].(json.Array)

    for enemy_spw in enemy_spawners {
        parsed := enemy_spw.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        // key_pos := rl.Vector2 {x_pos, y_pos}
        enemy_spawner_pot := Enemy_spawner_pot {
            position = {x, y}, 
            hp_stats = {
                max_hp = 150, 
                current_hp = 150
            },
            re_spawn = {
                max_time = 10.,
                status = .EXIST,
                time = 3. 
            },
            re_contruct ={
                max_time = 5.,
                time = 5.
            },
            enemy_id = rand.float32()
        } 
        append(&game.level_data.enemy_spawners,  enemy_spawner_pot)
    }

    // Exprience buff

    exps_container_wrapper := layer_data[EXP_LAYER]
    exps_container := exps_container_wrapper.(json.Object)["objects"].(json.Array)

    for exp_buff in exps_container {
        parsed := exp_buff.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        // key_pos := rl.Vector2 {x_pos, y_pos} 
        append(&game.level_data.exp_buffs,  Exp_buff{ position = {x, y}})
    }
    // --> GATE <---
    gate_container_wrapper := layer_data[EXP_LAYER]
    gate_container := gate_container_wrapper.(json.Object)["objects"].(json.Array)
    gate_pos_parsed := gate_container[0].(json.Object)


    gate_x := f32(gate_pos_parsed["x"].(json.Float))
    gate_y := f32(gate_pos_parsed["y"].(json.Float))
    game.level_data.gate_position = {gate_x, gate_y}
    
}

