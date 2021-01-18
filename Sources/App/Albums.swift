//
//  Albums.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

struct Albums {
    var albums: [AlbumSummary]
}

extension Albums: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case albums
    }
}
