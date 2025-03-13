# Blueberry Music Player

A modern music player built with Flutter that focuses on album-based music playback with karaoke-style lyrics display.

## Preview

![Album Grid View](./preview_grid.png)
_Album grid view with cover art display_

![Playback View](./preview_player.png)
_Music playback with karaoke-style lyrics_

## Features

- 🎵 Support for multiple audio formats (FLAC, APE, MP3, M4A, AAC, OGG, WAV, etc.)
- 📝 Karaoke-style synchronized lyrics display
- 💿 Album-centric organization with cover art display
- 🎯 CUE sheet support for seamless album playback
- 🎨 Modern, minimalist UI design
- 🖼️ Grid-based album view with smooth scrolling
- 🎼 Automatic lyrics file detection and parsing
- 🔄 Background image caching for smooth performance

## Installation

### Prerequisites

- Windows 10 or later
- [Flutter](https://flutter.dev/docs/get-started/install) (2.0.0 or higher)
- [Flutter Version Management (FVM)](https://fvm.app/) (optional but recommended)

### Setup

1. Clone the repository:

```bash
git clone https://github.com/yourusername/blueberry.git
cd blueberry
```

2. Install dependencies:

```bash
fvm flutter pub get
```

3. Generate necessary files:

```bash
dart run build_runner build
```

4. Run the app in development mode:

```bash
fvm flutter run -d windows
```

### Building for Production

To create a production build:

```bash
fvm flutter build windows
```

The built application will be available in `build/windows/runner/Release/`.

## Usage

1. Before Launch:

   - Config file hardcoded at `D:\\~\\album\\~.json`
   - Format like

   ```
   {
    "folders": [
            {
                "path": "D:\\~\\album"
            }
        ]
    }
   ```

2. Library Organization:

   - Albums are automatically organized based on folder structure
   - CUE sheets are parsed for proper track splitting
   - Lyrics files (.lrc) are automatically detected and linked

3. Playback:
   - Click on an album to start playback
   - Lyrics will automatically display if available

## Folder Structure

The app expects your music to be organized in the following way:

```
Music Directory
├── Album1
│   ├── folder.jpg
│   ├── 01. Track.flac
│   └── 01. Track.lrc
├── Album2
│   ├── folder.jpg
│   └── album.cue
│   └── album.flac
```

## Development

To contribute to development:

1. Setup development environment:

```bash
fvm install
fvm flutter pub get
```

2. Run code generation when changing models:

```bash
dart run build_runner build
```

3. Run tests:

```bash
fvm flutter test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
