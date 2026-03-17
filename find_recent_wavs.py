
import os
import datetime

def find_recent_wavs():
    now = datetime.datetime.now()
    one_day_ago = now - datetime.timedelta(days=1)
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.wav'):
                path = os.path.join(root, file)
                mtime = datetime.datetime.fromtimestamp(os.path.getmtime(path))
                if mtime > one_day_ago:
                    print(f"{mtime} {path}")

find_recent_wavs()
