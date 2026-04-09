package main
import rl "vendor:raylib"

Inittal_bullet_countdown :f32 : 1.

STAT_BUFF:: enum {
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
    on_ground: bool,
    is_flip: bool,
    bullet_cd: Bullet_Countdown,
    anim_controller: Animation_controller,
    exp_controller: Experience_controller
}

Body :: struct {
    size: rl.Vector2,
    position: rl.Vector2,
    vel: rl.Vector2,
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
    dmg: f32
}


Player_buffes :: struct {
    hp: f32,
    damage: f32,
    armor: f32,
    mv_spd: f32,
    at_spd: f32
}

Player_stats :: struct {
    health_stats: Heath_stats,
    dmg: f32,
    buffes: Player_buffes
}


Player_direction :: enum {
    LEFT, 
    RIGHT
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


player_update :: proc(player: ^Player, game: ^Game, game_collider_block: []rl.Rectangle, dt: f32) {
    player.body.vel.x = 0

    if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
        player.direction = .LEFT
        player.is_flip = true
        player.body.vel.x = -(PLAYER_MOVE_SPD + player.stats.buffes.mv_spd)
         if player.anim_controller.animation_name != RUN {
            player.anim_controller.animation_name = RUN
            player.anim_controller.current_frame = 0
            player.anim_controller.current_timer = Player_animations[RUN].frame_timer
        }
    } else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
        player.direction = .RIGHT
        player.is_flip = false

        player.body.vel.x = (PLAYER_MOVE_SPD + player.stats.buffes.mv_spd)
        if player.anim_controller.animation_name != RUN {
            player.anim_controller.animation_name = RUN
            player.anim_controller.current_frame = 0

            player.anim_controller.current_timer = Player_animations[RUN].frame_timer

        }
    } else {
        player.body.vel.x = 0
        if player.anim_controller.animation_name != IDLE {
            player.anim_controller.animation_name = IDLE
            player.anim_controller.current_frame = 0
            player.anim_controller.current_timer = Player_animations[IDLE].frame_timer

        }
    }


  
    
    player.body.position.x += player.body.vel.x  * dt

    player.body.position.x = clamp(player.body.position.x , 0, f32(SCREEN_WIDTH) - PLAYER_SIZE.x)
   
    jump_pressed := rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.UP) || rl.IsKeyPressed(.W)

    if jump_pressed && player.on_ground {
        player.body.vel.y = PlAYER_JUMP_VEL
        player.on_ground = false
    }
    
    for block_collider in game_collider_block {
        resolve_horizontal(player, block_collider)
    }


    player.body.vel.y = min(player.body.vel.y + (GRAVITY * dt), MAX_FALL_SPEED)
    
    player.on_ground = false
    player.body.position.y += player.body.vel.y * dt

    for block_collider in game_collider_block {
        resolve_vertical(player, block_collider)
    }

    if player.bullet_cd.current_time > 0 {
        player.bullet_cd.current_time -= dt
    }

    if rl.IsKeyPressed(.K) {
        if player.bullet_cd.current_time < 0.01 {
            player.bullet_cd.current_time = player.bullet_cd.max_time * (1. - (player.stats.buffes.at_spd / 100))
            bullet := Bullet {direction = player.direction, dmg = player.stats.dmg + player.stats.buffes.damage, position = player.body.position}
            append(&game.player_bullets, bullet)
        }


    }


    for &bullet in game.player_bullets {
        direction_vel : rl.Vector2

        switch bullet.direction {
            case .UP: direction_vel = {0, -200}
            case .DOWN: direction_vel = {0, 200}
            case .RIGHT: direction_vel = {200, 0}
            case .LEFT: direction_vel = {-200, 0}
            case : direction_vel = {0, 0}
        }

        bullet.position += direction_vel * dt


    }

}

player_draw :: proc(player: ^Player, game: Game, dt: f32) {
    r := get_body_rect(player.body)

    anim := Player_animations[player.anim_controller.animation_name]

    draw_animation(game.game_sprite_atlas, &player.anim_controller, anim, PLAYER_SPRITE, player.is_flip, r, dt)
    if game.game_options.is_debug {

        frameheight :f32 = 10
        rl.DrawRectangle(i32(player.body.position.x - 20), i32(player.body.position.y - 5), 5, i32(frameheight), rl.WHITE)
        rl.DrawRectangle(i32(player.body.position.x - 20), i32(player.body.position.y - 5), 5, i32(player.anim_controller.current_timer / anim.frame_timer * frameheight), rl.BLUE)
            

        rl.DrawCircleLinesV(player.body.position, 1, rl.BLACK)
    }

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
            game.ui_controller.is_buff_pick = true
            game.game_options.is_paused = true

            player.exp_controller.current -= player.exp_controller.require.val
            player.exp_controller.level += 1
            player.exp_controller.require = EXPERIENCE_PER_LEVEL[player.exp_controller.level]


        }

    }
}