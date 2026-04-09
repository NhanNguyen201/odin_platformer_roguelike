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

resolve_minion_horizontal :: proc(minion: ^Enemy_minion, rect: rl.Rectangle) {
    pr := get_body_rect(minion.body)

    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.x < rect.x {
        minion.body.position.x = rect.x - pr.width / 2
    } else {
        minion.body.position.x = rect.x + rect.width  + pr.width / 2
    } 
    minion.direction = minion.direction == .LEFT ? .RIGHT : .LEFT
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

resolve_minion_vertical :: proc(minion: ^Enemy_minion, rect: rl.Rectangle) {
    pr := get_body_rect(minion.body)


    if !rl.CheckCollisionRecs(pr, rect) do return

     if pr.y < rect.y {
        minion.body.position.y = rect.y - pr.height / 2
        minion.body.vel.y = 0
    } else {
        minion.body.position.y = rect.y + rect.height + pr.height / 2
        minion.body.vel.y = 0
    }
}



resolve_enemy_and_bullet:: proc(minion: ^Enemy_minion, bullets: ^[dynamic]Bullet) {
    pr := get_body_rect(minion.body)

    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(pr, bullet_rect) do continue 

        enemy_take_dmg(minion, bullet)
        unordered_remove(bullets, idx)

        break
    }


}


resolve_bullet_collider_collision:: proc(game: ^Game, bullets: ^[dynamic] Bullet,  rect: rl.Rectangle) {
    for bullet, idx in bullets {
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