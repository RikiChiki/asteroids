
require daslib/media
require daslib/decs_boost
require daslib/random

var
    seed = random_seed(0)

let
    sw = float(get_screen_width())
    sh = float(get_screen_height())

    PLAYER_ACL = 200.0
    PLAYER_ROTATION_VEL = 3.0
    PLAYER_RELOAD_TIME = 0.3
    PLAYER_INIT_LIFES = 5
    PLAYER_RESPAWN_TIME = 2.0

    BULLET_VEL = 800.0
    BULLET_LIFE_SEC = 1.4

    MAP_BORDER_EPS = float2(get_screen_width(), get_screen_height()) * 0.01

    ASTEROID_BIG_VEL = 200.0
    ASTEROID_BIG_SIZE = float(get_screen_width()) * 0.06
    ASTEROID_BIG_SCORE = 13
    ASTEROID_MEDIUM_SCORE = 45
    ASTEROID_MEDIUM_VEL = 250.0
    ASTEROID_MEDIUM_SIZE = float(get_screen_width()) * 0.04
    ASTEROID_SMALL_SCORE = 81
    ASTEROID_SMALL_VEL = 400.0
    ASTEROID_SMALL_SIZE = float(get_screen_width()) * 0.01

    ASTEROIDS_SPAWN_TIME = 2.0
    ASTEROIDS_SPAWN_COUNT = 2

    ENGINE_EMITTER_RELOAD_TIME = 0.2
    ENGINE_PARTICLE_VEL = 30.0
    ENGINE_PARTICLE_ROTATION = 0.5
    ENGINE_PARTICLE_SIZE = 7.0
    ENGINE_PARTICLE_SIZE_SCALE_VEL = 1.0
    ENGINE_PARTICLE_LIFE_TIME = 5.0

    BONUS_RESPAWN_TIME = 15.0

    BACKGROUND_COLOR = uint(0x241734)
    SHIP_COLOR = uint(0xf9c80e)
    ENGINE_PARTICLE_COLOR = uint(SHIP_COLOR)
    BULLET_COLOR = uint(0x2DE2E6)
    ASTEROID_COLOR = uint(0xFF6C11)
    ASTEROID_BURST_COLOR = uint(0xff3864)
    BONUS_COLOR = uint(0xD40078)

/*****************************************/

let shapes <- {{
  "base_ship" => [{auto float2(-0.5, -1.0); float2(0.0, 1.0); float2(0.5, -1.0); float2(0.0, -0.3); float2(-0.5, -1.0) }];
  "bullet" => [{auto float2(-0.5f, -1.0f); float2(0.0f, 1.0f); float2(0.5f, -1.0f); float2(0.0f, -0.3f); float2(-0.5f, -1.0f)}];
  "asteroid" => [{auto float2(-1.0f / 4.0f, 1.0f); float2(1.0f / 4.0f, 1.0f); float2(1.0f / 4.0f, 7.0f / 8.0f);
          float2(6.0f / 8.0f, 7.0f / 8.0f); float2(6.0f / 8.0f, 3.0f / 8.0f); float2(1.0f, 3.0f / 8.0f);
          float2(1.0f, -1.0f / 8.0f); float2(7.0f / 8.0f, -1.0f / 8.0f); float2(4.0f / 8.0f, -4.0f / 8.0f);
          float2(4.0f / 8.0f, -1.0f); float2(-6.0f / 8.0f, -1.0f); float2(-6 / 8, -7 / 8);
          float2(-1.0f, -6.0f / 8.0f); float2(-1.0f, 1.0f / 8.0f); float2(-7.0f / 8.0f, 2.0f / 8.0f);
          float2(-2.0f / 8.0f, 2.0f / 8.0f); float2(-1.0f / 4.0f, 1.0f)
  }];
  "tri_particle" => [{auto  float2(-0.5, 0.0);  float2(0.0, 0.5); float2(0.5, 0.0); float2(0.0, -0.5); float2(-0.5, 0.0)}]
}}


enum AsteroidType
    None
    Small
    Medium
    Big

enum BonusType
    Health

enum ObjectType
    Player
    Bullet
    Asteroid
    Bonus

def random_float(a,b:float)
    return a + random_float(seed) * (b-a)

