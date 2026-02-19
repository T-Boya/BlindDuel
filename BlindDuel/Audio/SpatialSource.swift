import AVFoundation

/// Wraps an AVAudioPlayerNode positioned in 3D space.
/// Manages loading, playing, and repositioning a single spatial audio source.
final class SpatialSource {
    
    /// The underlying player node.
    let playerNode: AVAudioPlayerNode
    
    /// The audio buffer for this source (loaded from file).
    private var buffer: AVAudioPCMBuffer?
    
    /// Current 3D position.
    var position: AVAudio3DPoint {
        didSet {
            playerNode.position = position
        }
    }
    
    /// Reverb blend (0 = dry, 1 = fully reverberant).
    var reverbBlend: Float {
        didSet {
            playerNode.reverbBlend = reverbBlend
        }
    }
    
    /// The rendering algorithm for spatialization.
    var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm {
        didSet {
            playerNode.renderingAlgorithm = renderingAlgorithm
        }
    }
    
    /// Volume (0–1).
    var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = newValue }
    }
    
    init() {
        self.playerNode = AVAudioPlayerNode()
        self.position = AVAudio3DPoint(x: 0, y: 0, z: 0)
        self.reverbBlend = 0
        self.renderingAlgorithm = .HRTFHQ
    }
    
    /// Load an audio file from the bundle into a buffer.
    /// - Parameters:
    ///   - name: The file name (without extension).
    ///   - ext: The file extension (default: "caf").
    /// - Returns: Whether loading succeeded.
    @discardableResult
    func loadBuffer(named name: String, withExtension ext: String = AudioAssets.fileExtension) -> Bool {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("[SpatialSource] Audio file not found: \(name).\(ext)")
            return false
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            guard let pcmBuffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else {
                print("[SpatialSource] Could not create buffer for: \(name)")
                return false
            }
            try file.read(into: pcmBuffer)
            buffer = pcmBuffer
            return true
        } catch {
            print("[SpatialSource] Error loading \(name): \(error)")
            return false
        }
    }
    
    /// Play the loaded buffer once.
    func playOnce() {
        guard let buffer = buffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }
    
    /// Play the loaded buffer in a loop.
    func playLooping() {
        guard let buffer = buffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }
    
    /// Stop playback.
    func stop() {
        playerNode.stop()
    }
    
    /// Whether the node is currently playing.
    var isPlaying: Bool {
        playerNode.isPlaying
    }
}
