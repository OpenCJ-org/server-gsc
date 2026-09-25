# Checkpoint editor

## Splits, merges and shared sections

Resume the opening with `!cp start normal`. Confirm its last shared landing,
then use `!cp split easy hard` (up to 16 route names are supported). The editor
opens Easy. Use `!cp start hard` to resume Hard at its latest section; an empty
section places you at its incoming shared landing.

You may finish Easy before discovering where Hard joins it. While building
Hard, Detect on an existing Easy landing highlights that checkpoint and explains
`!cp merge easy hard`. Run it before confirming the duplicate. Hard's approach
joins that exact checkpoint, reusing Easy's saved continuation and Finish. The
editor opens at the join, not at the end. For several existing continuations,
the first named existing route supplies the path for the new arrivals; existing
routes keep their later divergences.

If the paths separate again, stand on the last shared checkpoint and use Detect
(or select its section index with `!cp edit N`). Detect selects an existing shared
checkpoint rather than overwriting it. `!cp split easy hard` keeps Easy's existing
continuation and opens a fresh Hard branch there. The first argument keeps the
existing path; the remaining arguments receive new branches. Those branches can
merge back into an existing section or Finish later.

When neither continuation exists yet, you can still checkpoint the separate
approaches, Detect their first common landing, then merge and author the shared
section once. Multiple routes are supported. Include every route already using
an incoming/shared section. Published data is not changed by draft merge/split
operations. Finalization may reuse an identical recorded route, but still rejects
changes to its recorded geometry, grouping or requirements.

Overlapping areas are highlighted in orange/red. Confirmation of duplicate
sections is blocked, with guidance to merge at the joining landing and split at
the later divergence. Original section files are retained as recovery snapshots;
the network manifest selects the active versions.

`!cp rename normal combined` renames the shared opening without renaming Easy or
Hard. `!cp rename easy <newName>` renames that route instead. Names cannot collide
with another draft or published route. Colors, checkpoint IDs, player statistics
and demo payloads are preserved; published route/demo name references are updated
together in a database transaction. Retired draft names have `.renamed` recovery
snapshots. A rename requires CPC mode; it does not finalize unfinished drafts.

The HUD identifies every route sharing the current section and counts section
checkpoints. Incoming connections use their section colors. Shared sections keep
the opening's explicit color (cyan for default `normal`); exclusive sections use
route colors. The colors match gameplay markers.

Complete all branches, mark their finishes (a shared finish is also supported),
and `!cp finalize` publishes the whole network in one database transaction.
Publication requires migration `005-checkpoint-sections.sql`. Shared sections are
stored once as ordinary section draft files. The alternating CPN1 manifest files
record each route's ordered section references. Both the manifest **and all
referenced section drafts** must be retained for recovery; finalizing deletes none.

The runtime keeps the original shared opening once. After the fork, publishing
expands sections into route-specific logical checkpoint chains so existing
leaderboard and demo records remain unambiguous through merges. Section colors
are stored once in `checkpointSectionColors`, referenced by checkpoint areas.
Passing a coincident checkpoint prioritizes the expected next step. Standing on
it cannot accidentally trigger another route's copy on the following frame.
Taking a different route's later branch enables any% with a route-change message.

World markers use the original arrow with exact RGB tint, at half the previous
marker size. Minimap objectives use matching materials for the default route
palette. The stock compass has no RGB field: custom hex colors use the nearest
palette color on the minimap, while world arrows retain their exact tint.

## Legacy drafts

CPC2-CPC5 drafts remain readable. CPC6 preserves a legacy branch's shared-opening
color. Existing legacy branch drafts still publish through the previous guarded
publisher; they are not silently converted into section networks.

## Discarding and editing

`!cp discard` (Numpad Delete) discards a pending new checkpoint, or removes the
latest confirmed checkpoint if no new selection is pending. It always targets
the latest checkpoint, even when an older one is selected. Numpad Minus / `!cp
undo` restores the change during the current editing session. Shared opening
checkpoints remain protected. These actions edit the draft, not published data.

`!cp edit last` or `!cp edit <number>` selects a confirmed checkpoint. To mark
it as a finish, press Numpad 9 and then Numpad Enter (or `!cp finish`, then
`!cp confirm`). From the empty next slot, Numpad 4 also selects the last saved
checkpoint. Editing updates that checkpoint instead of appending a new one.

### Following an existing shared section

After merging into a completed route, the editor stays at the joining checkpoint.
When you land on any existing checkpoint in that shared section, it is selected
and highlighted automatically, including alternative areas. The panel identifies
where you are. The next existing checkpoint has a numbered cyan boundary and a
yellow center-to-center connection; a finish is explicitly labeled FINISH.
You do not need to recreate, detect or reconfirm existing checkpoints. Confirm
saves edits without jumping to the end. Automatic selection preserves pending edits.

If you land outside the existing checkpoints, the panel says so and retains the
last shared checkpoint as the split point. Detect also warns without overwriting
shared geometry. Use `!cp split easy hard`: Easy keeps its existing continuation
and Hard opens a new branch. Then detect the different landing again. Include all
sharing route names when more than two routes share the section; the first keeps
its continuation. Only finalize when you have verified the finish for your route.
