#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:math"

import "core:container/small_array"

IDLE_ANI :: "Idle_ani"
RUN_ANI :: "Run_ani"
HURT_ANI :: "Hurt_ani"
ATTACK_ANI :: "Attack_ani"
RELOAD_ANI :: "Reload_ani"
MAX_PARTICLE:int : 200

Animation_controller :: struct {
    default_ani: string,
    animation_name : string,

    current_frame: int,
    current_timer: f32,
}

Particle :: struct {
    position: rl.Vector2,
    sprite_source: rl.Rectangle,
    timer: Timer,
    is_scaled: bool,
    is_blur: bool,
    is_flip: bool,
    sprite_count: int,
    rotation: f32,
    size: rl.Vector2
}

Particles_systems :: struct {
    particles : small_array.Small_Array(MAX_PARTICLE, Particle)
}


Animation :: struct {
    name : string,
    count: int,
    frame_start: int,
    frame_end : int,
    frame_timer : f32,
    is_loop: bool
}


Player_animations := map[string] Animation {
    IDLE_ANI = {name = IDLE_ANI, frame_start = 0, frame_end = 1, frame_timer = .5, count = 2, is_loop = true },
    RUN_ANI = {name = RUN_ANI, frame_start = 2, frame_end = 4, frame_timer = .25, count = 3, is_loop = true },
}

Portal_animations := map[string] Animation {
    IDLE_ANI = {name = IDLE_ANI, frame_start = 0, frame_end = 0, frame_timer = 0.5, count = 1, is_loop = true },
    HURT_ANI = {name = HURT_ANI, frame_start = 1, frame_end = 2, frame_timer = 0.25, count = 2, is_loop = false },
}

E_melee_animations := map[string] Animation {
    IDLE_ANI = {name = IDLE_ANI, frame_start = 0, frame_end = 1, frame_timer = 0.5, count = 2, is_loop = true },
    RUN_ANI = {name= RUN_ANI, frame_start = 2, frame_end = 5, frame_timer = .25, count = 4, is_loop = true },
    ATTACK_ANI = {name= RUN_ANI, frame_start = 6, frame_end = 8, frame_timer = .25, count = 3, is_loop = true }
}

E_ranger_animations := map[string] Animation {
    IDLE_ANI = {name = IDLE_ANI, frame_start = 0, frame_end = 1, frame_timer = 0.5, count = 2, is_loop = true },
    RUN_ANI = {name= RUN_ANI, frame_start = 2, frame_end = 5, frame_timer = .25, count = 4, is_loop = true },
    RELOAD_ANI  = {name= RELOAD_ANI ,frame_start = 6, frame_end = 7, frame_timer = .25, count = 2, is_loop = true}
}

E_sniper_animations := map[string] Animation {
    IDLE_ANI = {name = IDLE_ANI, frame_start = 0, frame_end = 1, frame_timer = 0.5, count = 2, is_loop = true },
    RUN_ANI = {name= RUN_ANI, frame_start = 0, frame_end = 1, frame_timer = .25, count = 2, is_loop = true },
}

draw_animation :: proc (atlas: rl.Texture2D, anim_controller : ^Animation_controller, anim: Animation, sprite_name: string, is_flip: bool, dest: rl.Rectangle ,dt: f32) {
    anim_controller.current_timer -= dt

    if anim_controller.current_timer <= 0 {
        anim_controller.current_frame += 1
        anim_controller.current_timer = anim.frame_timer

        if anim_controller.current_frame == anim.count {
            if !anim.is_loop {
                anim_controller.animation_name = anim_controller.default_ani
            } 
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

add_particle:: proc(particle_sys: ^Particles_systems, new_particle: Particle) {
    small_array.push(&particle_sys.particles, new_particle)
    
}

particles_systems_update :: proc(particle_sys: ^Particles_systems, dt: f32) {
    for i:= 0; i < particle_sys.particles.len; i += 1 {

        if particle_sys.particles.data[i].timer.current - dt <= 0 {
            small_array.unordered_remove(&particle_sys.particles, i)
            continue
        } else {
            particle_sys.particles.data[i].timer.current -= dt
        }
    }
}

particls_systems_draw:: proc(atlas: rl.Texture2D, particle_sys: Particles_systems, dt: f32) {
    // particle_sprite := SPRITE_MAP[PARTICLE_SPRITE]
    // particle_soure := rl.Rectangle {x = particle_sprite.x, y = particle_sprite.y, width = particle_sprite.w, height = particle_sprite.h}
    for i:= 0; i < particle_sys.particles.len; i += 1 {
        p := small_array.get(particle_sys.particles, i)
        time_left := p.timer.max_time - p.timer.current
        sprite_count := max(p.sprite_count, 1)
        current_frame := math.floor_f32(time_left / p.timer.max_time * f32(sprite_count))
        frame_width := p.sprite_source.width / f32(sprite_count)
        new_sprite_source := rl.Rectangle {x = p.sprite_source.x + (frame_width * current_frame), y = p.sprite_source.y, width = frame_width * (p.is_flip ? -1 : 1), height = p.sprite_source.height}
        scale :=  p.is_scaled ? 1. + .5 * time_left / p.timer.max_time : 1
        tint := p.is_blur ? rl.Color {255, 255, 255, u8(55 +  200 * p.timer.current / p.timer.max_time)} : rl.WHITE
        dest := rl.Rectangle {x = p.position.x  , y = p.position.y , width = p.size.x * scale, height = p.size.y * scale}
        rl.DrawTexturePro(atlas, new_sprite_source, dest, {dest.width / 2, dest.height / 2}, p.rotation , tint)
    }
}
// math.sin_f32( (p.duration - p.time_left) / p.duration) * 90