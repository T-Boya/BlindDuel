import UIKit
import AVFoundation

/// First-launch onboarding screen.
/// Explains that the game uses sound and touch only, and checks for headphones.
final class OnboardingViewController: UIViewController {
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Blind Duel"
        label.font = UIFont.systemFont(ofSize: 42, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "This game has no visuals during combat.\n\nAll feedback is through sound and touch.\n\nPlug in headphones to begin."
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let headphoneStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Continue to main menu"
        return button
    }()
    
    // MARK: - Callback
    
    var onContinue: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        updateHeadphoneStatus()
        
        // Listen for route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(headphoneStatusLabel)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            headphoneStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            headphoneStatusLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }
    
    // MARK: - Headphone Detection
    
    private func updateHeadphoneStatus() {
        let headphonesConnected = isHeadphonesConnected()
        
        if headphonesConnected {
            headphoneStatusLabel.text = "✓ Headphones connected"
            headphoneStatusLabel.textColor = .systemGreen
            continueButton.isEnabled = true
            continueButton.alpha = 1.0
        } else {
            headphoneStatusLabel.text = "⚠ No headphones detected"
            headphoneStatusLabel.textColor = .systemOrange
            // Still allow continue — user might be testing on speaker
            continueButton.isEnabled = true
            continueButton.alpha = 0.7
        }
    }
    
    private func isHeadphonesConnected() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        return route.outputs.contains { output in
            output.portType == .headphones ||
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothLE ||
            output.portType == .bluetoothHFP
        }
    }
    
    // MARK: - Actions
    
    @objc private func continueTapped() {
        UserDefaults.standard.set(true, forKey: "BlindDuel.hasOnboarded")
        onContinue?()
    }
    
    @objc private func audioRouteChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateHeadphoneStatus()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
