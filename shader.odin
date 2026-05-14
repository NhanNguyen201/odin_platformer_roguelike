package main
import rl "vendor:raylib"
import "core:c"

Shader_locations :: struct {
    res_loc : c.int,
    screen_size_loc: c.int,
    light_loc: c.int,
    uTime: c.int
}

Shader_args :: struct {
    target : rl.RenderTexture2D,
    screen_size: rl.Vector2,
    light_pos: rl.Vector2,
    screen_resolution: rl.Vector2
}


get_shader_locs :: proc(shader: rl.Shader) -> Shader_locations {
    resolutionLoc := rl.GetShaderLocation(shader, "resolution")
    
       
    screenSizeLoc := rl.GetShaderLocation(shader, "screenSize")
    lightPosLoc   := rl.GetShaderLocation(shader, "lightPos")
    uTimeLoc := rl.GetShaderLocation(shader, "uTime")
    return {
        res_loc = resolutionLoc,
        screen_size_loc = screenSizeLoc,
        light_loc = lightPosLoc,
        uTime = uTimeLoc
    }
}
