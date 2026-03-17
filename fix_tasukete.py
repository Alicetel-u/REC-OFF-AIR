import json
import os

path = r"c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR\dialogue\ch01_entrance.json"

with open(path, 'r', encoding='utf-8-sig') as f:
    data = json.load(f)

# The structure seems to be a list of events in data["events"] or direct list?
# Let's check the structure first.
if isinstance(data, dict) and "events" in data:
    events = data["events"]
elif isinstance(data, list):
    events = data
else:
    print("Unknown structure")
    exit(1)

# Find first "……ッ！" or "た...す...け...て..." and replace
# Actually, the user wants the FIRST "……ッ！" to be "た...す...け...て..." + SFX.
# Wait, I already changed some to "た...す...け...て...".
# Let's find them by text.

new_events = []
found_first = False
for ev in events:
    if ev.get("type") == "say" and (ev.get("text") == "……ッ！" or ev.get("text") == "た...す...け...て..."):
        if not found_first:
            # First one: change to "た...す...け...て..." and add SFX
            ev["text"] = "た...す...け...て..."
            ev["voice"] = ""
            new_events.append(ev)
            new_events.append({
                "type": "sfx",
                "file": "horror_voice/tasukete_new",
                "vol": -11
            })
            found_first = True
        else:
            # Second one: skip (delete)
            continue
    else:
        new_events.append(ev)

# Also remove the SFX that might have been added after the "en?" line.
# "……え、嘘。誰もいないじゃん。期待させてごめ……ん？"
final_events = []
skip_next_sfx = False
for i in range(len(new_events)):
    ev = new_events[i]
    if ev.get("type") == "say" and "え、嘘。誰もいないじゃん。期待させてごめ……ん？" in ev.get("text", ""):
        # Check next events for SFX
        final_events.append(ev)
        continue
    
    if ev.get("type") == "sfx" and ev.get("file") == "horror_voice/tasukete_new":
        # Is this the SFX we added for "tasukete"? 
        # We want to keep it if it's the one we just added (found_first).
        # But we want to remove it if it's standalone after the dialogue.
        # The one we added is preceded by its "say" event.
        if i > 0 and new_events[i-1].get("text") == "た...す...け...て...":
            final_events.append(ev)
        else:
            # Standalone or after other dialogue -> skip
            continue
    else:
        final_events.append(ev)

if isinstance(data, dict) and "events" in data:
    data["events"] = final_events
else:
    data = final_events

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Replacement complete")