def get_forward(angle)
    return -rotate(float2(0.0, -1.0), angle)

def get_map_center()
    return float2(get_screen_width(), get_screen_height()) * 0.5

def get_world_mouse_position()
    return screen_to_world(get_mouse_position())

def rotate(var point: float2; var angle: float)
    let cs = cos(angle)
    let sn = sin(angle)

    return float2(
      point.x * cs - point.y * sn,
      point.x * sn + point.y * cs
    )

def point_to_world(var world_pos: float2; var world_angle, world_size: float)
    return rotate(world_pos, world_angle) * world_size

/******************************/
def spawn_asteroid(pos: float2; vel, angle, size:float; kind: AsteroidType; shape: string)
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("pos", pos)
        cmp |> set("forward_vel", vel)
        cmp |> set("angle", angle)
        cmp |> set("size", size)
        cmp |> set("asteroid_type", kind)
        cmp |> set("shape", shape)
        cmp |> set("team", 1)
        cmp |> set("obj_type", ObjectType Asteroid)
        cmp |> set("color", ASTEROID_COLOR)
        cmp |> set("alive", true)
    return

def spawn_asteroid(pos: float2; kind: AsteroidType)
    let angle = random_float(seed) * 2.0 * PI
    var vel = 0.0
    var size = 0.0

    if kind == AsteroidType Big
        vel = ASTEROID_BIG_VEL
        size = ASTEROID_BIG_SIZE
    elif kind == AsteroidType Medium
        vel = ASTEROID_MEDIUM_VEL
        size = ASTEROID_MEDIUM_SIZE
    elif kind == AsteroidType Small
        vel = ASTEROID_SMALL_VEL
        size = ASTEROID_SMALL_SIZE

    spawn_asteroid(pos, vel, angle, size, kind, "asteroid")
    return

def spawn_bullet(pos:float2; vel, angle, size: float; shape: string)
    let death_time = get_time_after_start() + BULLET_LIFE_SEC
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("pos", pos)
        cmp |> set("forward_vel", vel)
        cmp |> set("angle", angle)
        cmp |> set("size", size)
        cmp |> set("shape", shape)
        cmp |> set("death_time", death_time)
        cmp |> set("team", 0)
        cmp |> set("obj_type", ObjectType Bullet)
        cmp |> set("color", BULLET_COLOR)
        cmp |> set("alive", true)
    return

def spawn_burst(pos:float2; particlesCount: int; lifeSeconds:float)
    if particlesCount == 0
        return
    let anglePerParticle = 2.0 * PI / float(particlesCount)
    for i in range(0, particlesCount)
        let angle = float(i) * anglePerParticle
        let vel = random_float(30.0, 60.0)
        let death_time = get_time_after_start() + lifeSeconds
        let shape = "tri_particle"
        create_entity() <| @(eid, cmp)
            cmp |> set("eid", eid)
            cmp |> set("pos", pos)
            cmp |> set("angle", angle)
            cmp |> set("size", 10.0)
            cmp |> set("forward_vel", vel)
            cmp |> set("death_time", death_time)
            cmp |> set("shape", shape)
            cmp |> set("color", ASTEROID_BURST_COLOR)
    return

