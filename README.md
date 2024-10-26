
# AudioPlayer

## Overview

**AudioPlayer** is a modular audio player built using Swift and the Composable Architecture (TCA). It leverages `AVFoundation`, `Combine`, and `MediaPlayer` to provide a robust and scalable solution for audio playback, optimized for background functionality, playback control, and seamless integration with iOS’s Now Playing Info Center.

Key features include playback management for individual and queued audio items, real-time updates to playback info (e.g., title, artist, artwork), and the ability to handle interruptions like calls. This makes **AudioPlayer** ideal for applications needing dependable audio streaming with full playback control.

> **Note**: This project is actively developed, and some features may evolve as improvements are made.

## Features

- **Playback Control**: Supports play, pause, resume, seek, and stop actions.
- **Queue Management**: Easily enqueue and dequeue multiple audio items for a seamless playback experience.
- **Background Playback**: Configured to support audio playback while the app is in the background.
- **Now Playing Info Center Integration**: Displays track information in the lock screen and control center.
- **Error Handling**: Manages audio session errors gracefully.
- **Composable Architecture**: Built using TCA, making it highly modular and easy to extend or refactor.

## Project Structure

The core functionality of **AudioPlayer** is organized within `AudioPlayerFeature`, a feature reducer in TCA. The project structure is as follows:

- **`State`**: Defines the player’s state, including the playback queue, playback status, and current item information.
- **`Actions`**: Contains all the actions needed to control the audio player, such as `play`, `pause`, `seek`, `enqueue`, and more.
- **`Reducer`**: Manages the state transitions based on actions, using helper methods to handle playback and queue management.
- **`Protocols`**: `PlayableItemProtocol` allows flexibility in defining various types of audio items.
- **`Helper Methods`**: Includes methods for updating Now Playing info, configuring audio sessions, and handling remote command center actions.

### Example Code Snippet

Here’s a brief look at the `play` action and state management in `AudioPlayerFeature`:

```swift
case .play(let item):
    guard let item else { return .none }
    play(for: &state, item: item)
    return .none
```

The `play(for: &state, item:)` function handles playback by initializing the player with the provided audio item and updating the `isPlaying` status.

## Installation

To integrate **AudioPlayer** in your project:

1. Clone or download the repository.
2. Add the `AudioPlayer` source files to your project.
3. Import necessary modules (`ComposableArchitecture`, `AVFoundation`, `MediaPlayer`, `Combine`).
4. Use `AudioPlayerFeature` in your SwiftUI views and observe its state through the Composable Architecture framework.

## Contributing

We welcome contributions to improve **AudioPlayer**! Whether you're fixing bugs, adding new features, or enhancing documentation, please follow these steps to contribute:

1. **Fork the repository**: Click "Fork" at the top right of this repository.
2. **Create a branch**: Make a new branch for your feature (`git checkout -b feature-name`).
3. **Develop and test**: Ensure your changes work and are well-tested.
4. **Commit**: Write a clear, concise commit message (`git commit -m "Description of feature"`).
5. **Push your changes**: Push to your branch (`git push origin feature-name`).
6. **Submit a pull request**: Open a pull request to the main branch of this repository for review.

Please open issues for any bug reports, feature requests, or questions.
