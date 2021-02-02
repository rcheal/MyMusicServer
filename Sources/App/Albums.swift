//
//  Albums.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

struct Metadata: Codable {
    var totalCount: Int
    var limit: Int
    var offset: Int
}

struct Albums {
    var albums: [Album]
    var _metadata: Metadata
}

extension Albums: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case albums
        case _metadata
    }
}
