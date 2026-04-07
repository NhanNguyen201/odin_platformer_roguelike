#+feature dynamic-literals

package main
import rl "vendor:raylib"

IDLE :: "Idle"
RUN :: "Run"

Animation_controller :: struct {
    animation_name : string,

    current_frame: int,
    current_timer: f32,
}




Animation :: struct {
    name : string,
    count: int,
    frame_start: int,
    frame_end : int,
    frame_timer : f32,
}


Player_animations := map[string] Animation {
    IDLE = {name = IDLE, frame_start = 0, frame_end = 1, frame_timer = .5, count = 2 },
    RUN = {name = RUN, frame_start = 2, frame_end = 3, frame_timer = .5, count = 2 },
}

Minion_animations := map[string] Animation {
    IDLE = {name = IDLE, frame_start = 0, frame_end = 1, frame_timer = 0.5, count = 2 },
    RUN = {name= RUN, frame_start = 2, frame_end = 3, frame_timer = .5, count = 2 },
}

draw_animation :: proc (atlas: rl.Texture2D, anim_controller : ^Animation_controller, anim: Animation, sprite_name: string, is_flip: bool, dest: rl.Rectangle ,dt: f32) {
    anim_controller.current_timer -= dt

    if anim_controller.current_timer <= 0 {
        anim_controller.current_frame += 1
        anim_controller.current_timer = anim.frame_timer

        if anim_controller.current_frame == anim.count {
            anim_controller.current_frame = 0
        }
    }


    sprite := SPRITE_MAP[sprite_name]
    
    width := sprite.w / f32(sprite.count)


    source := rl.Rectangle {
        x = f32(anim_controller.current_frame + anim.frame_start) * width + sprite.x,
        y = sprite.y,
        width = width,
        height = sprite.h
    }

    if is_flip {
        source.width = -source.width
    }

    rl.DrawTexturePro(atlas, source, dest, {0, 0}, 0, rl.WHITE)
}