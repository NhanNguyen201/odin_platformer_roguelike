package main
import rl "vendor:raylib"




get_body_rect :: proc(body: Body) -> rl.Rectangle {
    return {body.position.x -  body.size.x / 2, body.position.y -  body.size.y / 2, body.size.x, body.size.y}

}
get_enemy_body_rect :: proc(body: Enemy_Body) -> rl.Rectangle {
    return {body.position.x -  body.size.x / 2, body.position.y -  body.size.y / 2, body.size.x, body.size.y}

}

resolve_horizontal :: proc(player: ^Player, rect: rl.Rectangle) {
    pr := get_body_rect(player.body)

    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.x < rect.x {
        player.body.position.x = rect.x - pr.width / 2
    } else {
        player.body.position.x = rect.x + rect.width  + pr.width / 2
    } 
    if !player.on_ground {
        player.body.vel.x = 0
    }
}

resolve_enemy_horizontal :: proc(body: ^Enemy_Body, rect: rl.Rectangle) {
    pr := get_enemy_body_rect(body^)

    if !rl.CheckCollisionRecs(pr, rect) do return


    if pr.x < rect.x {
        body.position.x = rect.x - pr.width / 2
        
    } else {
        body.position.x = rect.x + rect.width  + pr.width / 2
    } 
    body.direction = body.direction == .LEFT ? .RIGHT : .LEFT 
    body.vel.x *= -1
}

resolve_vertical :: proc( player : ^Player, rect : rl.Rectangle) {
    pr := get_body_rect(player.body)
    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.y < rect.y {
        player.body.position.y = rect.y - pr.height / 2
        player.on_ground = true
        player.body.vel.y = 0
    } else {
        player.body.position.y = rect.y + rect.height + pr.height / 2
        player.body.vel.y = 0
    }
}

resolve_enemy_vertical :: proc(body: ^Enemy_Body, rect: rl.Rectangle) {
    pr := get_enemy_body_rect(body^)


    if !rl.CheckCollisionRecs(pr, rect) do return

     if pr.y < rect.y {
        body.position.y = rect.y - pr.height / 2
        body.vel.y = 0
    } else {
        body.position.y = rect.y + rect.height + pr.height / 2
        body.vel.y = 0
    }
}

resolve_e_mele_attack:: proc(player: ^Player, enemy: ^Enemy_melee, force: f32, dt: f32) {
    player_rect := get_body_rect(player.body)
    enemy_rect := get_enemy_body_rect(enemy.body)
    if !rl.CheckCollisionRecs(player_rect, enemy_rect) do return

    enemy.combat_state = .PARTROL

    player.body.vel.x += (-enemy.body.position.x + player.body.position.x) * force 

}

resolve_enemy_and_bullet:: proc(e_body: Enemy_Body, health_stats: ^Health_stats, bullets: ^[dynamic]Bullet ) {
    pr := get_enemy_body_rect(e_body)

    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(pr, bullet_rect) do continue 

        enemy_take_dmg(health_stats, bullet)
        unordered_remove(bullets, idx)

        break
    }


}

resolve_player_and_bullet:: proc(body: Body, player_buffes: Player_buffes, health_stats: ^Health_stats, bullets: ^[dynamic]Bullet ) {
    pr := get_body_rect(body)

    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(pr, bullet_rect) do continue 

        player_take_dmg(health_stats, player_buffes, bullet.dmg)
        unordered_remove(bullets, idx)

        break
    }


}


resolve_bullet_collider_collision:: proc(game: ^Game, bullets: ^[dynamic]Bullet,  rect: rl.Rectangle) {
    sprite := SPRITE_MAP[PARTICLE_SPRITE]
    sprite_source := rl.Rectangle {x = sprite.x, y= sprite.y, width = sprite.w, height = sprite.h}
    for bullet, idx in bullets{
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(rect, bullet_rect)  {
            continue    
        }
        // pos := rl.Collision
        unordered_remove(bullets, idx)
        add_particle(&game.particle_system, Particle {
            timer = {
                current = 0.3,
                max_time = 0.3
            } ,
            position = {bullet.position.x, bullet.position.y},
            sprite_source = sprite_source,
            is_blur = true,
            is_scaled = true
        })
        break
       
    }
}

resolve_spawner_and_bullet :: proc( spawner : ^Enemy_spawner_pot, bullets: ^[dynamic]Bullet) {
    for bullet, idx in bullets{
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}
        spawner_rect := rl.Rectangle {x = spawner.position.x - ENEMY_SPAWNER_SIZE.x / 2, y = spawner.position.y - ENEMY_SPAWNER_SIZE.y / 2, width = ENEMY_SPAWNER_SIZE.x, height = ENEMY_SPAWNER_SIZE.y}
        if !rl.CheckCollisionRecs(spawner_rect, bullet_rect)  {
            continue    
        }
        // pos := rl.Collision
        spawner.hp_stats.current_hp -= bullet.dmg
        spawner.anim_controller.animation_name = HURT_ANI
        unordered_remove(bullets, idx)
        break
       
    }
}


enemy_take_dmg :: proc(health: ^Health_stats, bullet: Bullet) {
    health.current_hp -= bullet.dmg
}

player_take_dmg :: proc(health: ^Health_stats, player_buff: Player_buffes,dmg: f32) {
    reduced_dmg := dmg * (1 - (player_buff.armor / 100))

    if health.current_hp > reduced_dmg {
        health.current_hp -= reduced_dmg
    } else {
        health.current_hp = 0
    }
}

check_collision_line_rect :: proc(p1, p2: rl.Vector2, r: rl.Rectangle)  -> bool {
    collision_point: rl.Vector2
    if rl.CheckCollisionLines(p1, p2, {r.x, r.y}, {r.x + r.width, r.y}, &collision_point) || 
        rl.CheckCollisionLines(p1, p2, {r.x, r.y}, {r.x, r.y + r.height}, &collision_point) || 
        rl.CheckCollisionLines(p1, p2, {r.x + r.width, r.y}, {r.x + r.width, r.y + r.height}, &collision_point) || 
        rl.CheckCollisionLines(p1, p2, {r.x , r.y + r.height}, {r.x + r.width, r.y + r.height}, &collision_point) 
    {
        return true
    }
    return false
}