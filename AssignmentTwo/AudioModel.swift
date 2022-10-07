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
    
    // Function which returns the frequency in the windowed average
    // of the highest amplitude frequency
    func getHighestAmplitudeFrequency() -> Float{
        // store the highest value. Starts with the first value in the array
        var highest = highestFreq[0]
        var highestIndex = 0
        // skip the first element since it is already set to highest here, then loop over all indices of highestFreq
        for i in 1...((BUFFER_SIZE/2) - 1){
            // if the new value is higher than our stored one
            if (highestFreq[i] > highest){
                highest = highestFreq[i]
                highestIndex = i
            }
        }
        
        // Calculate the frequency of the highest index
        // To do this, we just divide our sampling rate of 24000 by the size of our fft array
        // and then multiply that number by our index
        let stride = ( (Float(24000)) / (Float((BUFFER_SIZE/2))) )
        
        // find the index of the peak
        // take the beginning and the end of the window of size 10
//        let endIndex = highestIndex+9
//        let midIndex = highestIndex+4
        
        // now use the equation to find the approximate middle index
        
        
        return (Float(stride) * (Float(highestIndex)) )
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
    
    private func takeWindowedAverageOfFFT(windowSize:Int){
        // iterate over every value of the fft
        for i in (windowSize/2)...((BUFFER_SIZE/2) - 1 - (windowSize/2)) {
            var highest = fftData[i]
            
            // Check the values windowSize/2 below and windowSize/2 above
            for x in 1...(windowSize/2) {
                // if the value in the window is higher than the highest value, set it
                if (fftData[i-x] > highest) {
                    highest = fftData[i-x]
                }
                if (fftData[i+x] > highest) {
                    highest = fftData[i-x]
                }
            }
            
            //at the end of the window, set the value at that index to the highest found in that window
            highestFreq[i] = highest
        }
        
        // set the first (windowSize/2) elements
        let setMeBegin = highestFreq[windowSize/2]
        for i in 0...((windowSize/2) - 1){
            highestFreq[i] = setMeBegin
        }
        
        // set the last (windowSize/2) elements
        let setMe = highestFreq[(BUFFER_SIZE/2)-1 - windowSize/2]
        for i in ((BUFFER_SIZE/2) - windowSize/2)...((BUFFER_SIZE/2)-1){
            highestFreq[i] = setMe
        }
    }
    
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
            self.takeWindowedAverageOfFFT(windowSize:10)
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
