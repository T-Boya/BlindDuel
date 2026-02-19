import UIKit
import AVFoundation

/// Left/right audio calibration screen.
/// Plays a sound from the left channel, then the right, so the user can confirm
/// their headphones are oriented correctly and spatial audio is working.
final class CalibrationViewController: UIViewController {
    
    // MARK: - UI
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Headphone Calibration"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to play a sound from the LEFT"
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play Sound", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Play calibration sound"
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.accessibilityLabel = "Finish calibration"
        return button
    }()
    
    // MARK: - State
    
    private enum CalibrationPhase {
        case left
        case right
        case done
    }
    
    private var phase: CalibrationPhase = .left
    
    // MARK: - Audio (simple stereo panning via AVAudioEngine)
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let environmentNode = AVAudioEnvironmentNode()
    
    // MARK: - Callback
    
    var onDone: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        setupAudio()
        
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine.stop()
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(instructionLabel)
        view.addSubview(statusLabel)
        view.addSubview(playButton)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 56),
            
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
        ])
    }
    
    // MARK: - Audio Setup
    
    private func setupAudio() {
        engine.attach(playerNode)
        engine.attach(environmentNode)
        engine.connect(playerNode, to: environmentNode, format: nil)
        engine.connect(environmentNode, to: engine.mainMixerNode, format: nil)
        
        playerNode.renderingAlgorithm = .HRTFHQ
        
        do {
            try engine.start()
        } catch {
            print("[Calibration] Audio engine failed: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @objc private func playTapped() {
        switch phase {
        case .left:
            playCalibrationSound(direction: -1.0)
            statusLabel.text = "Did you hear it on the LEFT?\n\nTap to play from the RIGHT"
            phase = .right
            
        case .right:
            playCalibrationSound(direction: 1.0)
            statusLabel.text = "Did you hear it on the RIGHT?\n\nCalibration complete!"
            phase = .done
            playButton.isHidden = true
            doneButton.isHidden = false
            
        case .done:
            break
        }
    }
    
    @objc private func doneTapped() {
        engine.stop()
        onDone?()
    }
    
    private func playCalibrationSound(direction: Float) {
        playerNode.position = AVAudio3DPoint(x: direction * 3.0, y: 0, z: -1.0)
        
        // Generate a simple tone as calibration sound
        guard let buffer = generateToneBuffer() else { return }
        
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }
    
    /// Generate a simple sine wave tone for calibration.
    private func generateToneBuffer() -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frequency: Double = 440 // A4
        let duration: Double = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Sine wave with fade in/out
            let envelope = min(t / 0.05, 1.0) * min((duration - t) / 0.05, 1.0)
            data[i] = Float(sin(2.0 * .pi * frequency * t) * 0.5 * envelope)
        }
        
        return buffer
    }
}
