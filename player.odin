#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:math/rand"

Inittal_bullet_countdown :f32 : 1.
PLAYER_MAX_HORIZONTAL_SPD : f32 : 130
Player_temp_buff_TICK_TIME : f32 : 1.
PLAYER_MAX_ACC : f32 : 7.5
STOMPED_MAX_FALL_SPEED: f32 : 600
PLAYER_ITEM_SLOT_NUMB: int : 6

PLAYER_ITEM_HEAL_AMOUNT: f32 : 30
PLAYER_ITEM_ATK_AMOUNT: f32: 30
PLAYER_ITEM_SPEED_AMOUNT: f32 : 25
SHOP_ITEM_SLOT_NUM : int : 3
SHOP_ITEM_COST: f32 : 75

Shop_item_purchase_error :: enum {
    NONE,
    INVALID_ACTION,
    NOT_ENOUGH_COINS,
    POCKET_FULL,
    SOLD
}

Shop_item :: struct {
    price : f32,
    item_type : Player_item_type,
    item_status : Shop_item_status 
} 

Shop_item_status :: enum {
    SOLD,
    AVAILABLE
}

Player_item:: struct {
    type: Player_item_type,
}

Player_item_type :: enum {
    NONE,
    HEAL,
    ATK_DMG,
    SPEED
}

Shop_manager :: struct {
    items: [SHOP_ITEM_SLOT_NUM] Shop_item
}

Stat_buff:: enum {
    HP,
    AD,
    ATS, 
    MVSPD,
    AR
}

Bullet_Countdown :: struct {
    max_time: f32,
    current_time: f32
}


Player :: struct {
    body: Body,
    direction: BULLET_DIRECTION,
    stats: Player_stats,
    spawn_pos: rl.Vector2,
    money_coins: Player_coins,
    bullet_cd: Bullet_Countdown,
    anim_controller: Animation_controller,
    exp_controller: Experience_controller,
    pocket_items: [PLAYER_ITEM_SLOT_NUMB] Player_item,
    input_controler : Player_input_controler
}

Body :: struct {
    size: rl.Vector2,
    position: rl.Vector2,
    vel: rl.Vector2,
    direction : Player_direction,
    acc: rl.Vector2,
    is_on_ground: bool,
    is_flip: bool,

}

Experience_controller:: struct {
    require: Exp_require,
    current: f32,
    level: int
}


Exp_require:: struct {
    val : f32
}


Bullet :: struct {
    position: rl.Vector2,
    direction: BULLET_DIRECTION,
    dmg: f32,
    is_exploded: bool
}


Player_buffes :: struct {
    hp: f32,
    damage: f32,
    armor: f32,
    mv_spd: f32,
    at_spd: f32
}

Player_stats :: struct {
    health_stats: Health_stats,
    dmg: f32,
    buffes: Player_buffes,
    temp_buffes: [dynamic] Player_temp_buff
}

Player_coins :: struct {
    val: f32
}

Player_direction :: enum {
    LEFT, 
    RIGHT
}

PLAYER_ACTION_SETTING :: enum {
    SHOOT,
    JUMP
}

Player_temp_buff :: struct {
    temp_buff_type: Temp_buff_types,
    tick_time: f32,
    time: Timer,
    value: f32
}

Temp_buff_types :: enum {
    BURNING,
    ATTACK,
    SPEED
    // FREEZED
}

MAX_LEVEL: int :10
EXPERIENCE_BUFF_AMOUNT:f32 : 20
EXPERIENCE_BUFF_SIZE: rl.Vector2: {12, 12}

EXPERIENCE_PER_LEVEL: [MAX_LEVEL]Exp_require = {
    {val = 20},
    {val = 30},
    {val = 45},
    {val = 70},
    {val = 90},
    {val = 120},
    {val = 160},
    {val = 210},
    {val = 250},
    {val = 300},

}

KEYBOARD_KEYS := map[string] rl.KeyboardKey{
    "k" = .K ,
}

get_key_to_keycode :: proc (key: string) -> rl.KeyboardKey {
    return KEYBOARD_KEYS[key]
} 

