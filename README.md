# Sunny Paws Pet Sanctuary

A cozy 3D pet-sanctuary game (Godot 4.7) that teaches children to manage big
feelings by having them **teach the pets**. Built for a 7-year-old on a tablet;
also runs on desktop.

## Run it

```bash
godot --path .
```

First time only (imports the assets): `godot --headless --import`

Controls: tap things. Slide to look around, pinch (or mouse wheel) to zoom.

## What the child does

- Runs the sanctuary: pet, feed, play fetch and dance with the pets, grow a
  garden, and play four mini-games (Snack Time memory orders, Block Tower,
  Match Cards, Hide & Seek in the 3D world).
- Earns hearts, which welcome new pets (24 in all).
- Every few minutes a pet gets a storm cloud over its head: a **feelings
  moment**. The child coaches the pet through it.

## How it teaches (the part the child doesn't see)

Each feelings moment walks the same steps a child therapist teaches in CBT:

1. **Name it** - pick the pet's feeling from three faces.
2. **Find it in the body** - hot face, tight paws, fluttery tummy...
3. **Size it** - a 1-5 feeling thermometer.
4. **Calm the body first** - the pet blurts a "stormy thought" and an unsafe
   urge. The child chooses between the urge and a calm-down tool. Picking the
   urge is never punished: the game *imagines* what would happen next, the
   thermometer rises, and the child chooses again.
5. **Do the tool together** - an interactive exercise the child physically
   paces (hold to breathe in for 4s, release for a 6s out-breath, and so on).
   Big feelings need a second tool: one is not always enough.
6. **Think, then solve** - swap the stormy thought for a helpful one, then pick
   a real solution (use words, ask for help, try again).
7. **"How about YOU?"** - sometimes the game asks the child their own feeling
   size and offers to do a tool for them.

Tools move through stages: **Learning** (guided) -> **Practicing** (child
leads) -> **Learned** (the pet asks for the tool itself and the child simply
practices along). Only one new tool is being learned at a time.

**Tricky moments.** Knowing the answer while calm is the easy part. So
mini-games sometimes go wrong on purpose (wind knocks the tower down, the cards
get mixed up). The buddy pet is frustrated too; they calm down together, with a
bit of real frustration in the room, then get a fair retry. Frequency is set in
the grown-ups menu (Off / Gentle / Medium / Lots; default Gentle).

### The tools and where they come from

| Tool | Technique | Basis |
| --- | --- | --- |
| Balloon Breaths | Slow breathing, longer out-breath | Standard CBT relaxation skill; arousal-lowering activities reduce anger (Kjaervik & Bushman 2024) |
| Slow Count to 10 | Response delay | Same meta-analysis; anger-control training |
| Turtle Shell | Stop, tuck, breathe, think | Turtle Technique from the PATHS curriculum |
| Squeeze and Melt | Progressive muscle relaxation | CBT relaxation training |
| Glitter Jar Break | Self-chosen calm-down break with a mindful focus | Time-away / mindfulness |
| Look Around | Sensory grounding (5-4-3-2-1 style) | Widely used clinically for anxiety; direct trial evidence is thin |
| Helpful Thoughts | Cognitive reappraisal, coping self-talk | Core of child CBT, e.g. Coping Cat |
| Slow Stretch | Slow, gentle movement | Calming movement lowers anger; hard exercise in the moment does not |

Also built in: naming feelings (affect labeling), consequential thinking, and
problem-solving steps. **Deliberately left out:** venting (hitting pillows,
yelling). Studies keep finding it sustains anger.

