# Componentes 2D para juego de plataforma

## Scenes
### Dimensión en pantalla de los Niveles
2D Cámara fija (por simplicidad)
Resolucion 5670 x 10800

Guardar scenes para agrupar components de nodos

### Niveles del juego
#### Componentes
**Mapa**
- `Node2D`
	- `TileMapLayer` contiene a los TileSet
		- Background (fondo)
		- Frame (marco)
	- `TileSet` contiene las imagenes o sprites en Tiles para el juego
		- `Physics Layers` capas de fisicas para los Tiles
		- `Collision Layers` capas de colision, renombrar capas
			- Solid
			- Damage
			- Player
			- Etc
**Personaje**
- `CharacterBody2D`
- TODO

### Assets
- Sprites: PNG con imagenes de 135 x 135 pixeles
	- Mundo (fondo, cielo, vegetacion, etc)
	- Plataforma (rocas)
	- Barra de poder
	
	