//
//  SecondViewController.swift
//  AssignmentTwo
//
//  Created by Muhammad Ashraf on 10/4/22.
//

import UIKit

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true

        // Do any additional setup after loading the view.
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
