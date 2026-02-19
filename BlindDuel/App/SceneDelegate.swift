import UIKit

/// Scene delegate — owns the DependencyContainer and manages the navigation flow.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    /// The composition root — creates and wires all dependencies.
    private let container = DependencyContainer()
    
    /// Navigation controller for screen transitions.
    private var navigationController: UINavigationController!
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Determine starting screen
        let hasOnboarded = UserDefaults.standard.bool(forKey: "BlindDuel.hasOnboarded")
        
        let rootVC: UIViewController
        if hasOnboarded {
            rootVC = makeMenuVC()
        } else {
            rootVC = makeOnboardingVC()
        }
        
        navigationController = UINavigationController(rootViewController: rootVC)
        navigationController.isNavigationBarHidden = true
        navigationController.view.backgroundColor = .black
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    // MARK: - Navigation Flow
    
    private func makeOnboardingVC() -> OnboardingViewController {
        let vc = container.makeOnboardingViewController()
        vc.onContinue = { [weak self] in
            guard let self = self else { return }
            let menuVC = self.makeMenuVC()
            self.navigationController.setViewControllers([menuVC], animated: true)
        }
        return vc
    }
    
    private func makeMenuVC() -> MenuViewController {
        let vc = container.makeMenuViewController()
        
        vc.onStartDuel = { [weak self] difficulty in
            guard let self = self else { return }
            let combatVC = self.makeCombatVC(difficulty: difficulty)
            self.navigationController.pushViewController(combatVC, animated: false)
        }
        
        vc.onCalibration = { [weak self] in
            guard let self = self else { return }
            let calibrationVC = self.makeCalibrationVC()
            self.navigationController.pushViewController(calibrationVC, animated: true)
        }
        
        return vc
    }
    
    private func makeCombatVC(difficulty: Difficulty) -> CombatViewController {
        let vc = container.makeCombatViewController(difficulty: difficulty)
        
        vc.onRoundEnd = { [weak self] result in
            guard let self = self else { return }
            let resultVC = self.makeResultVC(result: result, difficulty: difficulty)
            self.navigationController.setViewControllers(
                [self.makeMenuVC(), resultVC],
                animated: true
            )
        }
        
        return vc
    }
    
    private func makeCalibrationVC() -> CalibrationViewController {
        let vc = container.makeCalibrationViewController()
        vc.onDone = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        return vc
    }
    
    private func makeResultVC(result: RoundResult, difficulty: Difficulty) -> ResultViewController {
        let vc = container.makeResultViewController(result: result)
        
        vc.onPlayAgain = { [weak self] in
            guard let self = self else { return }
            let combatVC = self.makeCombatVC(difficulty: difficulty)
            // Replace result with combat, keeping menu underneath
            if let menuVC = self.navigationController.viewControllers.first {
                self.navigationController.setViewControllers([menuVC, combatVC], animated: false)
            }
        }
        
        vc.onMenu = { [weak self] in
            self?.navigationController.popToRootViewController(animated: true)
        }
        
        return vc
    }
}
