**Test build — not an official release.** This build packages
[kobayashi90/beach_recomp](https://github.com/kobayashi90/beach_recomp) (upstream commit `22495fd`)
plus this fork's fixes (ModernGekko
[`9d3b041`](https://github.com/chriswelland-svg/ModernGekko/commit/9d3b041157ab55873f9b50ea40da31e22eb90527))
for Windows, macOS (Apple Silicon) and Linux. All credit for the recompilation goes to
kobayashi90, and to ExpansionPak for
[DolRecomp](https://github.com/ExpansionPak/DolRecomp) and
[ModernGekko](https://github.com/ExpansionPak/ModernGekko).

It is newer than upstream's 1.0.8 release. It adds dual-core on by default, cross-chunk
call chaining and dispatch pruning in the module it builds, and an embedded gamepad
database.

### New in this build
- **Windows: the game module now builds without your own CMake.** Earlier Windows
  downloads stopped right after the recompiler step with
  `failed to launch command: Windows error 2`, because the bundled CMake was never found.
  If that happened to you, download this build, unzip it, and run it again.
- **Online play for up to 4 players** (USA disc): **Play online...** in the launcher. See
  [ONLINE-PLAY.md](https://github.com/chriswelland-svg/beach_recomp/blob/main/ONLINE-PLAY.md)
  for the step-by-step guide. Everyone in a game must use the same release.

Also in this build, from the 2026-11-22 test builds:
- **Local multiplayer fix:** controllers on ports 2–4 now reach the game.
- **New gameplay option:** a neutral ball marker for two-human teams (F1 → Gameplay).
- **Team jerseys:** put your own picture on a team's uniform (F1 → Jersey).
- **Smoother first match on the USA disc:** far fewer slow-path fallbacks on a fresh boot.

### You need your own copy of the game
These packages contain **no game code or data**. On first run the launcher asks for
**your own legally-owned disc image** of *Beach Spikers: Virtua Beach Volleyball*
(GameCube) as an ISO, RVZ or WBFS file. It extracts the image, then builds the
recompiled game module **on your machine**. NTSC-U (`GBSE8P`), PAL (`GBSP8P`) and
NTSC-J (`GBSJ8P`) are supported.

### Windows — `BeachSpikers-Windows.zip`
1. Unzip it to a folder.
2. Run **Beach Spikers.exe**.
3. Pick your disc image, then let it build the module. A compiler and CMake are bundled,
   and the first build takes about 10–25 minutes.
4. The Windows build is **experimental**. It builds and boots, but it hasn't had long
   play sessions yet.

### macOS (Apple Silicon M1–M4) — `BeachSpikers-macOS.tar.gz`
1. Install Apple's command-line tools if you don't have them: `xcode-select --install`.
2. Unpack it: `tar xzf BeachSpikers-macOS.tar.gz`.
3. The binaries are not signed, so allow them with
   `xattr -dr com.apple.quarantine BeachSpikers-macOS`.
4. Run `./BeachSpikers-macOS/"Beach Spikers"`, pick your disc image, and let it build
   the module (a few minutes).
5. The macOS build is **untested**.

### Linux — `BeachSpikers-*-x86_64.AppImage`
`chmod +x` the AppImage, run it, and pick your disc image. Building the module needs
gcc or clang.

### Online play (up to 4 players)
**Play online...** in the launcher opens a short wizard: your name, then
**Host a game** or **Join a friend's game** (with the address the host's lobby shows).
In the lobby, the host sees the address to give friends, seats players on the two teams
(ports 1–2 against ports 3–4), and can **Shuffle teams** or **Swap sides** before each
match. Everyone needs this same release and their own USA disc set up in it.
Playing from different homes (Tailscale or port forwarding) and what each error means
are covered in
[ONLINE-PLAY.md](https://github.com/chriswelland-svg/beach_recomp/blob/main/ONLINE-PLAY.md).

### Controllers
- **Choosing a pad:** plug it in, press **F1 → Input**, and pick it for Port 1. Ports 2–4
  work the same way for multiplayer, and changes apply immediately. The launcher's
  first-run screen also offers any connected pad.
- **Tested here with virtual pads:**
  - Xbox 360/One-style (XInput layout)
  - PlayStation 4/5-style
  - Nintendo Switch Pro (uses the printed labels: A = A, B = B)
  - generic USB pads from the community database (about 2,300 mappings)
  - unknown pads: they get a best-effort default with A/B/X/Y on buttons 1–4, sticks,
    D-pad and Start
- **Default layout (Xbox naming):**
  - Bottom face button = A, right = B, left = X, top = Y.
  - RB = Z, LT/RT = L/R (analog), Start = Start.
  - Left stick = stick, right stick = C-stick, D-pad = D-pad.
- **GameCube controllers through a USB adapter:** these should map 1:1, but they're
  **untested**. On Windows the official adapter needs the WinUSB driver (Zadig). macOS
  support for the adapter is unlikely in this build.
- **No button-remapping screen yet.** If your pad's buttons come out wrong, report the pad
  model.

### Gameplay option: neutral ball marker (USA disc only)
**F1 → Gameplay → "Neutral ball marker for human teams"** (off by default).

The ring on the sand where the ball will land normally takes the colour of the player the
game picks to play it. With this option on, when both players on a team are human:
- The **serve-receive** ring keeps its colour.
- From the **first touch after the serve**, the ring is a neutral grey for the rest of
  the rally, so the two of you decide who goes for the ball.
- The 1P/2P arrows over the players keep their colours.
- Teams with a COM partner keep the coloured ring.

It applies immediately and is saved with your settings. It's only on the NTSC-U disc
(`GBSE8P`) for now; on PAL and NTSC-J the Gameplay tab says so.

### Team jerseys: your own picture on a uniform
**F1 → Jersey:**
1. Pick a team. Any of the 16 national teams works.
2. Press **Choose picture...** and pick an image. PNG, JPEG, BMP and GIF all work.
   - You can also type the image's full path and press Enter.
3. Close the menu. Both players of that team now wear the picture on the front and the
   back of their top.
   - The tick boxes choose front, back, or both.
   - **Remove picture** puts the team's own uniform back.

Notes:
- A logo with a transparent background looks best; a photo shows as a patch.
- Each team can have its own picture, and the choice is saved with your settings.
- It works in every mode, and also when the computer plays that team.
- The picture is drawn onto the team's uniform texture from your own game files and
  saved as an HD texture-pack file in your user folder. Nothing of the game is in the
  download.
- In fullscreen the file dialog can open behind the game window.
- Tested on the USA disc. PAL and NTSC-J should work the same way, but haven't been
  tested yet.

### Playing
- **F1** opens the settings menu: resolution, graphics backend, controller per port,
  audio, savestates, cheats, gameplay options, team jerseys and widescreen. **ESC** closes
  it. It is off during online games.
- With no controller, the keyboard works as a pad:
  - Arrow keys: stick. Space: A. Left Shift: B. Enter: Start.
  - Q / E: L / R. W / A / S / D: C-stick.
- Settings and saves are stored in your user folder: `~/.local/share/moderngekko` on
  Linux, and the platform equivalent on other systems.

### Reporting problems
Please include your OS, CPU and GPU, your disc region, and the module-build log if the
build failed. That log is `Logs/module-build.log` in the user folder.
