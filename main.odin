package main

import rl "vendor:raylib"

import "core:mem"
import "core:fmt"


SCREEN_HEIGHT :: 720
SCREEN_WIDTH :: 1280
PIXEL_WINDOW_HEIGHT :: 180


main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leak %v bytes \n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free \n", entry.location)

        }
        mem.tracking_allocator_destroy(&track)
        free_all(context.temp_allocator)
        
        rl.CloseWindow()

    }

    rl.InitWindow(1280, 780, "My first game")
    rl.SetWindowPosition(30, 60)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)



    game := game_init()
    
    game.camera = rl.Camera2D {
        zoom = SCREEN_HEIGHT / PIXEL_WINDOW_HEIGHT,
        offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)},
        target = game.player.position
    }

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        t := rl.GetTime()

        game_update(&game, dt)

        rl.BeginDrawing()
         rl.ClearBackground(rl.BLACK)

        game.camera.target = game.player.position + rl.Vector2{PLAYER_SIZE.x / 2, PLAYER_SIZE.y / 2}
        rl.BeginMode2D(game.camera)

        
        
        game_draw(&game, dt)
        

        rl.EndMode2D()
        rl.EndDrawing()
    }

    delete(game.enemy_bullets)
    delete(game.player_bullets)
    delete(game.enemy_minions)
    delete(game.level_data.colliders)
    delete(game.level_data.enemy_spawners)
    delete(game.level_data.keys)
    delete(game.level_data.exp_buffs)
}