Honest limits: the evidence is for these techniques taught by people, mostly in
therapy or school programs, not for this game. Staging frustration and then
practicing coping follows the logic of stress-inoculation and the RAGE-Control
biofeedback game, but that research is small. The game is practice, not
treatment. The in-game grown-ups Guide says the same and gives tips for
carrying the skills into real life (use the game's words: "Want to do Balloon
Breaths like Biscuit?").

Sources:
[Kjaervik & Bushman 2024 (coverage)](https://www.sciencealert.com/venting-doesnt-reduce-anger-but-something-else-does-study-reveals) -
[Bushman 2002, venting](https://public.websites.umich.edu/~bbushman/PSPB02.pdf) -
[CBT for anger in children, meta-analysis](https://www.ojp.gov/ncjrs/virtual-library/abstracts/cognitive-behavioral-therapy-anger-children-and-adolescents-meta) -
[PATHS evidence rating](https://crimesolutions.ojp.gov/ratedprograms/193) -
[Turtle Technique handout](https://csefel.vanderbilt.edu/modules/module2/handout7.pdf) -
[Coping Cat](https://www.cde.state.co.us/healthandwellness/mhrb/copingcat) -
[Protege effect, Chase et al. 2009](https://link.springer.com/doi/10.1007/s10956-009-9180-4) -
[RAGE-Control trial](https://www.eurekalert.org/news-releases/930620) -
[Affect labeling](https://ggia.berkeley.edu/practice/naming_your_emotions)

## Grown-ups menu

Settings (gear) -> Grown-ups. Guarded by a multiplication question, or a
4-digit PIN once you set one.

- **Guide** - how the game teaches and how to reinforce it at home.
- **Skills** - set each tool to Not yet / Learning / Practicing / Learned;
  switch automatic progression on or off.
- **Child Settings** - tricky-moment frequency, how often pets need help,
  which feelings to include, the "how about you?" check-in, play-time reminder.
- **Progress** - practice counts, first-try accuracy, tool-vs-urge choices,
  and the child's own feeling check-ins.
- **Saves & PIN** - three save slots. Deleting is only possible here, and a
  deleted save goes to a recycle bin it can be restored from.

Saves autosave every 20 seconds and on exit, written atomically with a backup
copy that is used if the main file is damaged.

## Code layout

```
core/        pure logic, no engine nodes: content, save data, director, save store, adult gate
autoload/    Game (state + saving), Sfx (sound, music, read-aloud)
ui/          theme + widgets, title, settings, grown-ups menu, toolbox
world/       3D sanctuary, pets, HUD, director loop
feelings/    the feelings-moment flow and the eight tool exercises
activities/  mini-games and garden
tests/       unit tests and the end-to-end autopilot
```

## Tests

```bash
godot --headless -s tests/run_tests.gd
```

Unit tests for all the logic, including a 120-moment playthrough with no
engine nodes.

```bash
godot --headless -- --autopilot
```

End-to-end: drives the real game through every screen, tool, mini-game,
setback and the grown-ups menu using a throwaway save folder. Run it windowed
with `-- --autopilot=/some/folder` to also save a screenshot of every step and
check real mouse/touch input.

## Notes

- Text uses a rounded system font (Arial Rounded on Apple devices) and falls
  back to the platform default elsewhere.
- Read-aloud uses the device's text-to-speech and is on by default.
- Binary assets (models, images, audio) are stored with Git LFS: run
  `git lfs install` once before cloning.

## Builds and releases

Every commit to `main` runs `.github/workflows/release.yml`: it runs the unit
tests and the end-to-end smoke test, exports an Android APK plus Windows,
Linux and macOS builds, and publishes them as a GitHub release tagged
`build-<number>`.

**APK signing.** For a new APK to install over the old one (and keep save
files) every build must be signed with the same key. Set three repository
secrets: `ANDROID_KEYSTORE_BASE64` (the keystore file, base64-encoded),
`ANDROID_KEYSTORE_ALIAS` and `ANDROID_KEYSTORE_PASSWORD`. Without them the
workflow still builds, but signs with a throwaway key each time.

Local export: presets live in `export_presets.cfg` (Android, Windows, Linux,
macOS), for example `godot --headless --export-release Android build/android/SunnyPaws.apk`.

## Credits

3D models, icons, sounds and music by [Kenney](https://kenney.nl) (CC0):
Cube Pets, Nature Kit, Food Kit, Interface Sounds, Impact Sounds, Music
Jingles, Music Loops.
