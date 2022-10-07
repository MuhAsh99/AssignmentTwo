//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson
//  Copyright © 2020 Eric Larson. All rights reserved.


import UIKit
import Metal


class SecondViewController: UIViewController {

    @IBOutlet weak var FrequencyLabel: UILabel!
    
    struct AudioConstants{
        // This is the correct buffer size. Fight me and I'll bring the maths
//        static let AUDIO_BUFFER_SIZE = 16384 // or 1024*16 //
        static let AUDIO_BUFFER_SIZE = 32768 // experimental buffer size
    }
    
    // setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uncomment this function if you want to show the graphs
//        showGraphs()
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing(withFps: 10)

        audio.play()
        
        // set up the Frequency to update constantly
        setupFreq()
    }
    
    // periodically, update the displayed frequency
    @objc
    func updateFreq(){
        FrequencyLabel.text = String(self.audio.getHighestAmplitudeFrequency())
    }
    
    func setupFreq(){
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateFreq),
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
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
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
