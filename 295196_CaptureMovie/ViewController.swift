//
//  ViewController.swift
//  avfoundation003
//
//  Copyright © 2016年 FaBo, Inc. All rights reserved.
//  Modified by Jun Yamasita on Oct 10, 2020
//  This code is originally based on http://faboplatform.github.io/SwiftDocs/5.avfoundation/003_avfoundation/
//  Some lines of this program are modified to enable to run this code correctly after iOS 10.0 ,and added codes to save captured image to the Photo library.

import UIKit
import AVFoundation

// MARK: -　フォトライブラリに保存するために必要
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    // ビデオのアウトプット.
    private var myVideoOutput: AVCaptureMovieFileOutput!

    // スタートボタン.
    private var myButtonStart: UIButton!

    // ストップボタン.
    private var myButtonStop: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        // セッションの作成.
        let mySession = AVCaptureSession()

        // デバイス.
        var myDevice = AVCaptureDevice.default(for: .video)

        // 出力先を生成.
        // let myImageOutput = AVCaptureStillImageOutput()
        // MARK: - 'AVCaptureStillImageOutput' was deprecated in iOS 10.0: Use AVCapturePhotoOutput instead.
        // 警告通り、AVCapturePhotoOutput() でインスタンスを生成するよういする
        let myImageOutput = AVCapturePhotoOutput()
        
        // デバイス一覧の取得.
        // let devices = AVCaptureDevice.devices()
        // MARK: - 'devices()' was deprecated in iOS 10.0: Use AVCaptureDeviceDiscoverySession instead.
        // 警告に従うが、警告で出力されているメソッド名が微妙に異なる（AVCaptureDevice.DiscoverySessionが正解）なので注意する
        // 詳しい使い方は公式ドキュメントを参照
        // refer to: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/choosing_a_capture_device
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                        [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
                                                       mediaType: .video, position: .unspecified).devices
        // マイクを取得.
        let audioCaptureDevice = AVCaptureDevice.default(for: .audio)

        // マイクをセッションのInputに追加.
        let audioInput = try! AVCaptureDeviceInput.init(device: audioCaptureDevice!)

        // バックライトをmyDeviceに格納.

        //        for device in devices {
        //            if(device.position == AVCaptureDevice.Position.back){
        //                myDevice = device
        //            }
        //        }
        // MARK: - オリジナルのコードから一部変更。
        guard !devices.isEmpty else { fatalError("選択されたデバイスは存在しません") }
        myDevice = devices.first { $0.position == .back }
        
        // バックカメラを取得.
        let videoInput = try! AVCaptureDeviceInput.init(device: myDevice!)

        // ビデオをセッションのInputに追加.
        mySession.addInput(videoInput)

        // オーディオをセッションに追加.
        mySession.addInput(audioInput)

        // セッションに追加.
        mySession.addOutput(myImageOutput)

        // 動画の保存.
        myVideoOutput = AVCaptureMovieFileOutput()

        // ビデオ出力をOutputに追加.
        mySession.addOutput(myVideoOutput)

        // 画像を表示するレイヤーを生成.
        let myVideoLayer = AVCaptureVideoPreviewLayer.init(session: mySession)
        myVideoLayer.frame = self.view.bounds
        // myVideoLayer.session = myDevice
        myVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Viewに追加.
        self.view.layer.addSublayer(myVideoLayer)

        // セッション開始.
        mySession.startRunning()

        // UIボタンを作成.
        myButtonStart = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        myButtonStop = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        
        myButtonStart.backgroundColor = UIColor.red
        myButtonStop.backgroundColor = UIColor.gray

        myButtonStart.layer.masksToBounds = true
        myButtonStop.layer.masksToBounds = true

        myButtonStart.setTitle("撮影", for: .normal)
        myButtonStop.setTitle("停止", for: .normal)

        myButtonStart.layer.cornerRadius = 20.0
        myButtonStop.layer.cornerRadius = 20.0

        myButtonStart.layer.position = CGPoint(x: self.view.bounds.width/2 - 70, y:self.view.bounds.height-50)
        myButtonStop.layer.position = CGPoint(x: self.view.bounds.width/2 + 70, y:self.view.bounds.height-50)

        myButtonStart.addTarget(self, action: #selector(ViewController.onClickMyButton), for: .touchUpInside)
        myButtonStop.addTarget(self, action: #selector(ViewController.onClickMyButton), for: .touchUpInside)

        // UIボタンをViewに追加.
        self.view.addSubview(myButtonStart)
        self.view.addSubview(myButtonStop)
        
        //
        myButtonStop.isHidden = true
    }

    // MARK:
    func toggleButtonStatus() {
        //
        myButtonStop.isHidden.toggle()
        myButtonStart.isHidden.toggle()
    }
    
    /*
     ボタンイベント.
     */
    @objc internal func onClickMyButton(sender: UIButton){
        // 撮影開始.
        if( sender == myButtonStart ){
            // MARK:
            toggleButtonStatus()
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)

            // フォルダ.
            let documentsDirectory = paths[0]

            // ファイル名.
            let filePath = "\(documentsDirectory)/test.mp4"

            // URL.
            let fileURL = URL(fileURLWithPath: filePath)

            // 録画開始.
            myVideoOutput.startRecording(to: fileURL, recordingDelegate: self)

        }
            // 撮影停止.
        else if ( sender == myButtonStop ){
            //
            toggleButtonStatus()
            
            myVideoOutput.stopRecording()
        }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    /*
     動画がキャプチャーされた後に呼ばれるメソッド.
     */
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("didFinishRecordingTo outputFileURL")
        
        // MARK: - フォトライブラリにビデオを保存するのであれば、以下のコードを追加した上、NSPhotoLibraryAddUsageDescription を Info.plist に追加する必要がある。
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { completed, error in
            if completed {
                print("Video is saved!")
            }
        }
    }

    /*
     動画のキャプチャーが開始された時に呼ばれるメソッド.
     */
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("didStartRecordingTo fileURL")
    }

}
