//
//  routes+albums.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

func routealbums(_ albums: RoutesBuilder) throws {
    let ds = Datastore.shared()

    // MARK: GET /albums
    albums.get { req -> APIAlbums in
        let params = try req.query.decode(ListParams.self)
        let limit = params.limit ?? 10
        let offset = params.offset ?? 0
        let albums = try ds.getAlbums(limit: limit, offset: offset, fields: params.fields)
        let albumCount = ds.getAlbumCount()
        let metadata = APIMetadata(totalCount: albumCount, limit: limit, offset: offset)
        return APIAlbums(albums: albums, _metadata: metadata)
    }
    
    try albums.group(":id") { album in
        
        try routealbum(album)
    }
}

func routealbum(_ album: RoutesBuilder) throws {
    let ds = Datastore.shared()
    
    try album.group(":filename")  { file in
        
        try routealbumfiles(file)
    }
        
    
    // MARK: HEAD /albums/:id
    album.on(.HEAD, []) { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id") {
            if try ds.albumExists(id) {
                return(.ok)
            } else {
                return(.notFound)
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: GET /albums/:id
    album.get { req -> Album in
        if let id = req.parameters.get("id") {
            if let album = try ds.getAlbum(id) {
                return album
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: POST /albums/:id
    album.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
        let id = req.parameters.get("id")!
        let album = try req.content.decode(Album.self)
        
        if id != album.id {
            return HTTPResponseStatus.conflict
        }
        
        do {
            try ds.postAlbum(album)
        } catch {
            return HTTPResponseStatus.conflict
        }
        
        return HTTPResponseStatus.ok
        
    }
    
    // MARK: PUT /albums/:id
    album.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
        let id = req.parameters.get("id")!
        let album = try req.content.decode(Album.self)
        
        if id != album.id {
            return HTTPResponseStatus.conflict
        }
        
        try ds.putAlbum(album)
        
        return HTTPResponseStatus.ok
    }
    
    // MARK: DELETE /albums/:id
    album.delete { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id") {
            try ds.deleteAlbum(id)
        } else {
            throw Abort(.notFound)
        }
        
        return HTTPResponseStatus.ok
    }
}

func routealbumfiles(_ file: RoutesBuilder) throws {
    let ds = Datastore.shared()
    
    // MARK: GET /albums/:id/:filename
    file.get { req -> Response in
//                    file.get { req -> Future<Response> in     // requires Combine?
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let path = ds.getAlbumFilePath(id, filename: filename) {
                return req.fileio.streamFile(at: path)
//                            return req.streamFile(at: path)
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: POST /albums/:id/:filename
    file.on(.POST, [], body: .collect(maxSize: 100000000)) { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            let value = req.body.data
            let data = Data(buffer: value!)
            try ds.postAlbumFile(id, filename: filename, data: data)
            return HTTPResponseStatus.ok
        }
        
        return HTTPResponseStatus.badRequest
    }
    
    // MARK: PUT /albums/:id/:filename
    file.on(.PUT, [], body: .collect(maxSize: 100000000)) {req -> HTTPResponseStatus in
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            let value = req.body.data
            let data = Data(buffer: value!)
            try ds.putAlbumFile(id, filename: filename, data: data)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.badRequest
    }
    
    // MARK: DELETE /albums/:id/:filename
    file.delete { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            try ds.deleteAlbumFile(id, filename: filename)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.badRequest
    }
}