can_key_to_keycode :: proc(key: string) -> bool {
    return type_of(KEYBOARD_KEYS[key]) == rl.KeyboardKey  
}

refresh_shop:: proc(shop: ^Shop_manager) {
    new_item_for_shop : [3]Player_item_type = {.HEAL, .ATK_DMG, .SPEED}
    for i := 0; i < SHOP_ITEM_SLOT_NUM; i += 1 {
        new_item: Player_item_type= rand.choice(new_item_for_shop[:])
        shop.items[i] = {
            item_type = new_item,
            item_status = .AVAILABLE,
            price = SHOP_ITEM_COST
        }
    }
}

resolve_buy_item :: proc(shop: ^Shop_manager, item_idx: int, player_items: ^[PLAYER_ITEM_SLOT_NUMB]Player_item, player_coins: ^Player_coins) -> (bool, Shop_item_purchase_error) {
    found := false
    found_pockket_idx :int = 0
    
    
    if item_idx > SHOP_ITEM_SLOT_NUM do return false, .INVALID_ACTION

    shop_item := shop.items[item_idx]
    if shop_item.item_status == .SOLD do return false, .SOLD

    empty_slot, full_slot_error := get_player_pocket_empty_slot(player_items^)
    
    if full_slot_error != .NONE {
        return false, full_slot_error
    } else {
        found_pockket_idx = empty_slot
    }
    
    if player_coins.val < shop_item.price {
        return false, .NOT_ENOUGH_COINS
    } else {
        shop.items[item_idx].item_status = .SOLD
        player_items[found_pockket_idx].type = shop_item.item_type
        player_coins.val -= shop_item.price
        return true, .NONE
    }
}

get_player_pocket_empty_slot :: proc(player_items: [PLAYER_ITEM_SLOT_NUMB]Player_item) -> (int, Shop_item_purchase_error) {
    for i := 0; i < PLAYER_ITEM_SLOT_NUMB; i += 1 {
        if player_items[i].type == .NONE {
            return i, .NONE
        }
    }

    return 0, .POCKET_FULL
}

