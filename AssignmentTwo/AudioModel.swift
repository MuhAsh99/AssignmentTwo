//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    //this is for the sin wave
    private let USE_C_SINE = false
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    var highestFreq:[Float]
    

    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        highestFreq = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
    }
    
    //using this for creating an in-audible sound
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
            sineFrequency = withFreq
            // Two examples are given that use either objective c or that use swift
            //   the swift code for loop is slightly slower thatn doing this in c,
            //   but the implementations are very similar
            if let manager = self.audioManager{

                if USE_C_SINE {
                    // c for loop
                    manager.setOutputBlockToPlaySineWave(sineFrequency)
                }else{
                    // swift for loop
                    manager.outputBlock = self.handleSpeakerQueryWithSinusoid
                }


            }
        }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                                 selector: #selector(self.runEveryInterval),
                                 userInfo: nil,
                                 repeats: true)
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    //==========================================
    // MARK: Private Methods
    // NONE for this model
    
    //==========================================
    // MARK: Model Callback Methods
    @objc
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            
        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
            didSet{
                
                if let manager = self.audioManager {
                    if USE_C_SINE {
                        // if using objective c: this changes the frequency in the novocaine block
                        manager.sineFrequency = sineFrequency
                        
                    }else{
                        // if using swift for generating the sine wave: when changed, we need to update our increment
                        phaseIncrement = Float(2*Double.pi*Double(sineFrequency)/manager.samplingRate)
                    }
                }
            }
        }
        
        // SWIFT SINE WAVE
        // everything below here is for the swift implementation
        // this can be deleted when using the objective c implementation
        private var phase:Float = 0.0
        private var phaseIncrement:Float = 0.0
        private var sineWaveRepeatMax:Float = Float(2*Double.pi)
        
        private func handleSpeakerQueryWithSinusoid(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
            // while pretty fast, this loop is still not quite as fast as
            // writing the code in c, so I placed a function in Novocaine to do it for you
            // use setOutputBlockToPlaySineWave() in Novocaine
            if let arrayData = data{
                var i = 0
                while i<numFrames{
                    arrayData[i] = sin(phase)
                    phase += phaseIncrement
                    if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                    i+=1
                }
            }
        }
    
    
}
