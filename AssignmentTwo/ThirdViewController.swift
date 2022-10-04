//
//  ThirdViewController.swift
//  AssignmentTwo
//
//  Created by Muhammad Ashraf on 10/4/22.
//

import UIKit

class ThirdViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        

        // Do any additional setup after loading the view.
    }
    

    @IBAction func doneButtonTapped2(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