player_update :: proc(player: ^Player, game: ^Game, game_collider_block: []rl.Rectangle, dt: f32) {
    // player.body.vel.x = 0

    if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
        player.direction = .LEFT
        player.body.is_flip = true
        // player.body.vel.x = -(PLAYER_MOVE_SPD * (1. + player.stats.buffes.mv_spd / 100))
        player.body.acc.x = -PLAYER_MAX_ACC
         if player.anim_controller.animation_name != RUN_ANI {
            player.anim_controller.animation_name = RUN_ANI
            player.anim_controller.current_frame = 0
            player.anim_controller.current_timer = Player_animations[RUN_ANI].frame_timer
        }
    } else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
        player.direction = .RIGHT
        player.body.is_flip = false

        // player.body.vel.x = (PLAYER_MOVE_SPD * (1. + player.stats.buffes.mv_spd / 100))
        player.body.acc.x = PLAYER_MAX_ACC

        if player.anim_controller.animation_name != RUN_ANI {
            player.anim_controller.animation_name = RUN_ANI
            player.anim_controller.current_frame = 0

            player.anim_controller.current_timer = Player_animations[RUN_ANI].frame_timer

        }
    } else {
        player.body.acc.x = 0

        if player.body.is_on_ground {
            player.body.vel.x  *= 0.8
        }
        if player.anim_controller.animation_name != IDLE_ANI {
            player.anim_controller.animation_name = IDLE_ANI
            player.anim_controller.current_frame = 0
            player.anim_controller.current_timer = Player_animations[IDLE_ANI].frame_timer

        }
    }

    player.body.vel.x += player.body.acc.x

    _, amount_speed_boost := get_player_is_boosted_by(player.stats.temp_buffes[:], .SPEED)
    bounded_speed := (100 + amount_speed_boost + player.stats.buffes.mv_spd) / 100
    player.body.vel.x = clamp(player.body.vel.x, -PLAYER_MAX_HORIZONTAL_SPD * bounded_speed, PLAYER_MAX_HORIZONTAL_SPD * bounded_speed)
    
    player.body.position.x += player.body.vel.x  * dt

    player.body.position.x = clamp(player.body.position.x , 0, f32(SCREEN_WIDTH) - PLAYER_SIZE.x)
   
    jump_pressed := rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W)

    if jump_pressed && player.body.is_on_ground {
        player.body.vel.y = PlAYER_JUMP_VEL
        player.body.is_on_ground = false
    }
    
    stomp_pressed := rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)

    if stomp_pressed && !player.body.is_on_ground {
        player.body.acc.y = 50
    } else {
        player.body.acc.y = 0
    }

    for block_collider in game_collider_block {
        resolve_horizontal(&player.body, block_collider)
    }

    player.body.vel.y += player.body.acc.y
    player.body.vel.y = min(player.body.vel.y + (GRAVITY * dt), stomp_pressed ? STOMPED_MAX_FALL_SPEED : MAX_FALL_SPEED )
    
    player.body.is_on_ground = false
    player.body.position.y += player.body.vel.y * dt

    for block_collider in game_collider_block {
        _, _, is_stomped_collided := resolve_vertical(&player.body, block_collider, player.body.acc.y > 0)
        if is_stomped_collided  {
            add_particle(&game.particle_system, {
                sprite_count = 4,
                timer = {max_time = 0.5, current = 0.5},
                sprite_source = get_sprite_source_rect(SPRITE_MAP[UI_EFFECT_PLAYER_STOMP_SPRITE]),
                size = {24, 12},
                is_blur = true,
                is_scaled = true,
                position = player.body.position + {0,3} 
            })
        }
    }

    if player.bullet_cd.current_time > 0 {
        player.bullet_cd.current_time -= dt
    }

    if rl.IsKeyPressed(get_input_from_controller(.SHOOT, player.input_controler)) {
        if player.bullet_cd.current_time < 0.01 {
            player.bullet_cd.current_time = player.bullet_cd.max_time * (1. - (player.stats.buffes.at_spd / 100))
            _, dmg_buff := get_player_is_boosted_by(player.stats.temp_buffes[:], .ATTACK) 
            bullet := Bullet {direction = player.direction, dmg = player.stats.dmg + player.stats.buffes.damage + dmg_buff, position = player.body.position}
            append(&game.player_bullets, bullet)
        }


    }

    resolve_player_and_bullet(player.body, player.stats.buffes, &player.stats.health_stats, &game.enemy_side.enemy_bullets)
    if player.stats.health_stats.current_hp > 0 && game.ui_controller.ui_scene != .GAME_OVER{
        resolve_player_temp_buff_update(player, dt)
    }

    if player.stats.health_stats.current_hp > 0 && game.ui_controller.ui_scene == .NONE {
        resolve_using_item_from_keyboard(player.input_controler, &player.pocket_items, player)
    }
}

player_draw :: proc(atlas: rl.Texture2D, player: ^Player, dt: f32) {
    body_rect := get_body_rect(player.body)

    anim := Player_animations[player.anim_controller.animation_name]

    draw_animation(atlas, &player.anim_controller, anim, PLAYER_SPRITE, player.body.is_flip, body_rect, dt)
   

}

exp_buff_collect:: proc(player: ^Player, game: ^Game) {
    player_rect := get_body_rect(player.body)
    for &buff in game.level_data.exp_buffs {
        if buff.collected do continue

        buff_rect := rl.Rectangle {x = buff.position.x - EXPERIENCE_BUFF_SIZE.x / 2, y = buff.position.y - EXPERIENCE_BUFF_SIZE.y / 2, width = EXPERIENCE_BUFF_SIZE.x, height = EXPERIENCE_BUFF_SIZE.y}
        if !rl.CheckCollisionRecs(player_rect, buff_rect) do continue


        buff.collected = true

        player.exp_controller.current += EXPERIENCE_BUFF_AMOUNT
        
        if player.exp_controller.current >= player.exp_controller.require.val {
            game.game_options.is_paused = true
            game.ui_controller.ui_scene = .BUFFES_PICK

            player.exp_controller.current -= player.exp_controller.require.val
            player.exp_controller.level += 1
            player.exp_controller.require = EXPERIENCE_PER_LEVEL[player.exp_controller.level]


        }

    }
}

