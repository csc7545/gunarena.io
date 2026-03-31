# GunArena.io

**GunArena.io** is a fast-paced multiplayer top-down shooter built with [Flutter](https://flutter.dev/), [Flame](https://flame-engine.org/), and WebRTC.

Share a link, join the arena, and be the first to 10 kills!

> **Play now:** [https://gun-arena-io.web.app](https://gun-arena-io.web.app)

<br>

## 🎮 Game Features

- 🔫 Real-time PvP combat (2–4 players) via WebRTC DataChannel
- 🗺️ 1920x1024 wide arena with seed-based randomized obstacles (35-50)
- ❤️ HP system (100HP, 7-shot kill) with 5s respawn + 2s invincibility
- ⌨️ Keyboard controls (WASD/Arrow + Space + R) with real-time key visualizer
- 🏆 Live leaderboard with K/D tracking — first to 10 kills wins
- 🔄 Flame-based collision detection and rendering
- 🤖 Singleplayer mode with 3 AI bots
- 🔗 Link-sharing room system (no account required)

<br>

## 📡 Tech Stack

| Layer       | Tech                               |
| ----------- | ---------------------------------- |
| Game Engine | [Flame](https://flame-engine.org/) |
| UI          | Flutter Web                        |
| Network     | WebRTC P2P (DataChannel)           |
| Signaling   | Firebase Firestore                 |
| State Mgmt  | BLoC (Cubit)                       |

<br>

## 🚀 Getting Started

```bash
# Prerequisites: FVM (Flutter Version Manager)
fvm install stable

# Install dependencies
fvm flutter pub get

# Run on Chrome
fvm flutter run -d chrome

# Or with specific port
fvm flutter run -d chrome --web-hostname=localhost --web-port=3000
```

### Play

1. **Solo vs Bots**: Click "Play Solo" on the home screen
2. **Multiplayer**: Click "Create Room" → copy the share link → send to friends → start when everyone's in

<br>

## 🎮 Controls

| Action | Keyboard | Mouse/Touch |
|--------|----------|-------------|
| Move | `W` `A` `S` `D` / Arrow keys | — |
| Aim | Movement direction = aim direction | — |
| Shoot | `Space` (hold for auto-fire) | Fire button |
| Reload | `R` | Reload button |

<br>

## 🔫 Weapon Stats (AR)

| Stat | Value |
|------|-------|
| Damage | 15 per shot |
| Fire rate | 8 rounds/sec |
| Bullet speed | 400px/s |
| Range | 300px |
| Magazine | 30 rounds |
| Reload time | 2 seconds |

<br>

## 🏗️ Architecture

```
lib/
├── game/              # Flame engine (pure game logic)
│   ├── components/    # Player, Bullet, Obstacle, Map, AI
│   ├── systems/       # Spawn, Score
│   └── models/        # Game state, Player state, Weapon config
├── network/           # Networking (independent of game logic)
│   ├── signaling/     # Firebase Firestore signaling
│   ├── webrtc/        # PeerConnection + DataChannel
│   ├── protocol/      # Message types + serializer
│   └── sync/          # Host→Client state sync (20Hz)
├── application/       # BLoC layer
│   └── room/          # Room lifecycle management
└── presentation/      # UI
    ├── screens/       # Home, Lobby, Game, Result
    └── widgets/       # Key visualizer, Fire button, HUD
```

**Networking**: Host-client model over WebRTC. Host runs the simulation and broadcasts state at 20Hz. Clients send input only. Firebase Firestore handles WebRTC signaling (offer/answer/ICE exchange).

<br>

## 🔮 Roadmap

- [ ] Weapon switching
- [ ] Player skin customization
- [ ] Spectator mode
- [ ] Field-of-view fog (visibility limitation)
- [ ] Host migration
- [ ] Mobile touch controls (joystick)

<br>

---

> Made with ❤️ by [언덕](https://github.com/csc7545)
