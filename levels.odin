package main

import rl "vendor:raylib"
import "core:fmt"
import "core:encoding/json"
import "core:os"
import "core:strings"
import "core:math"
import "core:math/rand"


BACKGROUND_LAYER: int : 0
VISIBLE_LAYER_LOW: int : 1
VISIBLE_LAYER_MIDLE: int: 2
VISIBLE_LAYER_HIGH:int: 3
FORGROUND_LAYER:int: 4
COLLIDER_LAYER:int: 5
EXP_LAYER:int: 6
KEY_CONTAINER_LAYER:int: 7
ENEMY_MELEE_SPAWNERS_LAYER:int: 8
ENEMY_RANGER_SPAWNERS_LAYER:int: 9
ENEMY_SNIPER_SPAWNERS_LAYER:int: 10
GATE_LAYER: int: 11
PLAYER_SPAWN_POS_LAYER : int : 12
KEY_POT_SIZE : rl.Vector2: {10,10}

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
    is_complete: bool,
    colliders: [dynamic] rl.Rectangle,
    keys: [dynamic] Key_pot,
    exp_buffs: [dynamic] Exp_buff
}

Exp_buff :: struct {
    position: rl.Vector2,
    collected: bool
}

Key_pot :: struct {
    disabled: bool,
    position: rl.Vector2,
    collected: bool,
}


Enemy_spawner_pot :: struct {
    hp_stats: Health_stats,
    position: rl.Vector2,
    destination: rl.Vector2,
    re_contruct: Timer,
    re_spawn: Timer,
    state: Enemy_spawner_state,
    enemy_id: f32,
    enemy_type: Enemy_types,
    anim_controller: Animation_controller

}


Health_stats :: struct {
    max_hp: f32,
    current_hp: f32
}



Designed_Level : []Level = {
    Level {
        level_size = rl.Vector2 {800, 560},
        map_image = "assets/map_images/map_1.png",
        map_data = "assets/map_tiles/map_1.json"
    },
    Level {
        level_size = rl.Vector2 {960, 720},
        map_image = "assets/map_images/map_2.png",
        map_data = "assets/map_tiles/map_2.json"
    },
    Level {
        level_size = rl.Vector2 {960, 960},
        map_image = "assets/map_images/map_3.png",
        map_data = "assets/map_tiles/map_3.json"
    },
     Level {
        level_size = rl.Vector2 {720, 720},
        map_image = "assets/map_images/map_4.png",
        map_data = "assets/map_tiles/map_4.json"
    },
}


get_level_data::proc (lvl: int) -> Level {
    level_data : Level
    switch lvl {
        case 0: level_data =  Designed_Level[0]
        case 1: level_data = Designed_Level[1]
        case 2: level_data = Designed_Level[2]
        case 3: level_data = Designed_Level[3]
    }
    return level_data
}

