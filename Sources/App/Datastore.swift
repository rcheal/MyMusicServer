//
//  Datastore.swift
//  
//
//  Created by Robert Cheal on 1/9/21.
//

import Foundation
import MusicMetadata
import GRDB
import Vapor

class Datastore {
    public static var sharedInstance: Datastore?
    
    public static func create(memory: Bool = false) -> Datastore {
        let datastore = Datastore(memory: memory)
        sharedInstance = datastore
        return datastore
    }
    
    public static func shared() -> Datastore {
        if let dm = sharedInstance {
            return dm
        } else {
            let dm = Datastore(memory: false)
            sharedInstance = dm
            return dm
        }
    }
    
    var isMemory = false
    
    public var fileRootURL: URL
    
    private var dbQueue: DatabaseQueue

    private init(memory: Bool = false) {
        isMemory = memory
        let subDirectory = isMemory ? "MyMusicServerMemoryFiles" : "MyMusicServerFiles"
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let baseURL = homeURL.appendingPathComponent(subDirectory)
        let fm = FileManager()
        if !fm.fileExists(atPath: baseURL.path) {
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        if memory {
            fileRootURL = baseURL
            dbQueue = DatabaseQueue()
        } else {
            fileRootURL = baseURL.appendingPathComponent("music")
            let dbURL = baseURL.appendingPathComponent("MyMusic.sqlite")
            do {
                try dbQueue = DatabaseQueue(path: dbURL.path)
            } catch {
                dbQueue = DatabaseQueue()
            }
        }
        try? migrateDb()
    }

    func migrateDb() throws {
        var migrator = DatabaseMigrator()
        
        // 1st migration
        migrator.registerMigration("V1") { db in
            try db.create(table: "album") { t in
                t.column("id", .text).primaryKey()
                t.column("json", .blob)
            }
            
            try db.create(table: "single") { t in
                t.column("id", .text).primaryKey()
                t.column("json", .blob)
            }
            
            try db.create(table: "playlist") { t in
                t.column("id", .text).primaryKey()
                t.column("user", .text)
                t.column("shared", .boolean)
                t.column("json", .blob)
            }

            
            try db.create(table: "transaction") { t in
                t.column("time", .text).primaryKey()
                t.column("id", .text)
                t.column("method", .text)           // 'GET', 'POST', 'PUT' or 'DELETE'
                t.column("entity", .text)           // 'album', 'single', or 'playlist'
            }
        }
        
        try migrator.migrate(dbQueue)
    }

    // MARK: Server functions
    
    func getTransactions(since timestamp: String) throws -> [Transaction] {
        return try dbQueue.read { db in
            try Transaction.fetchAll(db, sql: "SELECT * FROM 'transaction' WHERE time >= ?",
                                     arguments: [timestamp])
        }
    }
    
    // MARK: Album functions
    
    func getAlbums(limit: Int, offset: Int, fields: String?) throws -> [Album] {
        var albums: [Album] = []
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT json FROM album LIMIT ? OFFSET ?",
                                        arguments: [limit, offset])
            for row in rows {
                if var album = Album.decodeFrom(json: row["json"]) {
                    if let fields = fields {
                        let fullAlbum = album
                        album = Album(title: fullAlbum.title)
                        album.id = fullAlbum.id
                        album.addFields(fields, from: fullAlbum)
                    }
                    albums.append(album)
                }
            }
        }
        return albums
    }
    
    func getAlbumCount() -> Int {
        var count = -1
        do {
            try dbQueue.read { db in
                count = try Album.fetchCount(db)
            }
        } catch {
        }
        return count
    }

    func albumExists(_ id: String) throws -> Bool {
        var exists = false
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT EXISTS(SELECT 1 from album WHERE id = ?)", arguments: [id]) {
                exists = (row["EXISTS"] == 1)
            }
        }
        return exists
    }
    
    /**
     Retrieves an album from the database
     
     The return value contains all metadata.  References to audio files and artwork files
     are included, but the files themselves must be retrieved separately via getArtwork(:artRef:)
     and/or getAudiofile(...)
     
     - paramter id: Unique identifier of album to retrieve
     
     - returns: Album?
     */
    func getAlbum(_ id: String) throws  -> Album? {
        var album: Album?
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT json FROM album WHERE id = ?", arguments: [id]) {
                album = Album.decodeFrom(json: row["json"])
            }
        }
        return album
    }
    
    /**
     Insert new album into the database
     
     Insert album into album and albumListItem tables
     Insert singles contained in album into singleListItem table
     Insert compositions contained in album into compositionListItem table
     
     - parameter album: album to be inserted into database
     
     - throws: Database exceptions
     */
    func postAlbum(_ album: Album)  throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO album (id, json) VALUES (?, ?)
                """,
                arguments: [album.id, album.json])
            
            let transaction = Transaction(method: "POST", entity: "album", id: album.id)
            try transaction.insert(db)

        }
    }
    
    func putAlbum(_ album: Album) throws {
        try dbQueue.write { db in
            var changes = 0
            do {
            try db.execute(
                sql: """
                    UPDATE album SET json = ? WHERE id = ?
                """,
                arguments: [album.json, album.id])
            
            changes = db.changesCount
            } catch {
                throw Abort(.internalServerError)
            }
            
            let transaction = Transaction(method: "PUT", entity: "album", id: album.id)
            try transaction.insert(db)

            if changes < 1 {
                throw Abort(.notFound)
            }
         }
    }
    
    /**
     Delete specified album
     
     Deletes all records from database associated with id.  This includes
     records in the album. albumListItem, compositionListItem and singleListItem tables.
     Also deletes the directory containing the albums audiofiles and artwork.
     
     - paramter id: Unique id of album to be deleted
     
     - throws: Database or filesystem errors.  There is no error if the album does not exist.
     */
    func deleteAlbum(_ id: String) throws {
        var directory: String?
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT json FROM album WHERE id = ?", arguments: [id]) {

                let album = Album.decodeFrom(json: row["json"])
                directory = album?.directory
            }
        }
        let deleted = try dbQueue.write { db -> Bool in
            var result = false
            do {
                result = try Album.deleteOne(db, key: id)
                if !result {
                    throw Abort(.notFound)
                }
                
                let transaction = Transaction(method: "DELETE", entity: "album", id: id)
                try transaction.insert(db)
                
            } catch is PersistenceError {
                throw Abort(.notFound)
            }
            return result
        }
        
        if let albumDir = directory, deleted {
            let fm = FileManager.default

            let dirURL = fileRootURL.appendingPathComponent(albumDir)
            try? fm.removeItem(at: dirURL)
        }
    }
    
    private func getAlbumDirectoryURL(_ id: String) -> URL? {
        do {
            if let album = try getAlbum(id),
               let directory = album.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getAlbumFilePath(_ id: String, filename: String) -> String? {
        if let albumURL = getAlbumDirectoryURL(id) {
            return albumURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getAlbumFile(_ id: String, filename: String) -> Data? {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            
            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postAlbumFile(_ id: String, filename: String, data: Data) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if !fm.fileExists(atPath: albumURL.path) {
                try fm.createDirectory(at: albumURL, withIntermediateDirectories: true, attributes: nil)
            }
            if !fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.found)
            }
        }
    }
    
    func putAlbumFile(_ id: String, filename: String, data: Data) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteAlbumFile(_ id: String, filename: String) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
    
    // MARK: Single functions

    func getSingles(limit: Int, offset: Int, fields: String?) throws -> [Single] {
        var singles: [Single] = []
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT json FROM single LIMIT ? OFFSET ?",
                                        arguments: [limit, offset])
            for row in rows {
                if var single = Single.decodeFrom(json: row["json"]) {
                    if let fields = fields {
                        let fullSingle = single
                        single = Single(title: fullSingle.title, filename: "", track: fullSingle.track)
                        single.addFields(fields, from: fullSingle)
                    }
                   singles.append(single)
                }
            }
        }
        return singles
    }
    
    func getSingleCount() -> Int {
        var count = -1
        do {
            try dbQueue.read { db in
                count = try Single.fetchCount(db)
            }
        } catch {
        }
        return count
    }

    func singleExists(_ id: String) throws -> Bool {
        var exists = false
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT EXISTS(SELECT 1 from single WHERE id = ?)", arguments: [id]) {
                exists = (row["EXISTS"] == 1)
            }
        }
        return exists
    }
    
    func getSingle(_ id: String) throws  -> Single? {
        var single: Single?
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT json FROM single WHERE id = ?", arguments: [id]) {

                single = Single.decodeFrom(json: row["json"])
            }
        }
        return single
    }
    
    func postSingle(_ single: Single)  throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO single (id, json) VALUES (?, ?)
                """,
                arguments: [single.id, single.json])

            let transaction = Transaction(method: "POST", entity: "single", id: single.id)
            try transaction.insert(db)
            
        }
    }
    
    func putSingle(_ single: Single) throws {
        try dbQueue.write { db in
            var changes = 0
            do {
                try db.execute(
                    sql: """
                        UPDATE single SET json = ? WHERE id = ?
                    """,
                    arguments: [single.json, single.id])
                
                changes = db.changesCount

                let transaction = Transaction(method: "PUT", entity: "single", id: single.id)
                try transaction.insert(db)
                
            } catch {
                throw Abort(.internalServerError)
            }
            if changes < 1 {
                throw Abort(.notFound)
            }
        }
    }

    func deleteSingle(_ id: String) throws {
        var directory: String?
        var filename: String?
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT json FROM single WHERE id = ?", arguments: [id]) {

                let single = Single.decodeFrom(json: row["json"])
                directory = single?.directory
                filename = single?.filename
            }
        }
        let deleted = try dbQueue.write { db -> Bool in
            var result = false
            do {
                result = try Single.deleteOne(db, key: id)
                if !result {
                    throw Abort(.notFound)
                }

                let transaction = Transaction(method: "DELETE", entity: "single", id: id)
                try transaction.insert(db)
                
             } catch is PersistenceError {
                throw Abort(.notFound)
            }
            return result
        }
        
        if let directory = directory,
           let filename = filename, deleted {
            let fm = FileManager.default

            let dirURL = fileRootURL.appendingPathComponent(directory)
            let fileURL = dirURL.appendingPathComponent(filename)
            try? fm.removeItem(at: fileURL)
            if let contents = try? fm.contentsOfDirectory(atPath: dirURL.path), contents.isEmpty {
                try? fm.removeItem(at: dirURL)
            }
        }
    }
    
    private func getSingleDirectoryURL(_ id: String) -> URL? {
        do {
            if let single = try getSingle(id),
               let directory = single.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getSingleFilePath(_ id: String, filename: String) -> String? {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            return singleDirectoryURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getSingleFile(_ id: String, filename: String) -> Data? {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            
            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postSingleFile(_ id: String, filename: String, data: Data) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if !fm.fileExists(atPath: singleDirectoryURL.path) {
                try fm.createDirectory(at: singleDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            if !fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.found)
            }
        }
    }
    
    func putSingleFile(_ id: String, filename: String, data: Data) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteSingleFile(_ id: String, filename: String) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
    
    // MARK: Playlist functions
    
    func getPlaylists(user: String?) throws -> [PlaylistSummary] {
        var playlists: [PlaylistSummary] = []
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT json FROM playlist WHERE user = ? OR shared = ?",
                                        arguments: [user,true])
            for row in rows {
                if let playlist = Playlist.decodeFrom(json: row["json"]) {
                    var playlistSummary = PlaylistSummary(playlist)
                    playlistSummary.sortTitle = nil
                    playlists.append(playlistSummary)
                }
            }
        }
        return []
    }
    
    func getPlaylistCount() -> Int {
        var count = -1
        do {
            try dbQueue.read { db in
                count = try Playlist.fetchCount(db)
            }
        } catch {
        }
        return count
    }
    
    func playlistExists(_ id: String) throws -> Bool {
        var exists = false
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT EXISTS(SELECT 1 from playlist WHERE id = ?)", arguments: [id]) {
                exists = (row["EXISTS"] == 1)
            }
        }
        return exists
    }
    
    func getPlaylist(_ id: String) throws -> Playlist?  {
        var playlist: Playlist?
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT json FROM playlist WHERE id = ?", arguments: [id]) {

                playlist = Playlist.decodeFrom(json: row["json"])
            }
        }
        return playlist
    }
    
    func postPlaylist(_ playlist: Playlist) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO playlist (id, user, shared, json) VALUES (?, ?, ?, ?)
                """,
                arguments: [playlist.id, playlist.user, playlist.shared, playlist.json])

            let transaction = Transaction(method: "POST", entity: "playlist", id: playlist.id)
            try transaction.insert(db)
            
        }

    }
    
    func putPlaylist(_ playlist: Playlist) throws {
        try dbQueue.write { db in
            var changes = 0
            do {
                try db.execute(
                    sql: """
                        UPDATE playlist SET user = ?, shared = ?, json = ? WHERE id = ?
                    """,
                    arguments: [playlist.user, playlist.shared, playlist.json, playlist.id])
                
                changes = db.changesCount

                let transaction = Transaction(method: "PUT", entity: "playlist", id: playlist.id)
                try transaction.insert(db)
                
            } catch {
                throw Abort(.internalServerError)
            }
            if changes < 1 {
                throw Abort(.notFound)
            }
        }
    }
    
    func deletePlaylist(_ id: String) throws {
        let deleted = try dbQueue.write { db -> Bool in
            var result = false
            do {
                result = try Playlist.deleteOne(db, key: id)
                
                let transaction = Transaction(method: "DELETE", entity: "playlist", id: id)
                try transaction.insert(db)
                
            } catch is PersistenceError {
                throw Abort(.notFound)
            }
            return result
        }
        if !deleted {
            throw Abort(.notFound)
        }

    }
}
