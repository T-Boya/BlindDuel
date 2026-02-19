import UIKit

/// Main menu screen.
/// Black background, white text, large tap targets.
/// Options: Quick Duel, Difficulty, Controls, Calibration.
final class MenuViewController: UIViewController {
    
    // MARK: - Dependencies
    
    private let inputManager: InputManager
    private var selectedDifficulty: Difficulty
    
    // MARK: - Callbacks
    
    var onStartDuel: ((Difficulty) -> Void)?
    var onCalibration: (() -> Void)?
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Blind Duel"
        label.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()
    
    private let streakLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var quickDuelButton = makeMenuButton(title: "Quick Duel", accessibilityLabel: "Start a quick duel")
    private lazy var difficultyButton = makeMenuButton(title: "Difficulty: Easy", accessibilityLabel: "Change difficulty")
    private lazy var controlsButton = makeMenuButton(title: "Controls: Touch", accessibilityLabel: "Change control method")
    private lazy var calibrationButton = makeMenuButton(title: "Calibration", accessibilityLabel: "Calibrate headphones")
    
    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [quickDuelButton, difficultyButton, controlsButton, calibrationButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Init
    
    init(inputManager: InputManager, difficulty: Difficulty = .easy) {
        self.inputManager = inputManager
        self.selectedDifficulty = difficulty
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLayout()
        setupActions()
        updateLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLabels()
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(streakLabel)
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            streakLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            streakLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
        ])
    }
    
    private func setupActions() {
        quickDuelButton.addTarget(self, action: #selector(quickDuelTapped), for: .touchUpInside)
        difficultyButton.addTarget(self, action: #selector(difficultyTapped), for: .touchUpInside)
        controlsButton.addTarget(self, action: #selector(controlsTapped), for: .touchUpInside)
        calibrationButton.addTarget(self, action: #selector(calibrationTapped), for: .touchUpInside)
    }
    
    private func updateLabels() {
        let streak = UserDefaults.standard.integer(forKey: "BlindDuel.winStreak")
        streakLabel.text = streak > 0 ? "Win Streak: \(streak)" : ""
        
        difficultyButton.setTitle("Difficulty: \(selectedDifficulty.displayName)", for: .normal)
        
        let controlName = inputManager.activeProvider?.displayName ?? inputManager.availableProviders.first?.displayName ?? "Touch"
        controlsButton.setTitle("Controls: \(controlName)", for: .normal)
    }
    
    // MARK: - Actions
    
    @objc private func quickDuelTapped() {
        onStartDuel?(selectedDifficulty)
    }
    
    @objc private func difficultyTapped() {
        // Cycle through difficulties
        let allCases = Difficulty.allCases
        guard let currentIndex = allCases.firstIndex(of: selectedDifficulty) else { return }
        let nextIndex = (currentIndex + 1) % allCases.count
        selectedDifficulty = allCases[nextIndex]
        difficultyButton.setTitle("Difficulty: \(selectedDifficulty.displayName)", for: .normal)
        
        // Persist
        UserDefaults.standard.set(selectedDifficulty.rawValue, forKey: "BlindDuel.difficulty")
    }
    
    @objc private func controlsTapped() {
        let available = inputManager.availableProviders
        guard available.count > 1 else { return }
        
        // Cycle through available providers
        let currentName = inputManager.activeProvider?.displayName ?? ""
        let currentIndex = available.firstIndex(where: { $0.displayName == currentName }) ?? 0
        let nextIndex = (currentIndex + 1) % available.count
        let nextProvider = available[nextIndex]
        
        inputManager.switchTo(nextProvider, in: view) { [weak self] success in
            if success {
                self?.controlsButton.setTitle("Controls: \(nextProvider.displayName)", for: .normal)
            }
        }
    }
    
    @objc private func calibrationTapped() {
        onCalibration?()
    }
    
    // MARK: - Factory
    
    private func makeMenuButton(title: String, accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = accessibilityLabel
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return button
    }
}
