//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson
//  Copyright © 2020 Eric Larson. All rights reserved.


import UIKit
import Metal





class SecondViewController: UIViewController {

    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*16 // This is the correct buffer size. Fight me and I'll bring the maths
    }
    
    // setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // uncomment this function if you want to show the graphs
        showGraphs()
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing(withFps: 10)

        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
       
    }
    
    func showGraphs(){
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            // add in graphs for display
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

            graph.addGraph(withName: "time",
                numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            graph.addGraph(withName: "avg", numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

            graph.makeGrids() // add grids to graph
        }
    }
    
    // periodically, update the graph with refreshed FFT Data
    @objc
    func updateGraph(){
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
        self.graph?.updateGraph(data: self.audio.highestFreq, forKey: "avg")
        
    }
    
    

}
