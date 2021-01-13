@testable import App
import XCTVapor
import MusicMetadata

struct Resource {
    let url: URL
    let baseURL: URL
    
    init(relativePath: String, sourceFile: StaticString = #file) throws {
        
        let testCaseURL = URL(fileURLWithPath: "\(sourceFile)", isDirectory: false)
        let testFolderURL = testCaseURL.deletingLastPathComponent()
        baseURL = testFolderURL.deletingLastPathComponent().appendingPathComponent("Resources", isDirectory: true)
        
        self.url = URL(fileURLWithPath: relativePath, relativeTo: baseURL)
    }
}


final class AppTests: XCTestCase {
    
    override func setUpWithError() throws {
        Datastore.sharedInstance = nil
        let ds = Datastore.create(memory: true)
        
        let musicDir = ds.fileRootURL.path
        let fm = FileManager()
        if fm.fileExists(atPath: musicDir) {
            try! fm.removeItem(atPath: musicDir)
        }
    }

    func createMixedAlbum() -> Album {
        var album = Album(title: "Test Album")
        let single1 = Single(track: 1, title: "Song1", filename: "song1.mp3")
        let single2 = Single(track: 2, title: "Song2", filename: "song2.mp3")
        let single3 = Single(track: 6, title: "Song3", filename: "song3.mp3")
        let single4 = Single(track: 1, title: "Song4", filename: "song4.mp3", disk: 2)
        let single5 = Single(track: 5, title: "Song5", filename: "song5.mp3", disk: 2)
        let single6 = Single(track: 6, title: "Song6", filename: "song6.mp3", disk: 2)

        var composition1 = Composition(track: 3, title: "Composition1")
        var composition2 = Composition(track: 2, title: "Composition2", disk: 2)
        
        let movement1 = Movement(track: 3, title: "Movement1", filename: "file1.mp3")
        let movement2 = Movement(track: 4, title: "Movement2", filename: "file2.mp3")
        let movement3 = Movement(track: 5, title: "Movement3", filename: "file3.mp3")
        composition1.addMovement(movement1)
        composition1.addMovement(movement2)
        composition1.addMovement(movement3)
                
        let movement4 = Movement(track: 2, title: "Movement1", filename: "file4.mp3", disk: 2)
        let movement5 = Movement(track: 3, title: "Movement2", filename: "file5.mp3", disk: 2)
        let movement6 = Movement(track: 4, title: "Movement3", filename: "file6.mp3", disk: 2)
        
        composition2.addMovement(movement4)
        composition2.addMovement(movement5)
        composition2.addMovement(movement6)
        
        album.addSingle(single1)
        album.addSingle(single2)
        album.addComposition(composition1)
        album.addSingle(single3)
        album.addSingle(single4)
        album.addComposition(composition2)
        album.addSingle(single5)
        album.addSingle(single6)

        return album
    }
    
    func createLisztAlbum() -> Album {
        var album = Album(title: "Liszt Piano Concertos 1 & 2")
        album.subtitle = "Totentanz"
        album.artist = "Krystian Zimmerman"
        album.composer = "Franz Liszt (1811-1886)"
        album.conductor = "Seiji Ozawa"
        album.orchestra = "Boston Symphony Orchestra"
        album.publisher = "Deutsche Grammophon"
        album.genre = "Classical"
        album.copyright = "1988 Deutsche Grammophon"
        album.encodedBy = "Created by Grip"
        album.recordingYear = 1988
        album.addArt(AlbumArtRef(type: .front, format: .jpg))
        album.directory = "liszt_piano_concertos_no1_2"
        
        var composition = Composition(track: 1, title: "Piano Concerto No. 1 in E flat major")
        composition.albumId = album.id

        var movement = Movement(track: 1, title: "I. Allegro maestoso",
                                filename: "1__i_allegro_maestoso.m4a")
        movement.albumId = album.id
        movement.duration = 332
        composition.addMovement(movement)

        movement = Movement(track: 2, title: "II. Quasi adagio - Alegretto vivace - Allegro animato",
                            filename: "1__ii_quasi_adagio__alegretto_vivace__allegro_animato.m4a")
        movement.albumId = album.id
        movement.duration = 534
        composition.addMovement(movement)

        movement = Movement(track: 3, title: "III. Allegro marziale animato - Presto",
                            filename: "1__iii_allegro_marziale_animato__presto.m4a")
        movement.albumId = album.id
        movement.duration = 248
        composition.addMovement(movement)
        album.addComposition(composition)

        composition = Composition(track: 4, title: "Piano Concerto No. 2 in A major")
        composition.albumId = album.id

        movement = Movement(track: 4, title: "I. Adagio sostenuto assai - Allegro agitato assai",
                            filename: "2__i_adagio_sostenuto_assai__allegro_agitato_assai.m4a")
        movement.albumId = album.id
        movement.duration = 446
        composition.addMovement(movement)

        movement = Movement(track: 5, title: "II. Allegro moderato - Allegro deciso",
                            filename: "2__ii_allegro_moderato__allegro_deciso.m4a")
        movement.albumId = album.id
        movement.duration = 499
        composition.addMovement(movement)

        movement = Movement(track: 6, title: "III. Marziale un poco meno allegro",
                            filename: "2__iii_marziale_un_poco_meno_allegro.m4a")
        movement.albumId = album.id
        movement.duration = 262
        composition.addMovement(movement)

        movement = Movement(track: 7, title: "IV. Allegro animator - Stretto (molto accelerando)",
                            filename: "2__iv_allegro_animato__stretto_molto_accelerando.m4a")
        movement.albumId = album.id
        movement.duration = 111
        composition.addMovement(movement)

        album.addComposition(composition)

        var single = Single(track: 8, title: "Totentanz (Danse macabre)",
                            filename: "totentanz_danse_macabre_paraphrase_on_dies_irae.m4a")
        single.albumId = album.id
        single.duration = 912
        
        album.addSingle(single)
        return album
    }
    
