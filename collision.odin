package main
import rl "vendor:raylib"




get_body_rect :: proc(body: Body) -> rl.Rectangle {
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
}

resolve_minion_horizontal :: proc(body: ^Body, rect: rl.Rectangle) {
    pr := get_body_rect(body^)

    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.x < rect.x {
        body.position.x = rect.x - pr.width / 2
    } else {
        body.position.x = rect.x + rect.width  + pr.width / 2
    } 
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

resolve_minion_vertical :: proc(body: ^Body, rect: rl.Rectangle) {
    pr := get_body_rect(body^)


    if !rl.CheckCollisionRecs(pr, rect) do return

     if pr.y < rect.y {
        body.position.y = rect.y - pr.height / 2
        body.vel.y = 0
    } else {
        body.position.y = rect.y + rect.height + pr.height / 2
        body.vel.y = 0
    }
}



resolve_enemy_and_bullet:: proc(e_body: Body, health_stats: ^Health_stats, bullets: ^[dynamic]Bullet ) {
    pr := get_body_rect(e_body)

    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(pr, bullet_rect) do continue 

        enemy_take_dmg(health_stats, bullet)
        unordered_remove(bullets, idx)

        break
    }


}


resolve_bullet_collider_collision:: proc(game: ^Game, bullets: ^[dynamic]Bullet,  rect: rl.Rectangle) {
    // bullets.data
    for bullet, idx in bullets{
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(rect, bullet_rect)  {
            continue    
        }
        // pos := rl.Collision
        unordered_remove(bullets, idx)
        add_particle(&game.particle_system, Particle {duration = 0.3, time_left = 0.3, position = {bullet.position.x, bullet.position.y}})
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
