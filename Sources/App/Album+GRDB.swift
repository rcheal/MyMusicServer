//
//  Album+GRDB.swift
//  MyMusicManager
//
//  Created by Robert Cheal on 12/22/20.
//

import Foundation
import MusicMetadata
import GRDB

extension Album: PersistableRecord {
    
}

extension Single: PersistableRecord {
    
}

extension Playlist: PersistableRecord {
    
}

extension Transaction: PersistableRecord, FetchableRecord {
    
}
