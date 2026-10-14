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

## Where things are

| Folder | Contents |
| --- | --- |
| `entities/pacman` | Pac-Man (`Pacman`) |
| `entities/ghosts` | Shared ghost logic (`Ghost`) and one folder per ghost with its chase target (`RedGhost`, `PinkGhost`, `CyanGhost`, `OrangeGhost`) |
| `entities/pellets` | Pellets (`Pellet`), power pellets (`PowerPellet`) and their spawner |
| `entities/tunnel` | Side tunnels (ghosts slow down inside) |
| `stages/main` | The level; `stages/maze_outline.gd` draws the maze |
| `utilities/grid_2d` | Tile-by-tile movement shared by Pac-Man and the ghosts |
| `utilities/ghost_manager` | Scatter/chase schedule and ghost sounds |
| `utilities/game_manager` | Lives, levels, game mode (autoload `GM`) |
| `utilities/save_system` | Score/highscore saving (autoload `SS`) |
# PACMM
