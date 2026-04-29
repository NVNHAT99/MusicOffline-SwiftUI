import Foundation

// MARK: - DIContainer.UseCases
extension DIContainer {

    public struct UseCases {
        // MARK: - Song
        let fetchSongUseCase: FetchSongUseCaseProtocol
        let addSongUseCase: AddSongUseCaseProtocol
        let updateSongUseCase: UpdateSongUseCaseProtocol
        let deleteSongUseCase: DeleteSongUseCaseProtocol
        let songMetadataRepository: SongMetadataRepositoryProtocol
        let completedUploadSongUseCase: CompletedUploadSongUseCaseProtocol

        // MARK: - Playlist
        let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
        let addPlaylistUseCase: AddPlaylistUseCaseProtocol
        let updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol
        let deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol
        let reorderPlaylistSongsUseCase: ReorderPlaylistSongsUseCaseProtocol
        let importSongFromFilesUseCase: ImportSongFromFilesUseCaseProtocol

        // MARK: - Lyrics
        let lyricsRepository: LyricsRepositoryProtocol
        let fetchLyricsUseCase: FetchLyricsUseCaseProtocol

        // MARK: - Smart Playlist
        let smartPlaylistRepository: SmartPlaylistRepositoryProtocol
        let saveSmartPlaylistUseCase: SaveSmartPlaylistUseCaseProtocol
        let smartPlaylistUseCase: SmartPlaylistUseCase

        // MARK: - Composite
        let fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol
        let transferUseCase: TransferUseCaseProtocol

        // MARK: - Upload
        let uploadSongUseCase: UploadSongUseCaseProtocol
        let manageWebUploaderUseCase: ManageWebUploaderUseCaseProtocol

        init(
            fetchSongUseCase: FetchSongUseCaseProtocol,
            addSongUseCase: AddSongUseCaseProtocol,
            updateSongUseCase: UpdateSongUseCaseProtocol,
            deleteSongUseCase: DeleteSongUseCaseProtocol,
            songMetadataRepository: SongMetadataRepositoryProtocol,
            completedUploadSongUseCase: CompletedUploadSongUseCaseProtocol,
            fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol,
            addPlaylistUseCase: AddPlaylistUseCaseProtocol,
            updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol,
            deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol,
            reorderPlaylistSongsUseCase: ReorderPlaylistSongsUseCaseProtocol,
            importSongFromFilesUseCase: ImportSongFromFilesUseCaseProtocol,
            fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol,
            transferUseCase: TransferUseCaseProtocol,
            uploadSongUseCase: UploadSongUseCaseProtocol,
            manageWebUploaderUseCase: ManageWebUploaderUseCaseProtocol,
            lyricsRepository: LyricsRepositoryProtocol,
            fetchLyricsUseCase: FetchLyricsUseCaseProtocol,
            smartPlaylistRepository: SmartPlaylistRepositoryProtocol,
            saveSmartPlaylistUseCase: SaveSmartPlaylistUseCaseProtocol,
            smartPlaylistUseCase: SmartPlaylistUseCase
        ) {
            self.fetchSongUseCase = fetchSongUseCase
            self.addSongUseCase = addSongUseCase
            self.updateSongUseCase = updateSongUseCase
            self.deleteSongUseCase = deleteSongUseCase
            self.songMetadataRepository = songMetadataRepository
            self.completedUploadSongUseCase = completedUploadSongUseCase
            self.fetchPlaylistUseCase = fetchPlaylistUseCase
            self.addPlaylistUseCase = addPlaylistUseCase
            self.updatePlaylistUseCase = updatePlaylistUseCase
            self.deletePlaylistUseCase = deletePlaylistUseCase
            self.reorderPlaylistSongsUseCase = reorderPlaylistSongsUseCase
            self.importSongFromFilesUseCase = importSongFromFilesUseCase
            self.fetchHomeDataUseCase = fetchHomeDataUseCase
            self.transferUseCase = transferUseCase
            self.uploadSongUseCase = uploadSongUseCase
            self.manageWebUploaderUseCase = manageWebUploaderUseCase
            self.lyricsRepository = lyricsRepository
            self.fetchLyricsUseCase = fetchLyricsUseCase
            self.smartPlaylistRepository = smartPlaylistRepository
            self.saveSmartPlaylistUseCase = saveSmartPlaylistUseCase
            self.smartPlaylistUseCase = smartPlaylistUseCase
        }

