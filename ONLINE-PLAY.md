# Playing Beach Spikers online (up to 4 players)

Everyone plays on their own computer. One person **hosts**; everyone else **joins**.
In Arcade or VS mode, ports 1 and 2 start as one team and ports 3 and 4 as the
other. The host can change or shuffle the teams in the lobby before each match.

---

## 1. What everyone needs (one time)

1. **The same download** of this game from the
   [release page](https://github.com/chriswelland-svg/beach_recomp/releases).
   Everyone must use the same release. If one person updates, everyone updates.
2. **Your own copy of Beach Spikers (USA)** set up in it. Start the game once,
   pick your disc image, and let it build (a few minutes). The game must run on
   your own before you go online.
3. **A controller or the keyboard.** Pick it under **Controller profile** in the
   launcher, or with **F1 > Input** while playing.
4. **Set your own options in single player first.** Screen size, sound and team
   jerseys carry over into online games. The settings menu (F1) is off during
   online games.

## 2. How the computers find each other

| Where are you? | What to do |
|---|---|
| **Same home / same Wi-Fi** | Nothing. The host's lobby shows a `192.168.x.x` address; friends type that. |
| **Different homes (easiest)** | Everyone installs **[Tailscale](https://tailscale.com/download)** and signs up with their own free account. The host then **shares their computer** with each friend: on the Tailscale admin page, open *Machines*, pick the computer, choose **Share**, and send each friend the invite. The host's lobby then shows a `100.x.x.x` address; friends type that. (Sharing, not inviting: the free plan allows only 3 users per network.) |
| **Different homes (no extra app)** | The host forwards **UDP port 2626** on their router to their computer, then gives friends their *public* address (search "what is my IP"). |

**Firewall:** the first time you host, Windows or macOS may ask whether to allow
the game on the network. Click **Allow**, and on Windows tick both
**Private** and **Public**.

## 3. Host a game

1. Open the game and click **Play online...**
2. Type your name, choose **Host a game**, click **Open my lobby**.
3. The lobby shows **the address to give your friends**. Click **Copy** next to
   it and send it to them.
4. Wait until every friend shows up with **match** and **ready**.
5. Set the teams:
   - **Left team = ports 1 and 2**, **right team = ports 3 and 4**.
   - Use the drop-down next to a port to seat someone there. They swap with
     whoever was there.
   - **Shuffle teams** mixes everyone up at random.
   - **Swap sides** swaps the two teams.
6. Click **Start the game**.

## 4. Join a game

1. Open the game and click **Play online...**
2. Type your name, choose **Join a friend's game**.
3. Type or paste the address the host gave you, for example `192.168.1.50`, and
   click **Join the game**.
4. You are in the host's lobby, marked ready. Wait for the host to start.

## 5. Playing

- **The player on port 1 runs the menus.** The lobby shows who that is.
- **Arcade:** on the entry screen, everyone else presses **Start** to join. With
  3 or 4 players the game switches to **Match Play**: ports 1 and 2 against ports
  3 and 4.
- **VS mode:** each player presses **Start**, then picks a place on the court.
- On the game's **POSITION** screen, players can still move to the other side.
  That changes teams without going back to the lobby.
- Your jersey pictures show only on your own screen.
- The host's **Neutral ball marker** setting applies to everyone.

## 6. Changing or shuffling teams between matches

Anyone closes their game window, and **everyone goes back to the lobby**.
Nobody is disconnected. The host changes the teams (or presses **Shuffle teams**),
then **Start the game** again.

## 7. If something goes wrong

| What you see | What to do |
|---|---|
| **"Could not reach the host"** | Check that the host's lobby is open, and that the address is typed exactly as their lobby shows it. Check that you're on the same network or on their Tailscale (or that they forwarded the port). Check that the host clicked **Allow** on the firewall question. |
| **"Your game files do not match the host's"** | Everyone needs the same release *and* the USA version of the game. |
| **"The host has a different version of this download"** | Everyone downloads the latest release again. |
| **"The host already started the match"** | The host closes their game window (everyone returns to the lobby), then you join again. |
| **The game freezes mid-match** | Someone's connection dropped. After about 15–20 seconds everyone returns to the lobby, and the lobby says who left. |
| **Short slow-motion moments** | Online, everyone plays at the speed of the slowest computer and connection. Use a cable instead of Wi-Fi if you can, and close other programs. Input delay adjusts by itself. |
| **"The games drifted apart (desync)"** | The game is stopped and everyone returns to the lobby. Press Start again. If it keeps happening, check that everyone has the same release and disc. |
| **"UDP port 2626 is already in use"** | Another lobby is still open on that computer. Close it, then host again. |

Mixing Windows, Mac and Linux computers should connect, but hasn't been tested
yet. If you get desync messages in a mixed group, try playing on the same kind of
computer.
