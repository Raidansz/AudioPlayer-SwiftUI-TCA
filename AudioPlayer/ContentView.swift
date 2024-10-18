//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI

struct ContentView: View {
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 100

    var body: some View {
        VStack {
            Slider(value: $currentTime, in: 0...totalTime)
                .padding()
                .onReceive(AudioPlayer.shared.totalDurationObserver.publisher) { totalTime in
                    self.totalTime = totalTime
                }
                .onReceive(AudioPlayer.shared.elapsedTimeObserver.publisher) { currentTime in
                    self.currentTime = currentTime
                }

            HStack {
                Text(formatTime(seconds: currentTime))
                Spacer()
                Text(formatTime(seconds: totalTime))
            }
            .padding(.horizontal)

            HStack {
                Button {
                    AudioPlayer.shared.seekBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(!isPlaying)

                Spacer()

                Button {
                    switch AudioPlayer.shared.playbackStatePublisher.value {
                    case .waitingForSelection:
                        isPlaying = true
                        AudioPlayer.shared.play(item: episode)
                    case .playing:
                        isPlaying = false
                        AudioPlayer.shared.pause()
                    case .paused:
                        AudioPlayer.shared.resume()
                        isPlaying = true
                    default:
                        break
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .padding()
                }
                Spacer()

                Button {
                    AudioPlayer.shared.seekForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 30))
                        .padding()
                }
                .disabled(!isPlaying)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func formatTime(seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
