import sys
import json
from syncedlyrics import search

def fetch_lyrics(title, artist=None):
    try:
        query = f"{title} {artist}" if artist else title
        print(json.dumps({
            "status": "searching",
            "query": query
        }), file=sys.stderr)
        
        lyrics = search(query, synced_only=True, enhanced=True)
        if lyrics:
            print(json.dumps({
                "success": True,
                "lyrics": lyrics
            }))
        else:
            print(json.dumps({
                "success": False,
                "error": "No lyrics found",
                "details": {
                    "query": query,
                    "title": title,
                    "artist": artist or "unknown",
                    "message": "Could not find synchronized lyrics. Try different artist name or title."
                }
            }))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e),
            "details": {
                "query": query,
                "title": title,
                "artist": artist or "unknown",
                "exception_type": e.__class__.__name__,
                "message": "An error occurred while fetching lyrics"
            }
        }))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "error": "Missing arguments",
            "details": {
                "expected": "python fetch_lyrics.py <title> [artist]",
                "received": len(sys.argv) - 1,
                "message": "Script requires at least song title argument"
            }
        }))
    else:
        title = sys.argv[1]
        artist = sys.argv[2] if len(sys.argv) > 2 else None
        fetch_lyrics(title, artist)