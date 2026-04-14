# Typewriter Voice Spec

- Typewriter audio must be dedicated per displayed string.
- Reusing one `tw_*` file for different texts is not allowed.
- Prefer descriptive filenames such as `tw_cp3_viewers_one.wav` over ambiguous sequence names.
- `typewriter` and `horror_typewriter` should both follow the same rule.
- Run `python tools/validate_typewriter_voice_mapping.py` after editing dialogue or adding typewriter audio.
