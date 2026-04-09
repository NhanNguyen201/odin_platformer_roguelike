#+feature dynamic-literals

package main
import rl "vendor:raylib"
import "core:math"
import "core:container/small_array"

IDLE :: "Idle"
RUN :: "Run"

MAX_PARTICLE:int : 200
Animation_controller :: struct {
    animation_name : string,

    current_frame: int,
    current_timer: f32,
}

Particle :: struct {
    position: rl.Vector2,
    duration: f32,
    time_left: f32,
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

add_particle:: proc(particle_sys: ^Particles_systems, new_particle: Particle) {
    small_array.push(&particle_sys.particles, new_particle)
    
}

particles_systems_update :: proc(particle_sys: ^Particles_systems, dt: f32) {
    for i:= 0; i < particle_sys.particles.len; i += 1 {

        if particle_sys.particles.data[i].time_left - dt <= 0 {
            small_array.unordered_remove(&particle_sys.particles, i)
            continue
        } else {
            particle_sys.particles.data[i].time_left -= dt
        }
    }
}

particls_systems_draw:: proc(atlas: rl.Texture2D, particle_sys: Particles_systems, dt: f32) {
    particle_sprite := SPRITE_MAP[PARTICLE_SPRITE]
    particle_soure := rl.Rectangle {x = particle_sprite.x, y = particle_sprite.y, width = particle_sprite.w, height = particle_sprite.h}
    for i:= 0; i < particle_sys.particles.len; i += 1 {
        p := small_array.get(particle_sys.particles, i)
        scale := 5. * (p.duration - p.time_left)
        dest := rl.Rectangle {x = p.position.x  , y = p.position.y - 50. * math.sin_f32( p.time_left ), width = particle_soure.width * scale, height = particle_soure.height * scale}
        rl.DrawTexturePro(atlas, particle_soure, dest, {dest.width / 2, dest.height / 2}, 0. , rl.Color {255, 255, 255, u8(55 +  200 * p.time_left / p.duration)})
    }
}
// math.sin_f32( (p.duration - p.time_left) / p.duration) * 90