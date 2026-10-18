# 🎮 Dev Guidelines – Game Jam Project

Documento de convenciones y estructura de carpetas para el proyecto.  
**Sigue estas reglas para mantener el proyecto limpio, consistente y fácil de trabajar en equipo.**

---

## 1. Estructura de Carpetas
```
proyecto/
├── .gitignore
├── .gitattributes
├── README.md
├── project.godot
├── icon.svg
│
├── assets/                     # Recursos "crudos" (arte, sonido, etc.)
│   ├── art/
│   │   ├── characters/
│   │   ├── environment/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── shaders/
│
├── scenes/                     # Todas las escenas (.tscn)
│   ├── characters/
│   ├── levels/
│   ├── ui/
│   ├── effects/
│   └── main.tscn               # Escena principal (o en la raíz)
│
├── scripts/                    # Scripts (.gd)
│   ├── characters/
│   ├── systems/                # Managers, GameManager, SaveSystem, etc.
│   ├── ui/
│   └── components/             # Scripts reutilizables
│
├── resources/                  # Recursos de Godot (.tres, materials, themes...)
│   ├── items/
│   ├── themes/
│   └── data/
│
├── autoload/                   # Scripts que se usan como Autoload (singletons)
│
└── addons/                     # Plugins de terceros (Asset Library)
```

### Notas sobre la estructura
- Agrupa los assets **cerca de las escenas** que los usan cuando el proyecto crezca.
- Si una feature crece mucho (ej: Player), puedes crear una carpeta propia:
	scenes/player/
├── player.tscn
├── player.gd
└── ...

- **Nunca** dejes archivos sueltos en la raíz del proyecto (excepto `project.godot`, `icon` y archivos de configuración).

---

## 2. Convenciones de Nombres

| Elemento                    | Convención          | Ejemplo                          |
|----------------------------|---------------------|----------------------------------|
| Carpetas y archivos        | `snake_case`        | `player_controller.gd`, `main_menu/` |
| Nombres de nodos           | `PascalCase`        | `Player`, `HealthBar`, `GameManager` |
| `class_name`               | `PascalCase`        | `class_name PlayerController`    |
| Variables y funciones      | `snake_case`        | `move_speed`, `take_damage()`    |
| Constantes                 | `CONSTANT_CASE`     | `MAX_HEALTH`, `JUMP_FORCE`       |
| Señales                    | `snake_case` (pasado o evento) | `died`, `score_changed`, `hit_received` |
| Escenas reutilizables      | `snake_case.tscn`   | `player.tscn`, `enemy_slime.tscn`|
| Recursos (.tres)           | `snake_case.tres`   | `health_potion.tres`             |

### Reglas importantes
- **Nunca uses espacios** ni caracteres especiales en nombres de archivos/carpetas.
- Usa **solo minúsculas + guiones bajos** para archivos y carpetas (evita problemas de case-sensitivity entre Windows/macOS/Linux).
- Los scripts deben tener el **mismo nombre** que la escena a la que pertenecen cuando sea posible (`player.tscn` → `player.gd`).

---

## 3. Buenas Prácticas Generales

### Escenas y Scripts
- Una escena = un archivo `.tscn`.
- Prefiere **composición** sobre herencia compleja.
- Los scripts de control van en el nodo raíz de la escena.
- Usa señales para comunicarte entre nodos (evita `get_node()` excesivos).

### Autoloads (Singletons)
- Coloca los scripts de Autoload en la carpeta `autoload/`.
- Nómbralos de forma clara: `GameManager`, `AudioManager`, `EventBus`, `SaveSystem`, etc.
- Regístralos en **Project → Project Settings → Autoload**.

### Assets
- Organiza los assets por categoría (`art/characters`, `audio/sfx`, etc.).
- Si un asset es de terceros, considera dejar constancia de la licencia en un archivo `LICENSE.txt` dentro de la carpeta correspondiente o en `addons/`.

### Recursos (.tres)
- Guarda materiales, themes, datos de items, stats, etc. en `resources/`.
- No uses archivos binarios innecesarios cuando se pueda usar formato de texto (`.tres`).

---

## 4. Git & Colaboración

### Archivos que **NO** deben subirse
El `.gitignore` ya está configurado para ignorar:
- `.godot/`
- Archivos de export y credenciales
- Archivos temporales del sistema e IDEs

### Flujo de trabajo recomendado
1. Trabaja siempre en una **branch** (`feature/nombre` o `fix/descripcion`).
2. Haz commits frecuentes y con mensajes claros.
3. Antes de hacer merge a `main`, asegúrate de que el proyecto abre y corre sin errores.
4. Evita subir archivos generados o temporales.

### Mensajes de commit (sugerencia)
feat: agregar movimiento del jugador
fix: corregir colisión con enemigos
refactor: reorganizar scripts de UI
docs: actualizar README

---

## 5. Checklist rápido antes de subir cambios

- [ ] ¿Los archivos nuevos están en la carpeta correcta?
- [ ] ¿Los nombres siguen las convenciones (`snake_case` / `PascalCase`)?
- [ ] ¿El proyecto abre y corre sin errores?
- [ ] ¿Se generaron archivos basura (`.tmp`, `.import`, etc.)? → No los subas
- [ ] ¿El commit tiene un mensaje claro?

## 6. Comandos básicos de Git

### Paso 0 - Clonar el repositorio
```bash
git clone https://github.com/USUARIO/NOMBRE-DEL-REPO.git
cd NOMBRE-DEL-REPO
```
### Paso 1 - Crear y cambiar de branch
```
# Crear una nueva branch y cambiarse a ella
git checkout -b feature/nombre-de-la-feature

# O usando el comando más moderno
git switch -c feature/nombre-de-la-feature

# Ver en qué branch estás
git branch

# Cambiar a una branch existente
git switch nombre-de-la-branch
```

### Paso 2 - Hacer commits (un branch puede tener muchos commits)
```
# Ver el estado de los archivos
git status

# Agregar archivos específicos
git add archivo1.gd carpeta/

# Agregar todos los cambios
git add .

# Crear el commit
git commit -m "feat: descripción clara del cambio"
```
### Paso 3 - Subir cambios (push)
```
# Primera vez que subes la branch
git push -u origin nombre-de-la-branch

# Las siguientes veces
git push
```
### Paso 4 - Actualizar tu branch con los cambios de main (cuando se necesite)
```
git switch main
git pull
git switch tu-branch
git merge main
```
---

**Última actualización:** Octubre 2026  
Cualquier duda o propuesta de cambio, coméntenlo en el grupo.
