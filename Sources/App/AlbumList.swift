//
//  AlbumList.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

struct AlbumList {
    var albums: [AlbumListItem]
}

extension AlbumList: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case albums
    }
}
