//
//  ServerStatus.swift
//  
//
//  Created by Robert Cheal on 10/21/20.
//

import Vapor

var myMusicServerVersion = "1.0.0" // You must manually sync this with the git tag
var myMusicApiVersions = "v1"  // comma separated list of supported api versions

class ServerState {
    static var shared = ServerState()
    
    
    var startDate: Date
    
    var upTime: Double {
        get {
            Date().timeIntervalSince(startDate)
        }
    }

    
    init() {
        startDate = Date()
    }
}

let serverState = ServerState.shared

struct ServerStatus: Content {

    struct Address: Codable {
        var host: String
        var port: Int
    }
    
    var version = myMusicServerVersion
    var apiVersions = myMusicApiVersions
    var name: String
    var url: Address
    var albumCount: Int
    var singleCount: Int
    var playlistCount: Int
    var upTime: Double
    
    init(_ app: Application) {
        let ds = Datastore.shared()
        
        upTime = serverState.upTime
        
        name = app.http.server.configuration.serverName ?? Host.current().localizedName ?? "Unknown"
        url = Address(host: app.http.server.configuration.hostname, port: app.http.server.configuration.port)
        albumCount = ds.getAlbumCount()
        singleCount = ds.getSingleCount()
        playlistCount = ds.getPlaylistCount()
    }
}
