import asyncio
import sys
import json
from qqmusic_api import lyric
import ctypes



def parse():
    # Load the DLL (make sure it's in the same directory or provide the full path)
    dll = ctypes.CDLL("QQMusicVerbatim.dll")

    # Define function signature (assuming it takes (char*, char*, int) and returns int)
    dll.des_qqmusic.argtypes = (ctypes.POINTER(ctypes.c_ubyte), ctypes.POINTER(ctypes.c_ubyte), ctypes.c_int)
    dll.des_qqmusic.restype = ctypes.c_int  # Assuming it returns an int

    # Prepare input data
    input_data = (ctypes.c_ubyte * 16)(*bytearray(b"1234567890abcdef"))  # Example 16-byte input
    output_data = (ctypes.c_ubyte * 16)()  # Empty buffer for output
    data_length = len(input_data)

    # Call the function
    result = dll.des_qqmusic(input_data, output_data, data_length)

    # Print output
    print("Return Value:", result)
    print("Output Data:", bytes(output_data))


async def get_lyric(mid):
    try:
        print(json.dumps({
            "status": "searching",
            "query": mid
        }, ensure_ascii=False).encode('utf-8-sig').decode('utf-8'), file=sys.stderr)
        
        result = await lyric.get_lyric(mid, True, False, False)
        if result:
            # Encode result with UTF-8-BOM
            print(json.dumps({
                "success": True,
                "result": result
            }, ensure_ascii=False).encode('utf-8-sig').decode('utf-8'))
        else:
            print(json.dumps({
                "success": False,
                "error": "No Songs found",
                "details": {
                    "query": mid,
                    "message": "Could not find songs. Try different artist name or title."
                }
            }, ensure_ascii=False).encode('utf-8-sig').decode('utf-8'))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e),
            "details": {
                "query": mid,
                "exception_type": e.__class__.__name__,
                "message": "An error occurred while fetching lyrics"
            }
        }, ensure_ascii=False).encode('utf-8-sig').decode('utf-8'))

if __name__ == "__main__":
    # Set stdout to use UTF-8-BOM encoding
    sys.stdout = codecs.getwriter('utf-8-sig')(sys.stdout.buffer)
    
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "error": "Missing arguments",
            "details": {
                "expected": "python fetch_lyrics.py <title> [artist]",
                "received": len(sys.argv) - 1,
                "message": "Script requires at least song title argument"
            }
        }, ensure_ascii=False))
    else:
        mid = sys.argv[1]
        asyncio.run(get_lyric(mid))