        static func create(
            songRepository: SongRepositoryProtocol,
            playlistRepository: PlaylistRepositoryProtocol,
            songMetadataRepository: SongMetadataRepositoryProtocol,
            webServerService: WebServerGCDServiceProtocol,
            coreDataManager: CoreDataProtocol
        ) -> UseCases {
            let fetchSong = FetchSongUseCase(repository: songRepository)
            let addSong = AddSongUseCase(repository: songRepository)
            let updateSong = UpdateSongUseCase(songRepository: songRepository)
            let deleteSong = DeleteSongUseCase(repository: songRepository)
            let completedUpload = CompletedUploadSongUseCase(
                repository: songRepository,
                songMetadataRepository: songMetadataRepository
            )
            let fetchPlaylist = FetchPlaylistUseCase(repository: playlistRepository)
            let addPlaylist = AddPlaylistUseCase(repository: playlistRepository)
            let updatePlaylist = UpdatePlaylistUseCase(repository: playlistRepository)
            let deletePlaylist = DeletetPlaylistUseCase(repository: playlistRepository)
            let reorderSongs = ReorderPlaylistSongsUseCase(repository: playlistRepository)
            let lyricsRepo = LyricsRepository()
            let fetchLyrics = FetchLyricsUseCase(repository: lyricsRepo)
            let importSong = ImportSongFromFilesUseCase(addSongUseCase: addSong, lyricsRepository: lyricsRepo)
            let smartPlaylistRepo = SmartPlaylistRepository(coreData: coreDataManager)
            let saveSmartPlaylist = SaveSmartPlaylistUseCase(repository: smartPlaylistRepo)
            let smartPlaylist = SmartPlaylistUseCase(coreData: coreDataManager)
            let fetchHome = FetchHomeDataUseCase(fetchSongUseCase: fetchSong, fetchPlaylistUseCase: fetchPlaylist)
            let transfer = TransferUseCase(
                addSongUseCase: addSong,
                updateSongUseCase: updateSong,
                deleteSongUseCase: deleteSong,
                coreDataService: coreDataManager,
                repository: playlistRepository
            )
            let uploadSong = UploadSongUseCase(service: webServerService)
            let manageUploader = ManageWebUploaderUseCase(service: webServerService)

            return UseCases(
                fetchSongUseCase: fetchSong,
                addSongUseCase: addSong,
                updateSongUseCase: updateSong,
                deleteSongUseCase: deleteSong,
                songMetadataRepository: songMetadataRepository,
                completedUploadSongUseCase: completedUpload,
                fetchPlaylistUseCase: fetchPlaylist,
                addPlaylistUseCase: addPlaylist,
                updatePlaylistUseCase: updatePlaylist,
                deletePlaylistUseCase: deletePlaylist,
                reorderPlaylistSongsUseCase: reorderSongs,
                importSongFromFilesUseCase: importSong,
                fetchHomeDataUseCase: fetchHome,
                transferUseCase: transfer,
                uploadSongUseCase: uploadSong,
                manageWebUploaderUseCase: manageUploader,
                lyricsRepository: lyricsRepo,
                fetchLyricsUseCase: fetchLyrics,
                smartPlaylistRepository: smartPlaylistRepo,
                saveSmartPlaylistUseCase: saveSmartPlaylist,
                smartPlaylistUseCase: smartPlaylist
            )
        }
    }
}
