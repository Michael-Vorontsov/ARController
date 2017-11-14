//
//  ObjectDraggingSceneController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 11/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import ARKit
import ARController

class ObjectDraggingSceneController: UIViewController, ARSCNViewDelegate, SceneControlling, ErrorReporting, TextManaging, SimpleObjectTracking , PanGestureRecognisable {

    @IBOutlet weak var sceneView: ARSCNView!
    weak var textManager: TextManager?

    var enabled: Bool = false { didSet {enableDidChange() }}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let parentContoller = navigationController?.parent as? ViewController {
            parentContoller.sceneController = self
        }
        enableDidChange()
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func  enableDidChange() {
        if enabled {
            let configuarion = self.sceneView.session.configuration ?? ARWorldTrackingConfiguration()
            
            self.sceneView.session.run(configuarion, options: [])
        }
        else {
            self.sceneView.session.pause()
        }
    }
    
    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear;
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    weak var trackedObject: VirtualObject?
    weak var draggedObjectSourceController: DragSourceProtocol?
    weak var hoverOverController: DragOverProtocol?
    
    @IBAction func dragObject(_ sender: UIPanGestureRecognizer) {
        processPanGestureAction(sender)
    }
    
    @IBAction func restartExperience(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIApplication.shared.sendAction(#selector(ObjectDraggingSceneController.restartExperience(_:)), to: nil, from: nil, for: nil)
            }
        }
    }
    
}
