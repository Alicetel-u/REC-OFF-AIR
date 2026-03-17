
import os
import re

def find_japanese_files():
    for root, dirs, files in os.walk('.'):
        for file in files:
            if re.search(r'[^\x00-\x7f]', file):
                print(os.path.join(root, file))

find_japanese_files()