    func createLisztSingle() -> Single {
        var single = Single(track: 1, title: "Totentanz (Danse macabre)",
                            filename: "totentanz_danse_macabre_paraphrase_on_dies_irae.m4a")
        single.artist = "Krystian Zimmerman"
        single.composer = "Franz Liszt (1811-1886)"
        single.conductor = "Seiji Ozawa"
        single.orchestra = "Boston Symphony Orchestra"
        single.publisher = "Deutsche Grammophon"
        single.genre = "Classical"
        single.copyright = "1988 Deutsche Grammophon"
        single.encodedBy = "Created by Grip"
        single.recordingYear = 1988
        single.directory = "liszt_totentanz"
 
        single.duration = 912
        return single
    }
    
    func createSingle(track: Int, title: String, filename: String) -> Single {
        var single = Single(track: track, title: title, filename: filename)
        single.disk = 1
        single.sortTitle = "SortTitle"
        single.subtitle = "SubTitle"
        single.artist = "Artist"
        single.sortArtist = "SortArtist"
        single.supportingArtists = "Artist1;Artist2;Artist3"
        single.composer = "Composer"
        single.sortComposer = "SortComposer"
        single.conductor = "Conductor"
        single.orchestra = "Orchestra"
        single.lyricist = "Lyricist"
        single.genre = "Genre"
        single.publisher = "Publisher"
        single.copyright = "Copyright"
        single.encodedBy = "EncodedBy"
        single.encoderSettings = "EncoderSettings"
        single.recordingYear = 2020
        single.duration = 1800

        return single
    }

    func testServerStatus() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let serverStatus = try res.content.decode(ServerStatus.self)
            
