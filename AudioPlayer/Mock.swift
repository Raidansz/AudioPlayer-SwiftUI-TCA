//
//  Mock.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//

import Foundation

class Episode: PlayableItemProtocol {
    var title: String
    var artist: String
    var image: URL?
    var streamURL: URL
    var id: UUID

    init(title: String, artist: String, image: URL? = nil, streamURL: URL, id: UUID) {
        self.title = title
        self.artist = artist
        self.image = image
        self.streamURL = streamURL
        self.id = id
    }

    static func == (lhs: Episode, rhs: Episode) -> Bool {
        lhs.id == rhs.id
    }
}

var episode: Episode {
    .init(title: "Song", artist: "Author", image: URL(string: "https://picsum.photos/200"), streamURL: URL(string: imageurl1)!, id: UUID())
}

var episode2: Episode {
    .init(title: "Song2", artist: "Author2", streamURL: URL(string: imageurl2)!, id: UUID())
}

public let imageurl1 = "https://op3.dev/e,pg=e85a9a88-0ddf-5f39-9cc8-49d74fd9d96b/https://d12wklypp119aj.cloudfront.net/track/86d38d9a-2f4b-44ae-a77f-a72e034f6d54.mp3"


public let imageurl2 = "https://op3.dev/e,pg=81cfe3db-0b34-52d6-835c-61a3510bea82/https://d12wklypp119aj.cloudfront.net/track/0cada75d-2986-4960-8c0d-b3309367b97b.mp3"
