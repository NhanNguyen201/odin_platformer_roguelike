package main
import rl "vendor:raylib"


player_rect :: proc(p: Player) -> rl.Rectangle {
    return {p.position.x -  p.size.x / 2, p.position.y -  p.size.y / 2, p.size.x, p.size.y}
}
enemy_minion_rect :: proc(enemy: Enemy_minion) -> rl.Rectangle {
    return {enemy.position.x -  enemy.size.x / 2, enemy.position.y -  enemy.size.y / 2, enemy.size.x, enemy.size.y}

}

resolve_horizontal :: proc(player: ^Player, rect: rl.Rectangle) {
    pr := player_rect(player^)

    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.x < rect.x {
        player.position.x = rect.x - pr.width / 2
    } else {
        player.position.x = rect.x + rect.width  + pr.width / 2
    } 
}

resolve_minion_horizontal :: proc(minion: ^Enemy_minion, rect: rl.Rectangle) {
    pr := enemy_minion_rect(minion^)

    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.x < rect.x {
        minion.position.x = rect.x - pr.width / 2
    } else {
        minion.position.x = rect.x + rect.width  + pr.width / 2
    } 
    minion.direction = minion.direction == .LEFT ? .RIGHT : .LEFT
}

resolve_vertical :: proc( player : ^Player, rect : rl.Rectangle) {
    pr := player_rect(player^)
    if !rl.CheckCollisionRecs(pr, rect) do return

    if pr.y < rect.y {
        player.position.y = rect.y - pr.height / 2
        player.on_ground = true
        player.vel.y = 0
    } else {
        player.position.y = rect.y + rect.height + pr.height / 2
        player.vel.y = 0
    }
}
resolve_minion_vertical :: proc(minion: ^Enemy_minion, rect: rl.Rectangle) {
    pr := enemy_minion_rect(minion^)


    if !rl.CheckCollisionRecs(pr, rect) do return

     if pr.y < rect.y {
        minion.position.y = rect.y - pr.height / 2
        minion.vel.y = 0
    } else {
        minion.position.y = rect.y + rect.height + pr.height / 2
        minion.vel.y = 0
    }
}



resolve_enemy_and_bullet:: proc(minion: ^Enemy_minion, bullets: ^[dynamic]Bullet) {
    pr := enemy_minion_rect(minion^)

    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(pr, bullet_rect) do continue 

        enemy_take_dmg(minion, bullet)
        unordered_remove(bullets, idx)
        break
    }


}


resolve_bullet_collider_collision:: proc(bullets: ^[dynamic] Bullet,  rect: rl.Rectangle) {
    for bullet, idx in bullets {
        bullet_rect := rl.Rectangle {x = bullet.position.x - BULLET_SIZE.x / 2, y = bullet.position.y - BULLET_SIZE.y / 2, width = BULLET_SIZE.x, height = BULLET_SIZE.y}

        if !rl.CheckCollisionRecs(rect, bullet_rect)  {
            continue    
        }

        unordered_remove(bullets, idx)
        break
       
    }
}