player_apply_temp_buff :: proc(temp_buff: Player_temp_buff, player: ^Player) {
    for &current_temp_buff in player.stats.temp_buffes {
        if current_temp_buff.temp_buff_type == temp_buff.temp_buff_type {
            current_temp_buff.time = temp_buff.time
            current_temp_buff.value = max(current_temp_buff.value, temp_buff.value)
            
            return
        }
    }
    if temp_buff.temp_buff_type == .BURNING {
       
        append(&player.stats.temp_buffes, Player_temp_buff {temp_buff_type = .BURNING, value = temp_buff.value, time = temp_buff.time, tick_time = Player_temp_buff_TICK_TIME})
    } else if temp_buff.temp_buff_type == .ATTACK {
        append(&player.stats.temp_buffes, Player_temp_buff {temp_buff_type = .ATTACK, value = temp_buff.value, time = temp_buff.time})

    } else if temp_buff.temp_buff_type == .SPEED {
        append(&player.stats.temp_buffes, Player_temp_buff {temp_buff_type = .SPEED, value = temp_buff.value, time = temp_buff.time})

    }
}

resolve_player_temp_buff_update:: proc(player: ^Player, dt: f32) {
    for i := len(player.stats.temp_buffes) - 1; i >= 0; i -= 1 {
        temp_buff := &player.stats.temp_buffes[i]

        if temp_buff.time.current <= 0 {
            unordered_remove(&player.stats.temp_buffes, i)
            continue
        } else {
            temp_buff.time.current -= dt

            if temp_buff.temp_buff_type == .BURNING {
                temp_buff.tick_time -= dt 
                if temp_buff.tick_time < 0  && temp_buff.time.current > 0 {
                    player_take_dmg(&player.stats.health_stats, player.stats.buffes, temp_buff.value)
                    temp_buff.tick_time = Player_temp_buff_TICK_TIME
                }
            } 
        }
    }
}

resolve_using_item_from_keyboard :: proc(input_controler: Player_input_controler, pocket_items: ^[PLAYER_ITEM_SLOT_NUMB] Player_item, player: ^Player) {

    keycodes := get_item_keycode_to_array(input_controler)

    for i:= 0; i < PLAYER_ITEM_SLOT_NUMB; i += 1 {
        resolve_using_item_by_key(keycodes[i], &pocket_items[i], player)
    }
}

resolve_using_item_by_key :: proc(key: rl.KeyboardKey, item: ^Player_item, player: ^Player) {
    if rl.IsKeyPressed(key) {
        if item.type != .NONE {
            resolve_using_item(item^, player)
            item.type = .NONE
        }
    }
}

resolve_using_item :: proc(item: Player_item, player: ^Player) {
    if item.type == .ATK_DMG {
        player_apply_temp_buff({temp_buff_type = .ATTACK, time = {max_time = 30, current = 30}, value = PLAYER_ITEM_ATK_AMOUNT }, player)
    }  else if item.type == .SPEED {
        player_apply_temp_buff({temp_buff_type = .SPEED, time = {max_time = 30, current = 30}, value = PLAYER_ITEM_SPEED_AMOUNT }, player)
    } else if item.type == .HEAL {
        player.stats.health_stats.current_hp = min(player.stats.health_stats.max_hp, player.stats.health_stats.current_hp  + player.stats.health_stats.max_hp * PLAYER_ITEM_HEAL_AMOUNT / 100)
    }
}

player_take_dmg :: proc(health: ^Health_stats, player_buff: Player_buffes,dmg: f32) {
    reduced_dmg := dmg * (1 - (player_buff.armor / 100))

    if health.current_hp > reduced_dmg {
        health.current_hp -= reduced_dmg
    } else {
        health.current_hp = 0
    }
}

get_player :: proc(game: Game) -> Player {
    return game.player
}

get_player_is_boosted_by :: proc(temp_buffs: []Player_temp_buff, boosted_type : Temp_buff_types) -> (bool, f32) {
    for i:= 0; i< len(temp_buffs); i+= 1 {
        if temp_buffs[i].temp_buff_type == boosted_type do return true, temp_buffs[i].value
    }

    return false, 0
}