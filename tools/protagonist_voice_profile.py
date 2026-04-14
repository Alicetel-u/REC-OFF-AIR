"""Canonical protagonist voice profile.

All protagonist-facing narration, including choice readouts, must use this
shared definition instead of hard-coded speaker/model values in each script.
"""

VOICEVOX_URL = "http://127.0.0.1:50021"
VOICEVOX_SPEAKER_ID = 20
VOICEVOX_SPEED_SCALE = 1.25
VOICEVOX_INTONATION_SCALE = 1.5
VOICEVOX_PITCH_SCALE = 0.02
VOICEVOX_MAX_PAUSE_LENGTH = 0.15
VOICEVOX_PRE_PHONEME_LENGTH = 0.05
VOICEVOX_POST_PHONEME_LENGTH = 0.05

SBV2_URL = "http://127.0.0.1:5000"
SBV2_MODEL = "jvnv-F2-jp"
SBV2_STYLE = "Fear"
SBV2_LENGTH = 0.8
SBV2_SDP_RATIO = 0.2
SBV2_NOISE = 0.6
SBV2_NOISEW = 0.8


def voicevox_profile_summary() -> str:
    return (
        "VOICEVOX speaker=%d speed=%.2f intonation=%.2f pitch=%.2f"
        % (
            VOICEVOX_SPEAKER_ID,
            VOICEVOX_SPEED_SCALE,
            VOICEVOX_INTONATION_SCALE,
            VOICEVOX_PITCH_SCALE,
        )
    )


def sbv2_profile_summary() -> str:
    return (
        "SBV2 model=%s style=%s length=%.2f sdp_ratio=%.2f noise=%.2f noisew=%.2f"
        % (
            SBV2_MODEL,
            SBV2_STYLE,
            SBV2_LENGTH,
            SBV2_SDP_RATIO,
            SBV2_NOISE,
            SBV2_NOISEW,
        )
    )
