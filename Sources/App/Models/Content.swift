//
//  Content.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MyMusic

extension Album: Content {
    
}

extension Single: Content {
    
}

extension Transaction: Content {
    
}

extension Playlist: Content {
    
}

extension APIAlbums: Content {
    
}

extension APISingles: Content {
    
}

extension APIPlaylists: Content {
    
}

extension APITransactions: Content {
    
}

struct FileContent: Content {
    var name: String
    var data: Data
}

struct StartTime: Content {
    var startTime: String?
}

struct UserParams: Content {
    var user: String?
    var password: String?
}


struct ListParams: Content {
    var limit: Int?
    var offset: Int?
    var fields: String?
}
