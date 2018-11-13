//
//  ViewController.swift
//  Speech2Text
//
//  Created by Anoop tomar on 4/8/18.
//  Copyright © 2018 Devtechie. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
    
    @IBOutlet weak var outputTextView: UIImageView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var fadedView: UIView!
    @IBOutlet weak var recordingView: UIView!
    @IBOutlet weak var recordedMessage: UITextView!
    
    var memoData: [Memo]!
    
    lazy var speechRecognizer: SFSpeechRecognizer? = {
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            recognizer.delegate = self
            return recognizer
        }
        return nil
    }()
    
    lazy var audioEngine: AVAudioEngine = {
        let audioEngine = AVAudioEngine()
        return audioEngine
    }()
    
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        // request auth
        self.requestAuth()
        
        // init data
        memoData = []
        
        // tableview delegations
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // hide recording views
        self.recordingView.isHidden = true
        self.fadedView.isHidden = true
     
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func requestAuth() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                case .denied, .notDetermined, .restricted:
                    self.recordButton.isEnabled = false
                
                }
            }
        }
    }
    
    @IBAction func didTapRecordButton(sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        } else {
            self.startRecording()
            self.recordingView.isHidden = false
            self.fadedView.alpha = 0.0
            self.fadedView.isHidden = false
            UIView.animate(withDuration: 1.0) {
                self.fadedView.alpha = 1.0
            }
        }
    }
    
    @IBAction func stopRecording(sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
            self.memoData.append(Memo(memoTitle: "New Recording", memoDate: Date(), memoText: self.recordedMessage.text!))
            
            UIView.animate(withDuration: 0.5, animations: {
                self.fadedView.alpha = 0.0
            }) { (finished) in
                self.fadedView.isHidden = true
                self.recordingView.isHidden = true
                self.tableView.reloadData()
            }
        }
    }
    
    func startRecording() {
        
        if let recognitionTask = self.recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
         
        self.recordedMessage.text = ""
        print(recordedMessage.text)
        inputTextView.text = "\(self.recordedMessage.text)"
//        print(sentence, "2222222222")

        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        }catch {
            print(error)
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create a speech audio buffer")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            if let result = result {
                let sentence = result.bestTranscription.formattedString
                self.recordedMessage.text = sentence
              
                isFinal = result.isFinal
                self.inputTextView.text = "\(sentence)"
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.recordButton.isEnabled = true
            }
            
        })
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do{
            try audioEngine.start()
        }catch {
            print(error)
        }
        
    }
   
}

extension ViewController: SFSpeechRecognizerDelegate {}

extension ViewController: UITableViewDelegate {}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memoData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CustomCell
        let memo = memoData[indexPath.row]
        cell.titleLabel.text = memo.memoTitle
        cell.dateLabel.text = memo.memoDate.description
        cell.memoLabel.text = memo.memoText
        print(memo)
        return cell
    }
}
























