//
//  ViewController.swift
//  AssignmentTwo
//
//  Created by Muhammad Ashraf on 9/27/22.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
    }


    @IBAction func ModA(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        storyboard.instantiateViewController(withIdentifier: <#T##String#>)
        print("A clicked")
    }
    @IBAction func ModB(_ sender: Any) {
        print("B clicked")
    }
}

