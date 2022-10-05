//
//  ThirdViewController.swift
//  AssignmentTwo
//
//  Created by Muhammad Ashraf on 10/4/22.
//

import UIKit
import Metal

class ThirdViewController: UIViewController {
    
    // setup some constants we will use
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // setup audio model
    //take out for now
   // let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    
    //added
    let audio = AudioModel()
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.view)
    }()
    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        
        // add in a graph for displaying the audio
        if let graph = self.graph {
            graph.addGraph(withName: "time",
                           numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            graph.makeGrids()
        }
        
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing()

        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        

        

        // Do any additional setup after loading the view.
    }
    

    @IBAction func doneButtonTapped2(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
//    @objc
//    func updateGraph(){
//        // periodically, display the audio data
//        self.graph?.updateGraph(
//            data: self.audio.timeData,
//            forKey: "time"
//        )
//        
//    }
    

}
