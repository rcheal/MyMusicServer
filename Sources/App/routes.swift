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

func routes(_ app: Application) throws {
    let _ = ServerState.shared
    let ds = Datastore.shared()

    app.get { req -> ServerStatus in
        return ServerStatus(app)
    }

    
    app.group("albums") { albums in
        albums.get { req -> String in
            let query = try req.query.decode(StartTime.self)
            if let startTime = query.startTime {
                return "GET /albums?startTime=\(startTime)"
            }
            return "GET /albums"
        }
        albums.group(":id") { album in
            album.group(":filename")  { file in
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
                file.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        let value = req.body.data
                        let data = Data(buffer: value!)
                        try ds.postAlbumFile(id, filename: filename, data: data)
                        return HTTPResponseStatus.ok
                    }
                    
                    return HTTPResponseStatus.badRequest
                }
                file.on(.PUT, [], body: .collect) {req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        let value = req.body.data
                        let data = Data(buffer: value!)
                        try ds.putAlbumFile(id, filename: filename, data: data)
                        return HTTPResponseStatus.ok
                    }
                    return HTTPResponseStatus.badRequest
                }
                file.delete { req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        try ds.deleteAlbumFile(id, filename: filename)
                        return HTTPResponseStatus.ok
                    }
                    return HTTPResponseStatus.badRequest
                }
            }
            
            album.get { req -> Album in
                if let id = req.parameters.get("id") {
                    if let album = try ds.getAlbum(id) {
                        return album
                    }
                }
                throw Abort(.notFound)
            }
            album.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
                let id = req.parameters.get("id")!
                let album = try req.content.decode(Album.self)
                
                if id != album.id {
                    return HTTPResponseStatus.conflict
                }
                
                do {
                    try ds.postAlbum(album)
                } catch {
                    return HTTPResponseStatus.internalServerError
                }
                
                return HTTPResponseStatus.ok
                
            }
            album.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
                let id = req.parameters.get("id")!
                let album = try req.content.decode(Album.self)
                
                if id != album.id {
                    return HTTPResponseStatus.conflict
                }
                
                try ds.putAlbum(album)
                
                return HTTPResponseStatus.ok
            }
            album.delete { req -> HTTPResponseStatus in
                if let id = req.parameters.get("id") {
                    try ds.deleteAlbum(id)
                } else {
                    throw Abort(.notFound)
                }
                
                return HTTPResponseStatus.ok
            }
        }
    }

    app.group("singles") { singles in
        singles.get { req -> String in
            let query = try req.query.decode(StartTime.self)
            if let startTime = query.startTime {
                return "GET /singles?startTime=\(startTime)"
            }
            return "GET /singles"
        }
        singles.group(":id") { single in
            single.group(":filename")  { file in
                file.get { req -> Response in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        if let path = ds.getSingleFilePath(id, filename: filename) {
                            return req.fileio.streamFile(at: path)
                        }
                    }
                    throw Abort(.notFound)
                }
                file.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        let value = req.body.data
                        let data = Data(buffer: value!)
                        try ds.postSingleFile(id, filename: filename, data: data)
                        return HTTPResponseStatus.ok
                    }
                    
                    return HTTPResponseStatus.badRequest
                }
                file.on(.PUT, [], body: .collect) {req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        let value = req.body.data
                        let data = Data(buffer: value!)
                        try ds.putSingleFile(id, filename: filename, data: data)
                        return HTTPResponseStatus.ok
                    }
                    return HTTPResponseStatus.badRequest
                }
                file.delete { req -> HTTPResponseStatus in
                    if let id = req.parameters.get("id"),
                       let filename = req.parameters.get("filename") {
                        try ds.deleteSingleFile(id, filename: filename)
                        return HTTPResponseStatus.ok
                    }
                    return HTTPResponseStatus.badRequest
                }
            }
            
            single.get { req -> Single in
                if let id = req.parameters.get("id") {
                    if let single = try ds.getSingle(id) {
                        return single
                    }
                }
                throw Abort(.notFound)
            }
            single.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
                let id = req.parameters.get("id")!
                let single = try req.content.decode(Single.self)
                
                if id != single.id {
                    return HTTPResponseStatus.conflict
                }
                
                do {
                    try ds.postSingle(single)
                } catch {
                    return HTTPResponseStatus.internalServerError
                }
                
                return HTTPResponseStatus.ok
                
            }
            single.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
                let id = req.parameters.get("id")!
                let single = try req.content.decode(Single.self)
                
                if id != single.id {
                    return HTTPResponseStatus.conflict
                }
                
                try ds.putSingle(single)
                
                return HTTPResponseStatus.ok
            }
            single.delete { req -> HTTPResponseStatus in
                if let id = req.parameters.get("id") {
                    try ds.deleteSingle(id)
                } else {
                    throw Abort(.notFound)
                }
                
                return HTTPResponseStatus.ok
            }
        }

    }

}
