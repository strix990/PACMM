# PacProject

A Pac-Man clone made in the Godot game engine (4.7).

Based on [Pik-Pok](https://github.com/Alexander-Jordan/pik-pok-godot) by Alexander Jordan (MIT, see `LICENSE`),
reskinned with the Pac-Man sprites and sounds from the first Godot Pac-Man tutorial
(https://www.youtube.com/watch?v=CncJvOEM3OA).

## Game modes

| Mode | Players | Controls |
| --- | --- | --- |
| **1 PLAYER** | Pac-Man vs the 4 AI ghosts | WASD or arrow keys |
| **CO-OP** | Two Pac-Men (P2 is green) vs the 4 AI ghosts; shared score and lives | P1: WASD, P2: arrow keys |
| **VERSUS** | Pac-Man vs one ghost (Red) controlled by player 2 | Pac-Man: WASD, ghost: arrow keys |

In versus, Pac-Man wins by eating every pellet and the ghost wins when Pac-Man runs out of lives.

## Character select

**CO-OP** and **VERSUS** open a character select screen. In co-op both players pick a Pac-Man skin
(they can't pick the same one); in versus player 1 picks a Pac-Man skin and player 2 picks which ghost to play.
Move with **A/D** (P1) or **←/→** (P2), lock in with **Space** / **Enter**, and press it again once both are
ready to start (clicking works too; **Esc** goes back). 1 PLAYER always uses the classic Pac-Man.

Skins: Classic, Stylish Pac, HalloPac, SharkPac and SpideyPac. The custom ones are drawn in Aseprite
(`~/Documents/Sprites/*.ase`, 32x32 frames) and converted for the game with

    python3 tools/import_skins.py ~/Documents/Sprites

which writes `entities/pacman/skins/` (16x16 in-game sheets plus full-size previews for the select screen).
Rerun it after editing the art; the skin list itself is in `entities/pacman/pacman_skins.gd`.

## Items

A **?** item box appears below the ghost house 15 s into a game, and again 15 s after someone takes it.
Every player (both Pac-Men, and the ghost in versus) can hold **one** item, shown in the HUD slot at the
bottom right; a player who is already holding one can't take the box. Use it with **Space** (P1) or **Enter** (P2).

| Box gives (20 % each) | Effect |
| --- | --- |
| Speed boost | ×1.5 speed for 5 s |
| Dash | short burst of about 4 tiles |
| Wall walk | pass through walls for 5 s (you can't leave the maze; you pop out to the nearest corridor at the end) |
| Bomb | explodes after 2 s in a + shape, 3 tiles each way (walls stop it); **hits everyone**, including you: Pac-Men die, ghosts go home as eyes |
| Stun (bad luck) | frozen for 2 s straight away, no item |

Losing a life clears held items and active effects. The numbers are constants in
`utilities/items/item_holder.gd`, `entities/items/bomb.gd` and `entities/items/item_box.gd`.

## Where things are

| Folder | Contents |
| --- | --- |
| `entities/pacman` | Pac-Man (`Pacman`) and its skins (`PacmanSkins`, `skins/`) |
| `entities/ghosts` | Shared ghost logic (`Ghost`) and one folder per ghost with its chase target (`RedGhost`, `PinkGhost`, `CyanGhost`, `OrangeGhost`) |
| `entities/pellets` | Pellets (`Pellet`), power pellets (`PowerPellet`) and their spawner |
| `entities/tunnel` | Side tunnels (ghosts slow down inside) |
| `stages/main` | The level; `stages/maze_outline.gd` draws the maze |
| `utilities/grid_2d` | Tile-by-tile movement shared by Pac-Man and the ghosts |
| `utilities/ghost_manager` | Scatter/chase schedule and ghost sounds |
| `utilities/game_manager` | Lives, levels, game mode (autoload `GM`) |
| `utilities/save_system` | Score/highscore saving (autoload `SS`) |
| `utilities/items` | Player inventory and item effects (`ItemHolder`) |
| `entities/items` | The item box and the bomb, plus the item icons |
| `ui/character_select` | The co-op / versus character select screen |
| `tools` | `import_skins.py`: converts Aseprite skins into game sprites |
# PACMM
