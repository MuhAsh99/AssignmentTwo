//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson
//  Copyright © 2020 Eric Larson. All rights reserved.


import UIKit
import Metal





class ThirdViewController: UIViewController {

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
        
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            // add in graphs for display
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: 720)
            
            graph.addGraph(withName: "time",
                numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            graph.makeGrids() // add grids to graph
            
            // start up the audio model here, querying microphone
            audio.startMicrophoneProcessing(withFps: 10)
            
            //function for playing sin wave
            //setting frequency to middle value of range
            audio.startProcessingSinewaveForPlayback(withFreq: 19000)

            audio.play()
        }
        
       
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        
        // Check for motion periodically
        Timer.scheduledTimer(timeInterval: 0.08, target: self,
            selector: #selector(self.updateMotion),
            userInfo: nil,
            repeats: true)
    }
    
    //slider and label added for frequency of in-audible tone and motion detection
    @IBOutlet weak var freqLabel: UILabel!
    @IBAction func freqSlider(_ sender: UISlider) {
       //change frequency being played
        audio.startProcessingSinewaveForPlayback(withFreq: sender.value)
    }
    
    // periodically, update label with motion recognition
    @objc
    func updateMotion(){
        let val = audio.getHandMotion()
        switch(val) {
        case 1:
            freqLabel.text = String(format:"Hand moving away.\nVolume: %.1f dB\nFrequency: %.1f kHz",self.audio.getFreqVolume(), self.audio.sineFrequency/1000)
            break
        case 2:
            freqLabel.text = String(format:"Hand moving closer.\nVolume: %.1f dB\nFrequency: %.1f kHz",self.audio.getFreqVolume(), self.audio.sineFrequency/1000)
            break
        default:
            freqLabel.text = String(format:"No motion detected.\nVolume: %.1f dB\nFrequency: %.1f kHz",self.audio.getFreqVolume(), self.audio.sineFrequency/1000)
        }
    }
    
    
    // periodically, update the graph with refreshed FFT Data
    @objc
    func updateGraph(){
        self.graph?.updateGraph(
            // zoomed in fft data
            data: Array(self.audio.fftData[6130...6850]),
            forKey: "fft"
        )
        
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
    }
}
