//
//  Playlists.swift
//  
//
//  Created by Robert Cheal on 1/16/21.
//

import Vapor
import MusicMetadata

struct Playlists {
    var playlists: [PlaylistSummary]
}

extension Playlists: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case playlists
    }
}
