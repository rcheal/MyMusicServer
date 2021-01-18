//
//  routes+singles.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

func routesingles(_ singles: RoutesBuilder) throws {
    let ds = Datastore.shared()

    // MARK: GET /singles
    singles.get { req -> Singles in
        return Singles(singles: try ds.getSingles())
    }
    
    try singles.group(":id") { single in
        
        try routesingle(single)
    }
}

func routesingle(_ single: RoutesBuilder) throws {
    let ds = Datastore.shared()
    
    try single.group(":filename")  { file in
        
        try routesinglefiles(file)
        
    }
    
    // MARK: GET /singles/:id
    single.get { req -> Single in
        if let id = req.parameters.get("id") {
            if let single = try ds.getSingle(id) {
                return single
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: POST /singles/:id
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
    
    // MARK: PUT /singles/:id
    single.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
        let id = req.parameters.get("id")!
        let single = try req.content.decode(Single.self)
        
        if id != single.id {
            return HTTPResponseStatus.conflict
        }
        
        try ds.putSingle(single)
        
        return HTTPResponseStatus.ok
    }
    
    // MARK: DELETE /singles/:id
    single.delete { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id") {
            try ds.deleteSingle(id)
        } else {
            throw Abort(.notFound)
        }
        
        return HTTPResponseStatus.ok
    }
}

func routesinglefiles(_ file: RoutesBuilder) throws {
    let ds = Datastore.shared()
    
    // MARK: GET /singles/:id/:filename
    file.get { req -> Response in
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            if let path = ds.getSingleFilePath(id, filename: filename) {
                return req.fileio.streamFile(at: path)
            }
        }
        throw Abort(.notFound)
    }

    // MARK: POST /singles/:id/:filename
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
    
    // MARK: PUT /singles/:id/:filename
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
    
    // MARK: DELETE /singles/:id/:filename
    file.delete { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id"),
           let filename = req.parameters.get("filename") {
            try ds.deleteSingleFile(id, filename: filename)
            return HTTPResponseStatus.ok
        }
        return HTTPResponseStatus.badRequest
    }
}

