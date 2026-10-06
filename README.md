# PacProject

A Pac-Man clone made in the Godot game engine (4.7).

Based on [Pik-Pok](https://github.com/Alexander-Jordan/pik-pok-godot) by Alexander Jordan (MIT, see `LICENSE`),
reskinned with the Pac-Man sprites and sounds from the first Godot Pac-Man tutorial
(https://www.youtube.com/watch?v=CncJvOEM3OA).

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