load_level :: proc(game: ^Game, lvl: int)  {
    clear_game_mem(game)
    @static enemy_spawner_hp: f32 = 150
    @static enemy_respawn_time: f32 = 3.5
    @static enemy_recontruct_time: f32 = 5
    @static level_vendor_suggest_range: f32 = 60
    @static level_vendor_open_range: f32 = 20
    is_boss_level := get_is_boss_lvl(lvl)

    level := get_level_data(lvl)

    game.current_level = lvl
    game.level_data.map_size = level.level_size
    game.level_data.image = level.map_image
    game.level_data.texture = rl.LoadTexture(strings.clone_to_cstring(level.map_image, context.temp_allocator))
    game.level_data.is_complete = false
    game.level_data.collected_keys = 0
    game.player.body.vel = {0, 0}    
    refresh_shop(&game.shop_manager)

    game.boss_manager.is_boss_level = is_boss_level
    
    if is_boss_level {
        game.ui_controller.ui_scene = .BOSS_ENTRANCE
        game.ui_controller.transition_time = BOSS_SCENE_TRANSITION_TIME
        game.game_options.is_paused = true
        game.boss_manager.map_size = game.level_data.map_size
        spawn_boss(&game.boss_manager)
    } else {
        game.ui_controller.ui_scene = .START_LEVEL
        game.ui_controller.transition_time = 1.

        game.game_options.is_paused = true
    }

    data, ok := os.read_entire_file_from_filename(level.map_data)

    // clear(&game.)
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
        append(&game.level_data.keys,  Key_pot{ position = {x, y}, disabled = is_boss_level})
    }

    // Enemy MELEE spaawner
    enemy_melee_spawners_wrapper := layer_data[ENEMY_MELEE_SPAWNERS_LAYER]
    enemy_melee_spawners := enemy_melee_spawners_wrapper.(json.Object)["objects"].(json.Array)

    for enemy_melee_spw in enemy_melee_spawners {
        parsed := enemy_melee_spw.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        // key_pos := rl.Vector2 {x_pos, y_pos}
        enemy_spawner_pot := Enemy_spawner_pot {
            enemy_type = .MELEE,
            position = {x, y}, 
            hp_stats = {
                max_hp = enemy_spawner_hp, 
                current_hp = enemy_spawner_hp
            },
            state = .EXIST,
            re_spawn = {
                max_time = enemy_respawn_time,
                current = 2. 
            },
            re_contruct ={
                max_time = enemy_recontruct_time,
                current = enemy_recontruct_time
            },
            anim_controller =  {
                animation_name = IDLE_ANI,
                default_ani = IDLE_ANI
            },
            enemy_id = rand.float32()
        } 
        append(&game.enemy_side.enemy_spawners,  enemy_spawner_pot)
    }

    // Enemy RANGER spaawner
    enemy_ranger_spawners_wrapper := layer_data[ENEMY_RANGER_SPAWNERS_LAYER]
    enemy_ranger_spawners := enemy_ranger_spawners_wrapper.(json.Object)["objects"].(json.Array)

    for enemy_ranger_spw in enemy_ranger_spawners {
        parsed := enemy_ranger_spw.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        // key_pos := rl.Vector2 {x_pos, y_pos}
        enemy_spawner_pot := Enemy_spawner_pot {
            enemy_type = .RANGER,
            position = {x, y}, 
            state = .EXIST,
            hp_stats = {
                max_hp = enemy_spawner_hp, 
                current_hp = enemy_spawner_hp
            },
            re_spawn = {
                max_time = enemy_respawn_time,
                current = 2. 
            },
            re_contruct ={
                max_time = enemy_recontruct_time,
                current = enemy_recontruct_time
            },
            anim_controller =  {
                animation_name = IDLE_ANI,
                default_ani = IDLE_ANI

            },
            enemy_id = rand.float32()
        } 
        append(&game.enemy_side.enemy_spawners,  enemy_spawner_pot)
    }
    // Enemy SNIPER spaawner
    enemy_sniper_spawners_wrapper := layer_data[ENEMY_SNIPER_SPAWNERS_LAYER]
    enemy_sniper_spawners := enemy_sniper_spawners_wrapper.(json.Object)["objects"].(json.Array)

    for enemy_sniper_spw in enemy_sniper_spawners {
        parsed := enemy_sniper_spw.(json.Object)
        x := f32(parsed["x"].(json.Float))
        y := f32(parsed["y"].(json.Float))
        
        // key_pos := rl.Vector2 {x_pos, y_pos}
        enemy_spawner_pot := Enemy_spawner_pot {
            enemy_type = .SNIPER,
            position = {x, y}, 
            hp_stats = {
                max_hp = enemy_spawner_hp, 
                current_hp = enemy_spawner_hp
            },
            state = .EXIST,
            re_spawn = {
                max_time = enemy_respawn_time,
                current = 2. 
            },
            re_contruct ={
                max_time = enemy_recontruct_time,
                current = enemy_recontruct_time
            },
            anim_controller =  {
                animation_name = IDLE_ANI,
                default_ani = IDLE_ANI

            },
            enemy_id = rand.float32()
        } 
        append(&game.enemy_side.enemy_spawners,  enemy_spawner_pot)
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
    gate_container_wrapper := layer_data[GATE_LAYER]
    gate_container := gate_container_wrapper.(json.Object)["objects"].(json.Array)
    gate_pos_parsed := gate_container[0].(json.Object)


    gate_x := f32(gate_pos_parsed["x"].(json.Float))
    gate_y := f32(gate_pos_parsed["y"].(json.Float))
    game.level_data.gate_position = {gate_x, gate_y}
    

    player_spawn_pos_container_wrapper := layer_data[PLAYER_SPAWN_POS_LAYER]
    spawn_pos := player_spawn_pos_container_wrapper.(json.Object)["objects"].(json.Array)
    spawn_pos_parsed := spawn_pos[0].(json.Object)


    spawn_pos_x := f32(spawn_pos_parsed["x"].(json.Float))
    spawn_pos_y := f32(spawn_pos_parsed["y"].(json.Float))
    game.player.spawn_pos = {spawn_pos_x, spawn_pos_y}
    game.player.body.position = game.player.spawn_pos

    new_level_vendor_item, new_level_vendor_e_buff := refresh_vender()
    game.level_vendor.is_disabled = false
    game.level_vendor.body.position = {level.level_size.x - 50, 100}
    game.level_vendor.body.size = LEVEL_VENDOR_SIZE
    game.level_vendor.item = new_level_vendor_item
    game.level_vendor.enemy_buff = new_level_vendor_e_buff
    game.level_vendor.suggest_range = level_vendor_suggest_range
    game.level_vendor.open_range = level_vendor_open_range
}

