//
//  MainViewController.swift
//  Speech Recognizer
//
//  Created by Ryan Rottmann on 8/30/19.
//  Copyright © 2019 Ryan Rottmann. All rights reserved.
//

import UIKit
import Speech

class MainViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textBox: UITextView!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var recordingText: UILabel!
    
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "en-us"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordingText.text = ""
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization{
            status in
            var buttonState = false
            switch status{
            case . authorized:
                buttonState = true
                print ("permission recieved")
            case .denied:
                buttonState = false
                print(".denied")
            case .notDetermined:
                buttonState = false
                print(".notDetermined")
            case .restricted:
                buttonState = false
                print(".restricted")
            @unknown default:
                buttonState = false
                print("default")
            }
        }
        
        // Do any additional setup after loading the view.
    }

    func startRecording(){
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch{
            print("failed to setup audio session")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError()
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest){
            result, error in
            var isLast = false
            if result != nil {
                isLast = (result?.isFinal)!
            }
            if error != nil || isLast{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.start.isEnabled = true
                
                print(result?.transcriptions)
                
                let bestTranscription = result?.bestTranscription.formattedString
                /*
                if(bestTranscription) != nil {
                    self.textBox.text = bestTranscription
                } else {
                    self.textBox.text = "Did not translate"
                }*/
                var transcribed = ""
                if bestTranscription != nil{
                     transcribed = bestTranscription!
                } else {
                    print(bestTranscription)
                    print("incorrect")
                    self.textBox.text = "Did not translate"
                    self.recordingText.text = ""
                    return
                }
                print(transcribed)
                
                if (transcribed == "Adventure" || transcribed == "Apple" || transcribed == "Development"){
                    print("correct")
                    self.textBox.text = transcribed
                    self.recordingText.text = "Special Keyword!"
                } else {
                    self.textBox.text = transcribed
                    self.recordingText.text = ""
                }
                print(transcribed)
            }
            
        }
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format){
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do{
            try audioEngine.start()
        } catch{
            print ("Can't start the engine")
        }
    }


    @IBAction func startButtonPress(_ sender: Any) {
        if audioEngine.isRunning == false{
            startRecording()
            recordingText.text = "Recording"
        }
    }

    @IBAction func stopButton(_ sender: Any) {
        if audioEngine.isRunning{
            audioEngine.stop()
            recognitionRequest?.endAudio()
            start.isEnabled = false
            
            //start.setTitle("Record", for: .normal)
        }
    }

}
