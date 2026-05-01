package main

import rl "vendor:raylib"

import "core:mem"
import "core:fmt"


SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 760
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

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Platform shooter")
    rl.SetWindowPosition(30, 60)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(60)
    rl.SetExitKey(.KEY_NULL)
    

    game := game_init()
    game.fonts = load_fonts()
    game.game_options.cursor_controler.draw_cursor = true
    game.camera = rl.Camera2D {
        zoom = SCREEN_HEIGHT / PIXEL_WINDOW_HEIGHT,
        offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)},
        target = game.player.body.position + rl.Vector2{PLAYER_SIZE.x / 2, PLAYER_SIZE.y / 2}
    }


    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        
        game_pre_update(&game, dt)
        game_update(&game, dt)
        game_post_update(&game, dt)

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(game.camera)

        
        
        game_draw(&game, dt)
        game_ui_scene_draw(&game, dt)

        rl.EndMode2D()
        rl.EndDrawing()
    }

    drop_game_mem(&game)

}