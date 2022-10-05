//
//  ViewController.swift
//  AssignmentTwo
//
//  Created by Muhammad Ashraf on 9/27/22.
//

import UIKit

class ViewController: UIViewController {
    
    let audio = AudioModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        audio.startMicrophoneProcessing()
        
        audio.play()
    }

    
//
//    @IBAction func ModA(_ sender: Any) {
//        let storyboard = UIStoryboard(name: "Main",
//                                      bundle: nil)
//        let secondController = storyboard.instantiateViewController(withIdentifier: "modAController")
//        secondController.view.backgroundColor = .systemRed
//        self.present(secondController, animated: true, completion: nil)
//        print("A clicked")
//    }
//    @IBAction func ModB(_ sender: Any) {
//        let storyboard = UIStoryboard(name: "Main",
//                                      bundle: nil)
//        let thirdController = storyboard.instantiateViewController(withIdentifier: "modBController")
//        thirdController.view.backgroundColor = .systemBrown
//        self.present(thirdController, animated: true, completion: nil)
//        print("B clicked")
//    }
}

