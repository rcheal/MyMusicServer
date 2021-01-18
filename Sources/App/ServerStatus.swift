//
//  ServerStatus.swift
//  
//
//  Created by Robert Cheal on 10/21/20.
//

import Vapor

var myMusicServerVersion = "1.0.0" // You must manually sync this with the git tag

class ServerState {
    static var shared = ServerState()
    
    
    var startDate: Date
    
    var upTime: String {
        get {
            let elapsedSeconds = Date().timeIntervalSince(startDate)
            let hours = Int(elapsedSeconds) / 3600
            let minutes = (Int(elapsedSeconds) % 3600) / 60
            let seconds = Int(elapsedSeconds) % 60
            return String(hours) + ":" + String(minutes) + ":" + String(seconds)
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
    var name: String
    var url: Address
    var albumCount: Int
    var singleCount: Int
    var playlistCount: Int = 0
    var upTime: String
    
    init(_ app: Application) {
        let ds = Datastore.shared()
        
        upTime = serverState.upTime
        
        name = app.http.server.configuration.serverName ?? Host.current().localizedName ?? "Unknown"
        url = Address(host: app.http.server.configuration.hostname, port: app.http.server.configuration.port)
        albumCount = ds.getAlbumCount()
        singleCount = ds.getSingleCount()
    }
}
