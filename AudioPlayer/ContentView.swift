//
//  ContentView.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack {
            Text("Audio Player")
                .font(.title)
                .padding()

            if player != nil {
                Button(action: {
                    if player?.timeControlStatus == .playing {
                        player?.pause()
                    } else {
                        player?.play()
                    }
                }) {
                    Text(player?.timeControlStatus == .playing ? "Pause" : "Play")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("Loading Audio...")
            }
        }
        .onAppear {
            let url = URL(string: "https://d12wklypp119aj.cloudfront.net/track/86d38d9a-2f4b-44ae-a77f-a72e034f6d54.mp3")!
            let originalAsset = AVURLAsset(url: url)
            player = AVPlayer(playerItem: AVPlayerItem(asset: originalAsset))
        }
        .onDisappear {
            player?.pause()
        }
    }
}
//
//struct AudioPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        AudioPlayerView()
//    }
//}
//
//
//









//import SwiftUI
//import Combine
//
//struct ContentView: View {
//    @State private var playerStatus: PlaybackState = .paused
//    @State private var currentTime: Double = 0
//    @State private var totalTime: Double = 100
//
//    private func sliderEditingChanged(editingStarted: Bool) {
//        if editingStarted {
//            AudioPlayer.shared.elapsedTimeObserver.pause(true)
//        } else {
//            AudioPlayer.shared.seek(to: currentTime, playerStatus: playerStatus)
//        }
//    }
//
//    var body: some View {
//        List(episodes) { episode in
//            ListSongViewCell(episode: episode)
//                .onTapGesture {
//                    AudioPlayer.shared.play(item: episode, action: .playNow)
//                    playerStatus = .playing
//                }
//                .frame(maxWidth: .infinity)
//                .listRowSeparator(.hidden)
//        }
//        .listStyle(.plain)
//
//        VStack {
//            Slider(value: $currentTime, in: 0...totalTime, onEditingChanged: sliderEditingChanged)
//                .padding()
//                .onReceive(
//                    Publishers.CombineLatest(
//                        AudioPlayer.shared.totalDurationObserver.publisher,
//                        AudioPlayer.shared.elapsedTimeObserver.publisher)) { totalTime, currentTime in
//                            self.totalTime = totalTime
//                            self.currentTime = currentTime
//                        }
//
//            HStack {
//                Text(formatTime(seconds: currentTime))
//                Spacer()
//                Text(formatTime(seconds: totalTime))
//            }
//            .padding(.horizontal)
//
//            HStack {
//                Button {
//                    AudioPlayer.shared.seekBackward()
//                } label: {
//                    Image(systemName: "gobackward.15")
//                        .font(.system(size: 30))
//                        .padding()
//                }
//                .disabled(playerStatus == .paused)
//
//                Spacer()
//
//                Button {
//                    print(AudioPlayer.shared.playbackStatePublisher.value)
//                    switch AudioPlayer.shared.playbackStatePublisher.value {
//                    case .waitingForSelection:
//                        playerStatus = .playing
//                        AudioPlayer.shared.play(item: episode, action: .playNow)
//                    case .playing:
//                        playerStatus = .paused
//                        AudioPlayer.shared.pause()
//                    case .paused:
//                        AudioPlayer.shared.resume()
//                        playerStatus = .playing
//                    default:
//                        break
//                    }
//                } label: {
//                    Image(systemName: playerStatus == .playing ? "pause.circle.fill" : "play.circle.fill")
//                        .font(.system(size: 50))
//                        .padding()
//                }
//                Spacer()
//
//                Button {
//                    AudioPlayer.shared.seekForward()
//                } label: {
//                    Image(systemName: "goforward.15")
//                        .font(.system(size: 30))
//                        .padding()
//                }
//                .disabled(playerStatus == .paused)
//            }
//        }
//    }
//
//    private func formatTime(seconds: Double) -> String {
//        let minutes = Int(seconds) / 60
//        let seconds = Int(seconds) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//}
//
//#Preview {
//    ContentView()
//}
