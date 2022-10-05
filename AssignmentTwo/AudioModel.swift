
import Foundation
import Accelerate

class AudioModel {

    // MARK: Properties
    private var BUFFER_SIZE:Int
    
    //take out for now
    //private var _timeData:[Float]
    // this is a computed property in swift
    // when asked for, the array will be calculated from the input buffer
    
    //take out for now
//    var timeData:[Float]{
//        get{
//            self.inputBuffer!.fetchFreshData(&_timeData,
//                                             withNumSamples: Int64(BUFFER_SIZE))
//            return _timeData
//        }
//    }

    //take out for now
//    // MARK: Public Methods
//    init(buffer_size:Int) {
//        BUFFER_SIZE = buffer_size
//        // anything not lazily instatntiated should be allocated here
//        _timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
//    }
    
    //added
    init() {
            BUFFER_SIZE = 0 // not setting up any buffers here
        }
    
    //take out for now
//    // public function for starting processing of microphone data
//    func startMicrophoneProcessing(){
//        // setup the microphone to copy to circualr buffer
//        self.audioManager?.inputBlock = self.handleMicrophone
//
//    }

    //added
    // public function for starting processing of microphone data
        func startMicrophoneProcessing(){
            if let manager = self.audioManager{
                // this sets the input block whenever the manager is played
                manager.inputBlock = self.handleMicrophone
            }
        }
    

    //take out for now
//    // You must call this when you want the audio to start being handled by our model
//    func play(){
//        self.audioManager?.play()
//    }
    
    //added
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


//    private lazy var inputBuffer:CircularBuffer? = {
//        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
//                                   andBufferSize: Int64(BUFFER_SIZE))
//    }()


    //==========================================
    // MARK: Private Methods
    // NONE for this model

    //==========================================
    // MARK: Model Callback Methods


    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    
    //take out for now
//    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
//        // copy samples from the microphone into circular buffer
//        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
//    }
    
    //added
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>,
                                       numFrames:UInt32,
                                       numChannels: UInt32) {
            if let arrayData = data{
                // just print out the first audio sample
    //            print(arrayData[0])
                
                // bonus: vDSP example (will cover in next lecture)
                // here is an example using iOS accelerate to quickly handle the array
                // Let's use the accelerate framework
                var max:Float = 0
                vDSP_maxv(arrayData, 1, &max, vDSP_Length(numFrames))
                print(max)
            }
            
        }


}
