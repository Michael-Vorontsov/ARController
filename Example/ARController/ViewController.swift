/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import Foundation
import SceneKit
import UIKit
import Photos
import ARController

protocol SettingsConfugurable: class {
    func updateSettings()
    func subsctibeForSettingsUpdate() -> Any
}

extension SettingsConfugurable {
    func subsctibeForSettingsUpdate() -> Any {
        let token = NotificationCenter.default.addObserver(
            forName:  UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: OperationQueue.main)
        { [weak self] _ in self?.updateSettings() }
        return token
    }
}

class ViewController: UIViewController, SettingsConfugurable, TextManagerContaining {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var debugMessageLabel: UILabel!

    var notificationSubscriptionTokens = [Any]()

    var textManager: TextManager? { didSet { (self.sceneController as? TextManaging)?.textManager = textManager } }
    
    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet {
            debugMessageLabel.isHidden = !showDebugVisuals
            
            if showDebugVisuals {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            } else {
                sceneView.debugOptions = []
            }
            
            // save pref
            if oldValue != showDebugVisuals {
                UserDefaults.standard.set(showDebugVisuals, for: .debugMode)
            }
        }
    }
    var sceneController: SceneControlling? {
        didSet {

            oldValue?.sceneView = nil
            
            // Inject scene view
            sceneView.delegate = nil
            sceneController?.sceneView = sceneView

            // Inject text manager
            if let textManaging = sceneController as? TextManaging {
                textManaging.textManager = self.textManager
            }

            // Enable scene
            sceneController?.enabled = true
            sceneController?.setupScene()
        }
    }
	
    // MARK: - Main Setup & View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		sceneController?.enabled = true
        notificationSubscriptionTokens.append( subsctibeForSettingsUpdate() )
        updateSettings()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        sceneController?.enabled = false
        notificationSubscriptionTokens.removeAll()
	}
    
    func setupView() {
        Setting.registerDefaults()
        setupUIControls()
        setupDebug()
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        // Setup ligh environment
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        
    }
  
    func setupUIControls() {
        textManager = TextManager(viewController: self)
        
        // hide debug message view
        debugMessageLabel.isHidden = true
        debugMessageLabel.text = ""
        messageLabel.text = ""
    }
    
    func setupDebug() {
        // Set appearance of debug output panel
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
    }
    
    func updateSettings() {
        guard  isViewLoaded else { return }

        let defaults = UserDefaults.standard
        showDebugVisuals = defaults.bool(for: .debugMode)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sceneController = segue.destination as? SceneControlling {
            self.sceneController = sceneController
        }
        if let navController = segue.destination as? UINavigationController,
            let sceneController = navController.topViewController as? SceneControlling {
            self.sceneController = sceneController
        }

        super.prepare(for: segue, sender: sender)
    }
    
}
extension ViewController: UIPopoverPresentationControllerDelegate {
    
    @IBAction func showSettings(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as? SettingsViewController else {
            return
        }
        
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
        settingsViewController.title = "Options"
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.delegate = self
        navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
        self.present(navigationController, animated: true, completion: nil)
        
        navigationController.popoverPresentationController?.sourceView = sender as? UIButton
        navigationController.popoverPresentationController?.sourceRect = (sender as? UIButton)?.bounds ?? CGRect.zero
    }
    
    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        //        (sceneController as? SceneController).updateSettings()
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    }
}