            XCTAssertEqual(serverStatus.version,myMusicServerVersion)
            XCTAssertEqual(serverStatus.serverName, "Robert’s iMac")
            XCTAssertEqual(serverStatus.ipAddress, "127.0.0.1")
            XCTAssertEqual(serverStatus.port, 8080)
            XCTAssertEqual(serverStatus.albumCount, 0)
            XCTAssertEqual(serverStatus.singleCount, 0)
            let components  = serverStatus.upTime.components(separatedBy: ":")
            XCTAssertEqual(components.count, 3)
            let hours = Int(components[0]) ?? 0
            let minutes = Int(components[1]) ?? 0
            let seconds = Int(components[2]) ?? 0
            let uptimeInSeconds = (hours * 3600) + (minutes * 60) + seconds
            XCTAssertLessThan(uptimeInSeconds, 5)
            
        })
    }
    
    func testGetAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })
    }
    
    func testPutAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.PUT, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })

    }
    
    func testPostPutAlbum() throws {
        let album = createMixedAlbum()
        var newAlbum = album
        newAlbum.title = "New title"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        let newAlbumBuf = ByteBuffer(data: newAlbum.json ?? Data())
        
        try app.test(.POST, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newAlbumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(newAlbum.title, "New title")
            
        })
    }
    
    func testPostGetAlbum() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(album.title, newAlbum.title)
            XCTAssertEqual(album.subtitle, newAlbum.subtitle)
            XCTAssertEqual(album.artist, newAlbum.artist)
            XCTAssertEqual(album.composer, newAlbum.composer)
            XCTAssertEqual(album.conductor, newAlbum.conductor)
            XCTAssertEqual(album.lyricist, newAlbum.lyricist)
            
        })
    }
    
    func testPostDeleteAlbum() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.DELETE, "albums/\(album.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testDeleteAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.DELETE, "albums/\(album.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
    }

    func testGetSingleNotFound() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })
    }
    
    func testPutSingleNotFound() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.PUT, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })

    }
    
    func testPostPutSingle() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")
        var newSingle = single
        newSingle.title = "New title"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        let newSingleBuf = ByteBuffer(data: newSingle.json ?? Data())
        
        try app.test(.POST, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newSingleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(newSingle.title, "New title")
            
        })
    }
    
    func testPostGetSingle() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(single.title, newSingle.title)
            XCTAssertEqual(single.subtitle, newSingle.subtitle)
            XCTAssertEqual(single.artist, newSingle.artist)
            XCTAssertEqual(single.composer, newSingle.composer)
            XCTAssertEqual(single.conductor, newSingle.conductor)
            XCTAssertEqual(single.lyricist, newSingle.lyricist)
            
        })
    }
    
    func testPostDeleteSingle() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.DELETE, "singles/\(single.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testDeleteSingleNotFound() throws {
        let single = createSingle(track: 1, title: "Body and Soul", filename: "body&soul.mp3")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.DELETE, "singles/\(single.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
    }
    
    func testPostGetAlbumFiles() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        // POST Liszt album
        let album = createLisztAlbum()
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "albums/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        
        // POST album files
        if let directory = album.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            // POST artwork
            let frontFilename = album.frontArtRef()?.filename ?? "front.jpg"
            let fileURL = dirURL.appendingPathComponent(frontFilename)
            let fm = FileManager.default
            let data = fm.contents(atPath: fileURL.path)
            let dataBuf = ByteBuffer(data: data ?? Data())

            try app.test(.POST, "albums/\(album.id)/\(frontFilename)",
                         headers: HTTPHeaders([("Content-Type", "application/jpeg")]),
                         body: dataBuf, afterResponse: { res in
                            XCTAssertEqual(res.status, .ok)
                         })
            
            for content in album.contents {
                if let single = content.single {
                    // post single audio file
                    if let audiofileName = single.audiofileRef {
                        let fileURL = dirURL.appendingPathComponent(audiofileName)
                        let data = fm.contents(atPath: fileURL.path)
                        let dataBuf = ByteBuffer(data: data ?? Data())
                        
                        try app.test(.POST, "albums/\(album.id)/\(audiofileName)",
                                     headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                                     body: dataBuf, afterResponse: { res in
                                        XCTAssertEqual(res.status, .ok)
                                     })
                    }
                } else if let composition = content.composition {
                    for movement in composition.movements {
                        // post movement audio file
                        if let audiofileName = movement.audiofileRef {
                            let fileURL = dirURL.appendingPathComponent(audiofileName)
                            let data = fm.contents(atPath: fileURL.path)
                            let dataBuf = ByteBuffer(data: data ?? Data())
                            
                            try app.test(.POST, "albums/\(album.id)/\(audiofileName)",
                                         headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                                         body: dataBuf, afterResponse: { res in
                                            XCTAssertEqual(res.status, .ok)
                                         })
                        }
                    }
                }
            }

        }

        // GET and verify album
        try app.test(.GET, "albums/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(album.title, newAlbum.title)
            XCTAssertEqual(album.subtitle, newAlbum.subtitle)
            XCTAssertEqual(album.artist, newAlbum.artist)
            XCTAssertEqual(album.composer, newAlbum.composer)
            XCTAssertEqual(album.conductor, newAlbum.conductor)
            XCTAssertEqual(album.orchestra, newAlbum.orchestra)
            XCTAssertEqual(album.lyricist, newAlbum.lyricist)
            XCTAssertEqual(album.publisher, newAlbum.publisher)
            XCTAssertEqual(album.genre, newAlbum.genre)
            XCTAssertEqual(album.copyright, newAlbum.copyright)
            XCTAssertEqual(album.encodedBy, newAlbum.encodedBy)
            XCTAssertEqual(album.encoderSettings, newAlbum.encoderSettings)
            XCTAssertEqual(album.recordingYear, newAlbum.recordingYear)
            XCTAssertEqual(album.directory, newAlbum.directory)
            XCTAssertEqual(album.frontArtRef(), newAlbum.frontArtRef())
            XCTAssertEqual(album.contents.count, newAlbum.contents.count)
            for index in 0..<album.contents.count {
                XCTAssertEqual(album.contents[index].id, newAlbum.contents[index].id)
                XCTAssertEqual(album.contents[index].disk, newAlbum.contents[index].disk)
                XCTAssertEqual(album.contents[index].track, newAlbum.contents[index].track)
                if let comp1 = album.contents[index].composition,
                   let comp2 = newAlbum.contents[index].composition {
                    XCTAssertEqual(comp1.id, comp2.id)
                    XCTAssertEqual(comp1.startTrack, comp2.startTrack)
                    XCTAssertEqual(comp1.title, comp2.title)
                }

            }
        })

        // GET and verify related files
        if let directory = album.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            // post artwork
            let frontFilename = album.frontArtRef()?.filename ?? "front.jpg"
            let fileURL = dirURL.appendingPathComponent(frontFilename)
            let fm = FileManager.default
            let data = fm.contents(atPath: fileURL.path) ?? Data()
            let dataBuf = ByteBuffer(data: data)

            try app.test(.GET, "albums/\(album.id)/\(frontFilename)", afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.body, dataBuf)
            })
            
            for content in album.contents {
                if let single = content.single {
                    let audioFilename = single.audiofileRef ?? ""
                    let fileURL = dirURL.appendingPathComponent(audioFilename)
                    let data = fm.contents(atPath: fileURL.path) ?? Data()
                    let dataBuf = ByteBuffer(data: data)
                    
                    try app.test(.GET, "albums/\(album.id)/\(audioFilename)", afterResponse: { res in
                        XCTAssertEqual(res.status, .ok)
                        XCTAssertEqual(res.body, dataBuf)
                    })
                } else if let composition = content.composition {
                    for movement in composition.movements {
                        let audioFilename = movement.audiofileRef ?? ""
                        let fileURL = dirURL.appendingPathComponent(audioFilename)
                        let data = fm.contents(atPath: fileURL.path) ?? Data()
                        let dataBuf = ByteBuffer(data: data)
                        
                        try app.test(.GET, "albums/\(album.id)/\(audioFilename)", afterResponse: { res in
                            XCTAssertEqual(res.status, .ok)
                            XCTAssertEqual(res.body, dataBuf)
                        })
                    }
                }
            }

        }
    }

    func testPostGetSingleFiles() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        // POST Liszt single
        let single = createLisztSingle()
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "singles/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        
        // POST single audio file
        if let directory = single.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            
            let fm = FileManager.default

            // post single audio file
            if let audiofileName = single.audiofileRef {
                let fileURL = dirURL.appendingPathComponent(audiofileName)
                let data = fm.contents(atPath: fileURL.path)
                let dataBuf = ByteBuffer(data: data ?? Data())
                
                try app.test(.POST, "singles/\(single.id)/\(audiofileName)",
                             headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                             body: dataBuf, afterResponse: { res in
                                XCTAssertEqual(res.status, .ok)
                             })
            }
        }

        // GET and verify single
        try app.test(.GET, "singles/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(single.title, newSingle.title)
            XCTAssertEqual(single.subtitle, newSingle.subtitle)
            XCTAssertEqual(single.artist, newSingle.artist)
            XCTAssertEqual(single.composer, newSingle.composer)
            XCTAssertEqual(single.conductor, newSingle.conductor)
            XCTAssertEqual(single.orchestra, newSingle.orchestra)
            XCTAssertEqual(single.lyricist, newSingle.lyricist)
            XCTAssertEqual(single.publisher, newSingle.publisher)
            XCTAssertEqual(single.genre, newSingle.genre)
            XCTAssertEqual(single.copyright, newSingle.copyright)
            XCTAssertEqual(single.encodedBy, newSingle.encodedBy)
            XCTAssertEqual(single.encoderSettings, newSingle.encoderSettings)
            XCTAssertEqual(single.recordingYear, newSingle.recordingYear)
            XCTAssertEqual(single.directory, newSingle.directory)
        })

        // GET and verify audio file
        if let directory = single.directory {
            let fm = FileManager.default
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
                let audioFilename = single.audiofileRef ?? ""
                let fileURL = dirURL.appendingPathComponent(audioFilename)
                let data = fm.contents(atPath: fileURL.path) ?? Data()
                let dataBuf = ByteBuffer(data: data)
                
                try app.test(.GET, "singles/\(single.id)/\(audioFilename)", afterResponse: { res in
                    XCTAssertEqual(res.status, .ok)
                    XCTAssertEqual(res.body, dataBuf)
                })

        }
    }

}