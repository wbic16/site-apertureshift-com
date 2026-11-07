# Anti-Viral Mechanics — design of record

Will's ruling (2026-11-07, task 33.13.12/10.16.9/6.5.9): **the games adjust after every
solution is generated.** A solution — a walkthrough, a solver output, a memorized route,
a shared answer key — must not stay valid. The moment a solution exists, the game it
solves has already moved.

## The law

**Facts are fixed; instances are perishable.**

- NEVER mutates: the truth data. Real Singular atlas coordinates, the averaging rule,
  the canonical Zap Zoom Echo lines (they are the song), the real Kardashev checkpoints
  and growth rate, the greeting, the compliance copy, the grant rules. A mutation that
  touches a fact is a bug, not a feature.
- ALWAYS mutates: the instance. Which targets, in which order, with which distractors,
  on which seed, behind which event order. A player never plays "the" level; they play
  *a* level the generator dealt.

This is also why the mechanic is honest: what is being taught (addresses, averaging,
compounding, search) is invariant under re-dealing. Only memorization is taxed.

## How a game adjusts after a solution is generated

No server exists (by design — see GRANT-PROCESS.md), so mutation is local and
generative. Three triggers, layered:

1. **Completion trigger (the ruling, literally).** Finishing a game or level IS
   generating a solution. The game increments an on-device generation counter; the
   next run is dealt from generation g+1: new targets, new round order, new
   distractors, new quest draws — recomputed from the real data by the generator,
   never hand-authored twice. Replay is a new problem, not a rerun.
2. **Epoch trigger.** Instances also derive from a public time epoch (the ISO week).
   A walkthrough published for this week's instance does not describe next week's:
   solutions expire on schedule even for players who never finish.
3. **Seed display (auditability).** Every dealt instance shows its seed + generation
   on screen ("Instance 2026-W45 · G3 · seed 7F2A"). A solution that names its seed
   can be checked against exactly that instance — and only that instance. Sharing a
   seed to play the *same* instance with a friend on the same screen is cooperation,
   and stays allowed; what dies is the canonical answer key.

Generators must be FAIR by construction, as established in the play-test pass:
distractors are other real coordinates (never perturbations of the truth — the
medoid exploit), challenge targets are brute-force-verified reachable (Place a Word
standard), pars are computed from the dealt instance (BFS/coin-change optimum), and
every dealt instance is solvable — the generator proves it at deal time or re-deals.

## Mutation surface per game

| Game | Mutates per generation | Fixed (never) |
|---|---|---|
| Tap Home (0–2) | prompt rotation only | words, addresses |
| Zap Listen Mode (0–5) | line order in free play | the 11 lines |
| Sort the Scrolls (3–5) | card draws from the word sets | addresses |
| One Number Road (3–5) | target sequences | the road, the floor of 1 |
| Echo Tiles (3–5) | distractor draws | the 6 lines |
| Nine Numbers | target deals per road (par recomputed) | the wheels, dimension unlock order |
| Word Home | round word draws + real-coordinate distractors; Duel draws re-dealt per player | atlas data, specials as tutorials |
| Zap Zoom Echo | distractor pools, line order in Encore | the 11 lines |
| Scroll Seeker | quest pairs re-drawn from the real graph (par = dealt BFS) | the 30-word map, the 5-nearest rule |
| Place a Word | word pool extended + drawn per round; scroll set stable v1 | scroll addresses, the averaging rule |
| Kardashev Climb | event deck order + event year jitter | checkpoints, rates, the honest-accounting note |
| Find It Fast | the phext itself re-seeded per round (already generative — audit to confirm) | atlas scrolls at real addresses |
| Exocortex Quest I | step-4 target scroll re-drawn from the player's own scrolls | the quest structure, the export format |
| Neuralese | scroll order, garble rounds drawn per match | the cost model, the atlas table |
| The Long Road | event/chapter text variants at dynamic gates; Council tie jitter | the 12 nodes, gauge math, endings logic |
| Your Own Archive | landmark/baseline subsets rotate | the player's own text, the merge rule |
| Runway | event deck seeded per run; flip table re-drawn within verified bands | the doctrine gates (no outreach before product) |
| The Choir | task deck generated per week; event draws | seats, resets, register rules |

## Band scaling (the brick dial, applied to virality)

Anti-viral strength rises with age, like K'Nex share: **0–5 none** (repetition is the
learning; a toddler's "solution" is the skill itself) → **6–9 light** (re-drawn targets
and distractors; structure stable) → **10–12 medium** (quests and rounds fully re-dealt
per generation) → **13+ full** (epoch instances, seed display, event-order mutation).

## Compatibility

- **Grant/XP:** stamps stamp the *game*, never the instance — re-dealing cannot
  strand a player's XP, and the claim code construction is untouched.
- **Privacy/audit:** mutation inputs are public (epoch) or on-device (generation
  counter). No tracking is introduced; GRANT-PROCESS.md's data inventory is unchanged.
- **Multiplayer:** same-screen modes share one dealt instance per session (the seed
  is the session's), so partners always face the same problem.

## Rollout

1. Batch 5 (building now): generators specified at build time — done via spec addenda.
2. Built games: retrofit edits in viral-risk order — Word Home, Scroll Seeker,
   Nine Numbers, Place a Word, Neuralese, Kardashev Climb, Zap Zoom Echo,
   The Long Road, then the 0–9 light band. Find It Fast audited first (likely
   already compliant by construction).
3. Hub: displays the current epoch on the Road Card ("This week's instances:
   2026-W45") so the moving target is visible, not sneaky.
