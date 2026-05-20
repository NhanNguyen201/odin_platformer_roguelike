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
    // rl.SetConfigFlags({ .WINDOW_RESIZABLE })
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Platform shooter")
    rl.SetWindowPosition(30, 60)
    // rl.SetWindowState({.})
    rl.SetTargetFPS(60)
    rl.SetExitKey(.KEY_NULL)
    fullscreen := false
    game := game_init()
    game.shader = rl.LoadShader("", "shaders/shader.frag")
     // Create render texture
    game.shader_args.target = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
    shader_loccations := get_shader_locs(game.shader)
    resolution := [2]f32 {
        f32(SCREEN_WIDTH),
        f32(SCREEN_HEIGHT),
    }
    rl.SetShaderValue(
        game.shader,
        shader_loccations.screen_size_loc,
        &resolution[0],
        rl.ShaderUniformDataType.VEC2,
    )
    // Send resolution uniform
    
   

    game.fonts = load_fonts()
    game.game_options.cursor_controler.draw_cursor = true
    game.camera = rl.Camera2D {
        zoom = SCREEN_HEIGHT / PIXEL_WINDOW_HEIGHT,
        offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)},
        target = get_rect_center(get_body_rect(game.player.body))
    }
    
    defer {
        for _, entry in track.allocation_map {
            fmt.eprintf("%v leak %v bytes \n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprintf("%v bad free \n", entry.location)
            
        }
        mem.tracking_allocator_destroy(&track)
        free_all(context.temp_allocator)
        rl.UnloadShader(game.shader)
        rl.CloseWindow()
        
    }

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        slow_dt := game.slow_motion_manager.is_slow_motion ? dt * 0.5 : dt 
        shader_target := game.shader_args.target
        

       
        game_pre_update(&game, slow_dt)
        
        game_update(&game, slow_dt)
        game_post_update(&game, slow_dt)
        // Draw texture from the game
        rl.BeginTextureMode(shader_target)

        rl.ClearBackground(rl.BLACK)
        rl.BeginMode2D(game.camera)
        game_draw(&game, game.game_options.is_paused ? 0 : slow_dt)
        rl.EndMode2D()
       
        rl.EndTextureMode()
        // End texture mode


        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        rl.BeginShaderMode(game.shader)
        rl.DrawTextureRec(
            shader_target.texture,
            rl.Rectangle{
                0,
                0,
                f32(shader_target.texture.width),
                -f32(shader_target.texture.height),
            },
            rl.Vector2{0, 0},
            rl.WHITE,
        )
        rl.EndShaderMode()
        rl.BeginMode2D(game.camera)
        game_ui_draw(&game, slow_dt)
        rl.EndMode2D()

        rl.EndDrawing()

    
    }

    drop_game_mem(&game)

}