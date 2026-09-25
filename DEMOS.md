# Run demos

Run recording starts automatically and exists in memory only until completion.
Loading a save truncates the abandoned attempt. Pausing or watching a demo adds
no frames. Disconnecting discards unfinished recordings; restoring a run from
another connection does not make it eligible for a complete-run demo.

`!demo` / `!demo wt`: walkthrough for the current checkpoint and FPS category.
`!demo sr`: fastest compatible recording. `!demo rpg` / `!demo low`: lowest
RPG-jump count, then time. `!demo stop` returns to the original run state.
Playback loops by default (`!demoloop off` disables looping). Leaderboard names
are clickable and play that retained run in full. Old or superseded leaderboard
rows may have no recording. Clip recording/playback remains a separate feature.

Non-any-percent segments span the current checkpoint to the next landing.
Any-percent segments select a passage within 256 units, ending after 0.5 seconds
of sustained ground contact; short bunny-hop contacts remain in the segment.
If no passage is nearby, the whole run plays. With multiple routes, select a
route before requesting a contextual demo.

## Shared storage

Apply server-db migration `004-shared-demos.sql` before enabling recording.
`demoRuns` holds metadata; `demoWinners` references category winners; `demoChunks`
holds the single compressed payload shared by those categories. All servers
using this database can play the same recordings; no shared filesystem is needed.
Unreferenced superseded payloads are deleted transactionally. Incomplete uploads
older than seven days are removed on map initialization. Existing checkpoint and
leaderboard records are not removed by demo retention.

Selection admits only modes allowed by the requester. Time (or RPG jumps) wins
first; ties prefer fewer assistance modes, then the simpler FPS category. Clean
walkthroughs have separate 125/mix categories and exclude any%, elevator,
halfbeat, TAS and hax FPS. Checkpoint-authorized doubles are clean.

The OCJ1 wire format stores 64 frames per zlib chunk: a four-byte magic and
little-endian uint32 count, followed by 27 bytes per frame (float32 XYZ,
uint16 turn angles, flags, FPS, int32 checkpoint ID and one byte of event bits).
Frame sampling is 20 Hz. Positions retain float precision; angles have the
engine's 16-bit turn precision. Raw payload is about 1.85 MiB per hour before
compression. Hex is transport only, never persisted. Loads fetch eight chunks
at a time; cached native frames are freed after the last viewer. Native recording
and playback allocations share a 128 MiB growth budget and 128 recording slots;
allocation failures stop the affected demo, not the player's run.

`dev-tools/tests/demos.gsc` exercises the codec, long recordings, rewinds,
segment selection, SQL retention and real test-client playback. It refuses to
run outside its explicitly named isolated test database.

Automatic run capture pauses while the player is marked AFK. The in-memory recording is retained for that session and resumes only while the player is still in an eligible run; AFK time adds no frames, including through forced capture.

## Recorded presentation (OCJ2)

New CoD4 run recordings retain the actual weapon, stance/input/movement flags,
viewmodel animation and timing, camera height, ADS, velocity, ladder direction,
sprint timing and mantle presentation. Weapon names appear only on changes and
at each chunk's first detailed frame, so chunks remain independently decodable
and backward seeks do not rely on whatever weapon was played last. OCJ1 payloads
remain readable; they cannot recover visual detail absent from their recording.

Velocity uses three signed 16-bit components at quarter-unit precision (six bytes
per frame). The speedometer uses recorded velocity and the viewer's visibility
setting. Legacy recordings hide it. Playback maximum speed is separate from the
run's original value, which is restored on exit.

Playback applies presentation while linked and weapons-disabled, and never feeds
recorded fire inputs into weapon simulation. RPG firing animates the viewmodel
and plays the weapon definition's local fire sound once during forward playback;
ordinary gun firing is omitted. No gameplay rocket is spawned. Inventory, ammo,
weapon state, movement presentation and the original run state are restored on
exit. Format changes require a server rebuild; no client asset rebuild is needed.

Detailed playback freezes live input and drives the recorded weapon animation directly. It does not replay weapon-state timers through weapon simulation: this prevents both disableWeapons lowering the viewmodel to none and recorded RPG delays firing real missiles. The previous frozen-controls and weapon-disable state are restored on exit.

Detailed playback uses the client spectator-interpolation flag for the recorded view instead of predicting viewer input. The previous flag is restored on exit. New recordings use OCJ3 and store the original landing surface and impact strength only on landing frames (two extra bytes before compression). Playback emits normal landing events for the camera dip and landing sound; damaging landing events are converted to presentation-only impacts. OCJ1/OCJ2 recordings remain readable, but need a new recording to gain landing impacts. Loads and teleports mark interpolation cuts; ordinary stationary pauses are retained. Landing events are not replayed while paused, seeking, or on a load boundary.


Playback controls: Melee toggles pause; each strafe-left/right press steps through
-4x, -2x, -1x, 1x, 2x, 4x. Lean-left/right selects the previous/next recorded
checkpoint boundary for non-any-percent runs. Previous always selects the preceding checkpoint, even during a jump.
Reverse pauses at the start and resets to forward 1x for the next Play. Navigation
from a local jump segment opens the full recording timeline, and preserves pause.
Load still exits to the original run. Commands `!demo pause`, `!demo resume`,
`!demo speed -2`, `!demo previous` and `!demo next` provide bindable alternatives.
The time display describes retained recording time (20 frames/second), not
leaderboard time that may include discarded attempts. The normal progress bar
is hidden during playback and restored on exit.
No keybind text HUD is created. On CoD4 a transparent mouse menu opens automatically with Pause/Resume, all
six signed speeds, checkpoint navigation, and Exit Demo. Escape hides/reopens
the controls. The menu requires the rebuilt mod.ff; keyboard controls remain
available while the menu is closed. Menu responses are ignored outside playback.
