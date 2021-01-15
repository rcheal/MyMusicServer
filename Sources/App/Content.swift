//
//  Content.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MusicMetadata

extension Album: Content {
    
}

extension Single: Content {
    
}

struct FileContent: Content {
    var name: String
    var data: Data
}

struct StartTime: Content {
    var startTime: String?
}

struct UserPassword: Content {
    var user: String?
    var password: String?
}

