import UIKit

/// Post-round result screen.
/// Shows win/lose, current streak, and options to play again or return to menu.
final class ResultViewController: UIViewController {
    
    // MARK: - Properties
    
    private let result: RoundResult
    
    // MARK: - Callbacks
    
    var onPlayAgain: (() -> Void)?
    var onMenu: (() -> Void)?
    
    // MARK: - UI
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
        return label
    }()
    
    private let streakLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let playAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play Again", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Play another round"
        return button
    }()
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Menu", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Return to main menu"
        return button
    }()
    
    // MARK: - Init
    
    init(result: RoundResult) {
        self.result = result
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
        configureForResult()
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(resultLabel)
        view.addSubview(streakLabel)
        view.addSubview(playAgainButton)
        view.addSubview(menuButton)
        
        NSLayoutConstraint.activate([
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            streakLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            streakLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 16),
            
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.topAnchor.constraint(equalTo: streakLabel.bottomAnchor, constant: 50),
            playAgainButton.widthAnchor.constraint(equalToConstant: 200),
            playAgainButton.heightAnchor.constraint(equalToConstant: 56),
            
            menuButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            menuButton.topAnchor.constraint(equalTo: playAgainButton.bottomAnchor, constant: 20),
        ])
    }
    
    private func configureForResult() {
        let streak = UserDefaults.standard.integer(forKey: "BlindDuel.winStreak")
        
        switch result {
        case .playerWon:
            resultLabel.text = "You Win"
            resultLabel.textColor = .white
            streakLabel.text = "Win Streak: \(streak)"
            
        case .playerLost:
            resultLabel.text = "You Lose"
            resultLabel.textColor = .systemRed
            streakLabel.text = streak > 0 ? "Previous Streak: \(streak)" : ""
        }
    }
    
    // MARK: - Actions
    
    @objc private func playAgainTapped() {
        onPlayAgain?()
    }
    
    @objc private func menuTapped() {
        onMenu?()
    }
}
