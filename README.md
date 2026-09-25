# 🏎️ Retro Arcade Drift Racer (Low-Poly Style)

A fast-paced, low-poly arcade drift racing game inspired by classic 80s/90s Japanese drift racers (*Initial D*, *Inertial Drift*, *Art of Rally*).

---

## 🎮 Controls

| Key | Action |
|---|---|
| **W** or **Up Arrow** | Accelerate / Gas |
| **S** or **Down Arrow** | Brake / Reverse |
| **A** or **Left Arrow** | Steer Left |
| **D** or **Right Arrow** | Steer Right |
| **Space** or **Shift** | **DRIFT!** (Initiates power slide into turns) |
| **R** | Reset car position to start line |

---

## ⚡ Drifting & Racing Mechanics

1. **Power Sliding & Counter-Steer**:
   - Drive into a corner at speed and hold **`Space`** or **`Shift`** while steering.
   - The car whips sideways into a powerslide with angled body roll.
   - Counter-steer (steer in the opposite direction) to widen or tighten your drift angle around the apex.
2. **Polygonal White Tire Smoke**:
   - Billowing white flat-shaded polygon smoke puffs burst from both rear tires while sliding (matching the screenshot style!).
3. **Drift Boost Release**:
   - Holding a drift for >0.8 seconds and releasing grants a clean speed boost out of the corner.
4. **Retro Track Environment**:
   - Sweeping asphalt curves with solid white border lines.
   - Red and white alternating rumble-strip curbs on corners.
   - Low-poly faceted green rolling hills.
   - Low-poly blue water pond with wooden tree logs and boulders on the grassy shores.
5. **Arcade Lap Timer HUD**:
   - Bold red arcade header across the top:
     `LAP: 1` | `LAST LAP: 0:31.000` | `CURRENT LAP: 0:01.969` | `BEST LAP: 0:31.000`
   - Real-time speedometer in the bottom-right.
   - `DRIFT!` notification badge when actively sliding.

---

## 🚀 How to Launch & Play

### Option 1: Terminal
```bash
open -a /Users/jazib/Downloads/Godot.app --args --path /Users/jazib/racing-game
```

### Option 2: Inside Godot
1. Open Godot (`/Users/jazib/Downloads/Godot.app`).
2. Open `/Users/jazib/racing-game`.
3. Press **F5** (or the Play button).
