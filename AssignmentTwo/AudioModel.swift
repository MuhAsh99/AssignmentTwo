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
    
    private let stride:Float
    
    // The values left and right of the target frequency being used
    // for hand movement detection
    private var leftDopplerAverage:Float
    private var rightDopplerAverage:Float
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    var windowedMaxArray:[Float]
    

    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        leftDopplerAverage = 0
        rightDopplerAverage = 0
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        windowedMaxArray = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        stride = ( (Float(24000)) / (Float((BUFFER_SIZE/2))) )
    }
    
    //using this for creating an in-audible sound
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        self.sineFrequency = withFreq
            // Two examples are given that use either objective c or that use swift
            //   the swift code for loop is slightly slower thatn doing this in c,
            //   but the implementations are very similar
            if let manager = self.audioManager{
                if USE_C_SINE {
                    // c for loop
                    manager.setOutputBlockToPlaySineWave(sineFrequency)
                    
                    // Take a snapshot of the fft data around the played frequency a second
                    // after it is played
                    Timer.scheduledTimer(timeInterval: 1.0, target: self,
                        selector: #selector(self.getDopplerBaseline),
                        userInfo: nil,
                        repeats: false)
                }else{
                    // swift for loop
                    manager.outputBlock = self.handleSpeakerQueryWithSinusoid
                    
                    // Take a snapshot of the fft data around the played frequency a second
                    // after it is played
                    Timer.scheduledTimer(timeInterval: 1.0, target: self,
                        selector: #selector(self.getDopplerBaseline),
                        userInfo: nil,
                        repeats: false)
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
    
    // Pause all audio functions
    func pause(){
        if let manager = self.audioManager{
            manager.pause()
        }
    }
    
//    func getSecondHighestAmplitudeFrequency() -> Float {
//        let highestFrequency = getHighestAmplitudeFrequency()
//
//        var secondHighest = highestFreq[0]
//        var secondHighestIndex = 0
//
//        for i in 1...((BUFFER_SIZE/2) - 1){
//            if (highestFreq[i] > secondHighest && (Int(highestFreq[i]) != Int(highestFrequency))){
//                secondHighest = highestFreq[i]
//                secondHighestIndex = i
//            }
//        }
//
//        return getFreqFromIndex(index: secondHighestIndex)
//    }
    
    // Function which returns the frequency in the windowed average
    // of the highest amplitude frequency, with minAmplitude as the minimum amplitude required. Default is -1000
    func getHighestAmplitudeFrequency(minAmplitude: Float=(Float(-1000))) -> [Float] {
        // store the highest value. Starts with the first value in the array
        var highestCurrentFrequency = Float(0)
        var highestCurrentAmplitude = minAmplitude
        
        var secondHighestCurrentFrequency = Float(0)
        var secondHighestAmplitude = minAmplitude
        
        
        // skip the first element since it is already set to highest here, then loop over all indices of highestFreq
        // Find the highest Freq
        for i in 0...((BUFFER_SIZE/2) - 1){
            let currFreq = getFreqFromIndex(index: i)
            // if this index amplitude is greater than the stored one, and the frequency is higher as well, store the frequency and the amplitude
            if (windowedMaxArray[i] > highestCurrentAmplitude && currFreq > highestCurrentFrequency){
                highestCurrentAmplitude = windowedMaxArray[i]
                highestCurrentFrequency = currFreq
            }
        }
        
        // Find the second highest Freq
        for i in 0...((BUFFER_SIZE/2) - 1){
            let currFreq = getFreqFromIndex(index: i)
            // if this index amplitude is greater than the stored one, and the frequency is higher as well, yet still smaller than the highest frequency by at least 48 (to make sure it is another frequency), store the frequency and the amplitude
            if (windowedMaxArray[i] > secondHighestAmplitude && currFreq > secondHighestCurrentFrequency && (currFreq + 48) < highestCurrentFrequency){
                secondHighestAmplitude = windowedMaxArray[i]
                secondHighestCurrentFrequency = currFreq
            }
        }
        print(highestCurrentAmplitude)
        // return the two highest frequencies
        return [highestCurrentFrequency, secondHighestCurrentFrequency]
    }
    
    // Guesses the motion infront of the phone by comparing the current FFT of the mic data
    // against a snapshot when the tone initially played
    // 0 = no motion, 1 = moving away, 2 = moving towards
    func getHandMotion() -> Int{
        let freq_index = getIndexFromFreq(frequency: sineFrequency)
        let left = getAverageOverWindow(start_index: freq_index-101)
        let right = getAverageOverWindow(start_index: freq_index+1)
        let left_diff = left-leftDopplerAverage
        let right_diff = right-rightDopplerAverage
        let diff = left_diff - right_diff
        if (diff < 2.5 && diff > -2.5) {
            return 0
        } else if (left_diff > right_diff) {
            return 1
        } else if (right_diff > left_diff) {
            return 2
        }
        return 0
    }
    
    // This function calculates the frequency given an index
    // To do this, we just divide our sampling rate of 24000 by the size of our fft array
    // and then multiply that number by our index
    func getFreqFromIndex(index:Int) -> Float{
        return (Float(stride) * (Float(index)) )
    }
    
    // This function calculates the index given a frequency
    // To do this, we just divide the frequency by the sampling rate divided by the size of the fft array
    func getIndexFromFreq(frequency:Float) -> Int{
        return (Int)(frequency/Float(stride))
    }
    
    // Returns volume in decibles of the played tone
    func getFreqVolume() -> Float {
        return fftData[getIndexFromFreq(frequency: self.sineFrequency)]
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
    
    // Take a windowed max of the fft, checking 5 in front and behind
    private func takeWindowedMaxOfFFT(windowSize:Int){
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
            windowedMaxArray[i] = highest
        }
        
        // set the first (windowSize/2) elements
        let setMeBegin = windowedMaxArray[windowSize/2]
        for i in 0...((windowSize/2) - 1){
            windowedMaxArray[i] = setMeBegin
        }
        
        // set the last (windowSize/2) elements
        let setMe = windowedMaxArray[(BUFFER_SIZE/2)-1 - windowSize/2]
        for i in ((BUFFER_SIZE/2) - windowSize/2)...((BUFFER_SIZE/2)-1){
            windowedMaxArray[i] = setMe
        }
    }
    
    // Get the average of particular window in the FFT
    private func getAverageOverWindow(start_index:Int=0) -> Float{
        var sum:Float = 0
        for i in start_index..<start_index+100 {
            sum += fftData[i]
        }
        return sum/100
    }
    
    // Get the averages to the left and right of played frequency
    @objc private func getDopplerBaseline(){
        let freq_index = getIndexFromFreq(frequency: sineFrequency)
        self.leftDopplerAverage = getAverageOverWindow(start_index: freq_index-101)
        self.rightDopplerAverage = getAverageOverWindow(start_index: freq_index+1)
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
            self.takeWindowedMaxOfFFT(windowSize:50)
            
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
    
    var sineFrequency:Float = 18.0 { // frequency in Hz (changeable by user)
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
