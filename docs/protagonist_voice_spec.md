# Protagonist Voice Spec

## Rule

- Any line spoken by the protagonist must use one canonical voice profile.
- This includes normal dialogue, monologue, ending narration, and accessibility readouts such as `qa_*` choice prompts.
- Choice-readout audio is not an exception path. If the protagonist is reading it, it must use the protagonist profile.

## Source Of Truth

- The only source of truth for the protagonist voice profile is `tools/protagonist_voice_profile.py`.
- Generation scripts must import that module instead of hard-coding `Speaker ID`, `model`, or `style`.
- A protagonist voice change is a spec change and must appear as a diff in `tools/protagonist_voice_profile.py`.

## Operational Guardrail

- `tools/gen_ending_voices.py` now imports the canonical profile and refuses to run if the effective speaker does not match it.
- Any future script that generates protagonist audio should follow the same pattern.
