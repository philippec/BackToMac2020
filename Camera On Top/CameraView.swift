//
//  CameraView.swift
//  Camera On Top
//
//  Created by Philippe Casgrain on 2020-10-04.
//

import SwiftUI
import AVFoundation


struct CameraView: NSViewRepresentable {

    private let session = AVCaptureSession()

    private func setupCamera(_ view: CameraPreview) {
        if let mainCamera = AVCaptureDevice.default(for: AVMediaType.video) {
            if let input = try? AVCaptureDeviceInput(device: mainCamera) {
                session.sessionPreset = .photo

                if session.canAddInput(input) {
                    session.addInput(input)
                }
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)

                previewLayer.videoGravity = .resizeAspectFill
                if let layer = view.layer {
                    layer.addSublayer(previewLayer)
                } else {
                    view.layer = previewLayer
                }

                view.previewLayer = previewLayer

                session.startRunning()
            }
        }

    }

    private func checkCameraAuthorizationStatus(_ view: CameraPreview) {

        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus == .authorized {
            setupCamera(view)
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.sync {
                if granted {
                    self.setupCamera(view)
                }
            }
        }
    }

    //MARK: - NSViewRepresentable
    typealias NSViewType = CameraPreview

    func makeNSView(context: Context) -> CameraPreview {
        let cameraView = CameraPreview(session: session)
        checkCameraAuthorizationStatus(cameraView)
        return cameraView
    }

    func updateNSView(_ view: CameraPreview, context: Context) {
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    static func dismantleNSView(_ view: CameraPreview, coordinator: ()) {
        view.session.stopRunning()
    }
}
