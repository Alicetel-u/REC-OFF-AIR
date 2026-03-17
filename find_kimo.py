
import os

def find_kimo():
    for root, dirs, files in os.walk('.'):
        for file in files:
            if 'きも' in file:
                print(os.path.join(root, file))

find_kimo()
