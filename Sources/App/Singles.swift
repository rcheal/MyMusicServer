//
//  Singles.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MusicMetadata

struct Singles {
    var singles: [SingleSummary]
}

extension Singles: Codable, Content {
    
    public enum CodingKeys: String, CodingKey {
        case singles
    }
}
