import json
import sys
from pathlib import Path


def collect_typewriter_voice_usage() -> dict[str, list[tuple[str, str]]]:
    usage: dict[str, list[tuple[str, str]]] = {}
    for path in Path("dialogue").glob("*.json"):
        data = json.loads(path.read_text(encoding="utf-8"))

        def walk(obj):
            if isinstance(obj, dict):
                if "typewriter_voice" in obj and "typewriter" in obj:
                    usage.setdefault(obj["typewriter_voice"], []).append(
                        (path.name, obj["typewriter"])
                    )
                if (
                    obj.get("type") == "horror_typewriter"
                    and obj.get("voice")
                    and obj.get("text")
                ):
                    usage.setdefault(obj["voice"], []).append((path.name, obj["text"]))
                for value in obj.values():
                    walk(value)
            elif isinstance(obj, list):
                for value in obj:
                    walk(value)

        walk(data)
    return usage


def main() -> int:
    usage = collect_typewriter_voice_usage()
    errors: list[str] = []
    for voice_path, items in sorted(usage.items()):
        texts = {text for _, text in items}
        if len(texts) > 1:
            lines = [f"{voice_path} is mapped to multiple texts:"]
            for filename, text in items:
                lines.append(f"  {filename}: {text}")
            errors.append("\n".join(lines))

    if errors:
        print("\n\n".join(errors))
        return 1

    print(f"OK: {len(usage)} typewriter voice mappings are one-to-one.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
