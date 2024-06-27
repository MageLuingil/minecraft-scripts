#!/usr/bin/env python3
import json, os, platform, shutil, sys

''' 
    Copy music from game assets into ./data/sounds/{music, records}/
    Modified from https://minecraft.fandom.com/wiki/Tutorials/Sound_directory#Extracting_Minecraft_sounds_using_Python
'''

def validateAssetsPath(path):
    return os.path.exists(path) \
        and os.path.exists(os.path.join(path, "indexes")) \
        and os.path.exists(os.path.join(path, "objects"))

# Search for a valid minecraft assets directory, looking in:
# - the current working directory
# - the Linux user's home directory
# - the Windows app data directory
def getAssetsPath():
    relPath = os.path.join(os.getcwd(), "assets")
    if validateAssetsPath(relPath):
        return relPath
    
    homePath = os.path.expanduser("~/.minecraft/assets")
    if validateAssetsPath(homePath):
        return homePath
    
    winPath = os.path.expandvars(r"%APPDATA%\.minecraft\assets")
    if platform.system() == "Windows" and validateAssetsPath(winPath):
        return winPath
    
    print(f"Minecraft assets directory not found", file=sys.stderr)
    sys.exit(1)

def getObjectIndex(assetsPath):
    indexes = os.listdir(os.path.join(assetsPath, "indexes"))
    if len(indexes) < 1:
        print("Minecraft object index not found", file=sys.stderr)
        sys.exit(1)
    with open(os.path.join(assetsPath, "indexes", indexes[-1]), "r") as fp:
         return json.load(fp)

def getObjectsWithPrefix(prefix, index):
    # Find each line that starts with prefix, remove the prefix, and return the rest of the path and the hash
    return {key[len(prefix):] : val["hash"] for (key, val) in index["objects"].items() if key.startswith(prefix)}

def copySoundObjectsOfType(type, assetsPath, index):
    count = 0
    dir = os.path.dirname(os.path.realpath(__file__))
    objects = getObjectsWithPrefix(f"minecraft/sounds/{type}/", index)
    for filepath, hash in objects.items():
        srcFile = os.path.join(assetsPath, "objects", hash[:2], hash)
        destFile = os.path.normpath(f"{dir}/data/sounds/{type}/{filepath}")
        # Since objects have nested folder structure, make sure directory exists
        os.makedirs(os.path.dirname(destFile), exist_ok=True)
        if not os.path.exists(destFile):
            count += 1
            print(f"Copying {srcFile} to {destFile}")
            shutil.copyfile(srcFile, destFile)
    if count == 0:
        print(f"No missing {type} to copy")

###############
# Main Script #
###############

assets = getAssetsPath()
print(f"Using assets from {assets}")
index = getObjectIndex(assets)

copySoundObjectsOfType("music", assets, index)
copySoundObjectsOfType("records", assets, index)
