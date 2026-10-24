# ReplayKit Max

Removes the ReplayKit resolution cap (1600×1600 or 1920×1920) and records at the full screen size. This is the tweak version of `defaults write replayd RPFullResCapture -bool 1`.

It injects into `replayd` only. Requires iOS 9 or later.

## Settings

Open **Settings → ReplayKit Max**. Changes apply to the next recording.

- **Enable ReplayKit Max**: Removes the resolution cap. On by default.
- **120 FPS**: Shown on displays that can refresh at 120 Hz. Playback still follows how often the screen updates, so the file is often below 120 FPS.
- **HEVC**: Shown on devices that can encode HEVC. Saves the recording as HEVC instead of H.264.
- **HDR10 (Experimental)**: Shown on displays that support HDR10. The picture may look too bright.
