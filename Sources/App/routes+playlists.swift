//
//  routes+playlists.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

func routeplaylists(_ playlists: RoutesBuilder) throws {
    
    // MARK: GET /playlists - notImplemented
    playlists.get { req -> Response in
        throw Abort(.notImplemented)
    }
    
    
    try playlists.group(":id") { playlist in
        
        try routeplaylist(playlist)
    }

}

func routeplaylist(_ playlist: RoutesBuilder) throws {
    
    // MARK: GET /playlists/:id - notImplemented
    playlist.get { req -> Response in
        throw Abort(.notImplemented)
    }
    
    // MARK: POST /playlists/:id - notImplemented
    playlist.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
        return HTTPResponseStatus.notImplemented
    }
    
    // MARK: PUT /playlists/:id - notImplemented
    playlist.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
        return HTTPResponseStatus.notImplemented
    }
    
    // MARK: DELETE /playlists/:id - notImplemented
    playlist.delete { req -> HTTPResponseStatus in
        return HTTPResponseStatus.notImplemented
    }

}
