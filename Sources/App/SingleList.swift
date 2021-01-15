//
//  SingleList.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MusicMetadata

struct SingleList {
    var singles: [SingleListItem]
}

extension SingleList: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case singles
    }
}