def spawn_bonus(pos:float2; bonusType: BonusType)
    create_entity() <| @(eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("pos", pos)
        cmp |> set("angle", 0.0)
        cmp |> set("size", 30.0)
        cmp |> set("shape", "tri_particle")
        cmp |> set("color", BONUS_COLOR)
        cmp |> set("rotation_vel", 1.0)
        cmp |> set("alive", true)
        cmp |> set("obj_type", ObjectType Bonus)
        cmp |> set("bonus_type", BonusType Health)
        cmp |> set("team", 1)
    return

/************ DRAW ************/
def draw_strip_lines(points: array<float2>; var world_origin_pos: float2; var world_angle, world_size: float; color:uint)
    for i in range(0, length(points)-1)
        let p0 = world_origin_pos + point_to_world(points[i], world_angle, world_size)
        let p1 = world_origin_pos + point_to_world(points[i+1], world_angle, world_size)
        line(p0.x, p0.y, p1.x, p1.y, color)
    return

[decs(stage=draw)]
def draw_shape(pos: float2; angle, size:float; shape:string; color:uint)
    let shape_points = find(shapes, shape)
    if shape_points != null
        draw_strip_lines(deref(shape_points), pos, angle, size, color)
    return

[decs(stage = draw)]
def draw_score(score: int)
    text_out(1,1, "SCORE:{score}", 0xffffff)
    return

[decs(stage = draw)]
def draw_player_life(player_lifes: int)
    let shape_points = find(shapes, "base_ship")
    let size = sw / 60.0
    let space = 5.0
    var base = float2(sw * 0.01, sh * 0.07)
    for i in range(0, player_lifes)
        var pos = float2(
          base.x + float(i) * (space + size),
          base.y
        )
        draw_strip_lines(deref(shape_points), pos, PI, size, SHIP_COLOR)
    return

[decs(stage = draw)]
def emitter(pos:float2; angle:float; size:float; emitter_enabled: bool; var emitter_next_spawn_time: float&; emitter_reload_time: float)
    if !emitter_enabled
        return
    let time = get_time_after_start()
    if time > emitter_next_spawn_time
        emitter_next_spawn_time = time + emitter_reload_time
        let backward = -1.0 * get_forward(angle)
        let particle_pos = pos + backward * size * 0.7
        create_entity() <| @(eid, cmp)
            cmp |> set("pos", particle_pos)
            cmp |> set("angle", angle + PI)
            cmp |> set("size", ENGINE_PARTICLE_SIZE)
            cmp |> set("forward_vel", ENGINE_PARTICLE_VEL)
            cmp |> set("shape", "tri_particle")
            cmp |> set("rotation_vel", ENGINE_PARTICLE_ROTATION)
            cmp |> set("size_scale_vel", ENGINE_PARTICLE_SIZE_SCALE_VEL)
            cmp |> set("death_time", get_time_after_start() + ENGINE_PARTICLE_LIFE_TIME)
            cmp |> set("color", ENGINE_PARTICLE_COLOR)
    return

[decs(stage = draw)]
def draw_restart_hint(player_lifes:int)
    if player_lifes == 0
        text_out(get_screen_width()/2 - 100, get_screen_height()/2, "RESTART: CTRL+F5", SHIP_COLOR )
    return

/************ UPDATE ************/

[decs(stage=update)]
def generate_bonus(var bonus_next_time_spawn: float&; bonus_respawn_time: float)
    let time = get_time_after_start()
    if time > bonus_next_time_spawn
        bonus_next_time_spawn = time + bonus_respawn_time
        let pos = float2(
          random_float(sw * 0.3, sw * 0.8),
          random_float(sh * 0.3, sh * 0.8)
        )
        spawn_bonus(pos, BonusType Health)
    return

[decs(stage=update)]
def size_scaler(var size:float&; size_scale_vel: float)
    size -= size_scale_vel * get_delta_time()
    if size < 0.5
        size = 0.5
    return

[decs(stage=update)]
def death_timer(eid:EntityId; death_time:float)
    if get_time_after_start() > death_time
        delete_entity(eid)

[decs(stage=update)]
def forward_move(var pos: float2&; angle: float; forward_vel: float)
    let forward = get_forward(angle)
    pos += forward_vel * get_delta_time() * forward
    pos = respawn_if_needed(pos)
    return

[decs(stage = update)]
def player_respawn_timer(eid: EntityId; player_respawn_time:float)
    let ableToRespawn = find_query() <| $(player_lifes: int)
        if player_lifes > 0
            return true
        else
            return false
    if get_time_after_start() > player_respawn_time
        if ableToRespawn
            init_player()
        delete_entity(eid)
    return

[decs(stage = update)]
def check_asteroids_for_respawn(asteroids_respawner_enabled: bool)
    if !asteroids_respawner_enabled
        return

    let asteroidsAlive = find_query() <| $(asteroid_type: AsteroidType)
        if asteroid_type == AsteroidType Big || asteroid_type == AsteroidType Medium
            return true
        else
            return false

    let spawnTimerAlive = find_query() <| $(asteroids_next_time_spawn: float)
        return true

    if !asteroidsAlive && !spawnTimerAlive
        create_entity() <| @(eid, cmp)
            cmp |> set("eid", eid)
            cmp |> set("asteroids_next_time_spawn", get_time_after_start() + ASTEROIDS_SPAWN_TIME)
            cmp |> set("asteroids_spawn_count", ASTEROIDS_SPAWN_COUNT)
    return

[decs(stage=update)]
def respawn_asteroids(eid: EntityId; asteroids_next_time_spawn: float; asteroids_spawn_count: int)
    if get_time_after_start() < asteroids_next_time_spawn
        return

    delete_entity(eid)

    for i in range(0, asteroids_spawn_count)
        let x = random_float(seed) * sw
        let y = random_float(seed) * sh
        var pos = float2(0.0, 0.0)

        let border = i % 4
        if border == 0
            pos = float2(x, sh)
        elif border == 1
            pos = float2(x, 0.0)
        elif border == 2
            pos = float2(sw, y)
        elif border == 3
            pos = float2(sw, 0.0)

        spawn_asteroid(pos, AsteroidType Big)
    return

def respawn_if_needed(var pos: float2)
    let w = float(get_screen_width())
    let h = float(get_screen_height())
    let border_spawn = MAP_BORDER_EPS * 0.6
    if pos.x > w + MAP_BORDER_EPS.x
        pos.x = -border_spawn.x
    elif pos.x < -MAP_BORDER_EPS.x
        pos.x = w + border_spawn.x
    elif pos.y > h + MAP_BORDER_EPS.y
        pos.y = -border_spawn.y
    elif pos.y < -MAP_BORDER_EPS.y
        pos.y = h + border_spawn.y
    return pos

[decs(stage = update)]
def player_controller(var rotation_vel: float&; var player_acl: float&; var emitter_enabled: bool&)
    let dt = get_delta_time()

    if get_key(VK_A) || get_key(VK_D)
        if get_key(VK_A)
            rotation_vel = -PLAYER_ROTATION_VEL
        else
            rotation_vel = PLAYER_ROTATION_VEL
    else
        rotation_vel = 0.0

    if get_key(VK_W) || get_key(VK_S)
        emitter_enabled = true
        if get_key(VK_W)
            player_acl = PLAYER_ACL
        else
            player_acl = -PLAYER_ACL
    else
        player_acl = 0.0
        emitter_enabled = false

    return

[decs(stage = update)]
def move_player_ship(var pos:float2&; angle:float; player_acl:float; var player_vel: float2&)
    let dt = get_delta_time()
    let forward = get_forward(angle)
    player_vel += forward * (player_acl * dt) - player_vel * 0.5 * dt

    player_vel.x = abs(player_vel.x) < 0.1 ? 0.0 : player_vel.x
    player_vel.y = abs(player_vel.y) < 0.1 ? 0.0 : player_vel.y

    pos += player_vel * dt
    pos = respawn_if_needed(pos)
    return

[decs(stage = update)]
def rotate(var angle:float&; var rotation_vel: float&)
    angle += rotation_vel * get_delta_time()
    return

[decs(stage = update)]
def player_pew_pew(pos: float2; angle:float; size: float; var next_time_to_fire: float&; reload_time:float)
    if get_key(VK_SPACE)
        let time = get_time_after_start()
        if time > next_time_to_fire
            let start_pos = pos + get_forward(angle) * size * 1.5
            spawn_bullet(start_pos, BULLET_VEL, angle, 5.0, "bullet")
            next_time_to_fire = time + reload_time
    return

def circle_collision(center0: float2&; r0: float; center1: float2&; r1: float&)
    let dr = center1-center0
    return length_sq(dr) < pow((r0+r1)*0.8, 2.0)

def on_asteroid_death(eid: EntityId; pos:float2)
    delete_entity(eid)

    spawn_burst(pos, 20, 2.0)
    query(eid) <| $(asteroid_type: AsteroidType)
        var add_score = 0
        var newAsteroidType: AsteroidType
        var spawn_count = 0

        if asteroid_type == AsteroidType Big
            add_score = ASTEROID_BIG_SCORE
            newAsteroidType = AsteroidType Medium
            spawn_count = 2
        elif asteroid_type == AsteroidType Medium
            add_score = ASTEROID_MEDIUM_SCORE
            newAsteroidType = AsteroidType Small
            spawn_count = 2
        elif asteroid_type == AsteroidType Small
            newAsteroidType =  AsteroidType None

        if asteroid_type != AsteroidType None
            for i in range(0, spawn_count)
                spawn_asteroid(pos, newAsteroidType)

        query() <| $(var score: int&)
            score += add_score
    return

def on_bullet_death(eid: EntityId)
    delete_entity(eid)
    return

def on_player_death(eid: EntityId; pos: float2)
    delete_entity(eid)

    query() <| $(var player_lifes: int&)
        player_lifes -= 1

    create_entity() <| @(eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("player_respawn_time", get_time_after_start() + PLAYER_RESPAWN_TIME)
    return

def on_bonus_death(eid: EntityId; pos:float2)
    delete_entity(eid)

    spawn_burst(pos, 3, 5.0)

    query(eid) <| $(bonus_type: BonusType)
        if bonus_type == BonusType Health
            query() <| $(var player_lifes: int&)
                player_lifes += 1
    return

def on_death(eid: EntityId&; pos:float2&; obj_type: ObjectType&)
    if obj_type == ObjectType Asteroid
        on_asteroid_death(eid, pos)
    elif obj_type == ObjectType Bullet
        on_bullet_death(eid)
    elif obj_type == ObjectType Player
        on_player_death(eid, pos)
    elif obj_type == ObjectType Bonus
        on_bonus_death(eid, pos)
    return

[decs (stage = update)]
def check_circle_collision(eid: EntityId; pos: float2; size: float; team: int; obj_type: ObjectType; var alive:bool&)
    if !alive
        return

    let eid0 = eid
    let pos0 = pos
    let size0 = size
    let team0 = team
    let obj_type0 = obj_type
    let has_collision = find_query() <| $(eid: EntityId; pos: float2; size: float; team: int; obj_type: ObjectType; var alive:bool&)
        if eid != eid0 && team != team0
            if circle_collision(pos, size, pos0, size0)
                on_death(eid, pos, obj_type)
                on_death(eid0, pos0, obj_type0)
                alive = false
                return true
        return false
    if has_collision
        alive = false
    return

/************ INIT ***************/

// 'initialize' runs once when game starts and every hot-reload

def init_player()
    let size = float(get_screen_width()) * 0.01
    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("pos", get_map_center())
        cmp |> set("player_vel", float2(0.0, 0.0))
        cmp |> set("player_acl", 0.0)
        cmp |> set("rotation_vel", 0.0)
        cmp |> set("angle", PI)
        cmp |> set("size", size)
        cmp |> set("shape", "base_ship")
        cmp |> set("next_time_to_fire", 0.0)
        cmp |> set("reload_time", PLAYER_RELOAD_TIME)
        cmp |> set("team", 0)
        cmp |> set("obj_type", ObjectType Player)
        cmp |> set("emitter_enabled", false)
        cmp |> set("emitter_next_spawn_time", 0.0)
        cmp |> set("emitter_reload_time", ENGINE_EMITTER_RELOAD_TIME)
        cmp |> set("color", SHIP_COLOR)
        cmp |> set("alive", true)
    return

def init_stat()
    create_entity() <| @(eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("player_lifes", PLAYER_INIT_LIFES)
        cmp |> set("score", 0)
    return

def init_level()
    create_entity() <| @(eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("asteroids_respawner_enabled", true)
    create_entity() <| @(eid, cmp)
        cmp |> set("eid", eid)
        cmp |> set("bonus_next_time_spawn", BONUS_RESPAWN_TIME)
        cmp |> set("bonus_respawn_time", BONUS_RESPAWN_TIME)

[export]
def initialize
    set_window_title("something")
    randomize_seed(seed)
    init_level()
    init_stat()
    init_player()
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    decs_stage("update")
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    fill_rect(0,0, get_screen_width(), get_screen_height(), BACKGROUND_COLOR)
    text_out(get_screen_width()/2 - 100, get_screen_height()-100, "Definitely not ATARI", SHIP_COLOR )
    text_out(1, 100, "AWSD - movement", SHIP_COLOR )
    text_out(1, 120, "SPACE - shot", SHIP_COLOR )
    decs_stage("draw")
    return
