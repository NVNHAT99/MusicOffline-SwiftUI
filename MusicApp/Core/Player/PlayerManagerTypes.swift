import Foundation
import Combine

// MARK: - RepeatMode
enum RepeatMode: Int {
    case none = 0
    case one = 1
    case all = 2
}

// MARK: - PlayerManagerState
struct PlayerManagerState {
    var currentSong: SongModel?
    var isPlaying: Bool = false
    var repeatMode: RepeatMode = .none
    var shuffleEnabled: Bool = false
    var currentTimePlay: TimeInterval = 0
}

// MARK: - PlayerManagerProtocol
@MainActor
protocol PlayerManagerProtocol: ObservableObject {
    var state: PlayerManagerState { get }
    var statePublisher: Published<PlayerManagerState>.Publisher { get }
    var refreshHomePubliser: AnyPublisher<Void, Never> { get }
    var missingFilePublisher: AnyPublisher<String, Never> { get }

    func setCurrentPlaylist(id: UUID) async
    func play(_ playlistId: UUID, songs: [SongModel], songPlay: SongModel) async
    func play(_ playlistId: UUID, songPlay: SongModel) async
    func play(song: SongModel) async
    func play() async
    func pause() async
    func stop() async
    func next() async
    func previous() async
    func toggleShuffle() async
    func setRepeatMode(_ mode: RepeatMode) async
    func scheduleStop(after seconds: TimeInterval) async
    func cancelScheduleStop() async
    func seek(to duration: Double)
}
