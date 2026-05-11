package main
import rl "vendor:raylib"

Witch_state :: enum {
    RELOAD,
    BLESS,
}

Witch_tpye :: enum {
    GOOD,
    BAD
} 

Witch :: struct {
    is_active: bool,
    body: Body,
    reload: Timer
}

