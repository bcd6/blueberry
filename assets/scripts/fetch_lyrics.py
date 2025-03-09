import sys
import json
from syncedlyrics import search

def fetch_lyrics(title, artist=None):
    try:
        query = f"{title} {artist}" if artist else title
        lyrics = search(query)
        if lyrics:
            print(json.dumps({
                "success": True,
                "lyrics": lyrics
            }))
        else:
            print(json.dumps({
                "success": False,
                "error": "No lyrics found"
            }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "error": "Missing arguments"
        }))
    else:
        title = sys.argv[1]
        artist = sys.argv[2] if len(sys.argv) > 2 else None
        fetch_lyrics(title, artist)