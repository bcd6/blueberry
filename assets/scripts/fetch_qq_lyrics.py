import sys
import json
import base64
import requests
from urllib.parse import quote
import time

def search_qq_music(title, artist=None, timeout=10):
    try:
        # Clean up search terms
        title = title.strip().lower()
        artist = artist.strip().lower() if artist else None
        
        # Form search query
        query = f"{artist} {title}" if artist else title

        # QQ Music search API endpoint with required parameters
        search_url = (
            "https://c.y.qq.com/soso/fcgi-bin/client_search_cp?"
            f"w={quote(query)}&"
            "format=json&"
            "p=1&"
            "n=20&"
            "aggr=1&"
            "lossless=0&"
            "cr=1&"
            f"t={int(time.time())}"
        )

        # Headers to mimic browser request
        headers = {
            'Referer': 'https://y.qq.com',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
            'Accept': 'application/json'
        }

        # Get search results with timeout
        response = requests.get(search_url, headers=headers, timeout=timeout)
        response.raise_for_status()  # Raise exception for bad status codes
        data = response.json()

        if 'data' not in data or 'song' not in data['data'] or 'list' not in data['data']['song']:
            return {
                'success': False, 
                'error': 'Invalid API response',
                'details': {'query': query}
            }

        songs = data['data']['song']['list']
        if not songs:
            return {
                'success': False, 
                'error': 'No songs found',
                'details': {'query': query}
            }

        # Get first song's mid
        song = songs[0]
        song_mid = song['songmid']

        # Get lyrics using song mid
        lyric_url = (
            "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?"
            f"songmid={song_mid}&"
            "format=json&"
            "nobase64=0&"
            f"g_tk={int(time.time())}&"
            "loginUin=0&"
            "hostUin=0"
        )

        # Get lyrics with timeout
        lyric_response = requests.get(lyric_url, headers=headers, timeout=timeout)
        lyric_response.raise_for_status()
        
        # Handle callback wrapper
        content = lyric_response.text.strip()
        if content.startswith('MusicJsonCallback('):
            content = content[16:-1]
        
        lyric_data = json.loads(content)

        if lyric_data.get('retcode', -1) != 0:
            return {
                'success': False,
                'error': 'Failed to get lyrics',
                'details': {
                    'query': query,
                    'song_mid': song_mid,
                    'retcode': lyric_data.get('retcode')
                }
            }

        # Decode base64 lyrics
        if 'lyric' in lyric_data:
            try:
                decoded_lyric = base64.b64decode(lyric_data['lyric']).decode('utf-8')
                
                # Verify we got actual lyrics, not just metadata
                if '[00:' not in decoded_lyric:
                    return {
                        'success': False,
                        'error': 'No synchronized lyrics found',
                        'details': {'query': query}
                    }
                
                return {
                    'success': True,
                    'lyrics': decoded_lyric,
                    'meta': {
                        'title': song['songname'],
                        'artist': song['singer'][0]['name'] if song['singer'] else None,
                        'album': song['albumname'],
                        'source': 'QQ Music'
                    }
                }
            except Exception as e:
                return {
                    'success': False,
                    'error': 'Failed to decode lyrics',
                    'details': {'query': query, 'error': str(e)}
                }

        return {
            'success': False,
            'error': 'No lyrics in response',
            'details': {'query': query}
        }

    except requests.Timeout:
        return {
            'success': False,
            'error': 'Request timed out',
            'details': {'query': query, 'timeout': timeout}
        }
    except requests.RequestException as e:
        return {
            'success': False,
            'error': 'Network error',
            'details': {'query': query, 'error': str(e)}
        }
    except Exception as e:
        return {
            'success': False,
            'error': 'Unexpected error',
            'details': {'query': query, 'error': str(e)}
        }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({
            'success': False,
            'error': 'No search terms provided'
        }, ensure_ascii=False))
        sys.exit(1)

    title = sys.argv[1]
    artist = sys.argv[2] if len(sys.argv) > 2 else None

    result = search_qq_music(title, artist)
    print(json.dumps(result, ensure_ascii=False, indent=2))