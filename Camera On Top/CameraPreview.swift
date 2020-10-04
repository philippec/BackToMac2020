//
//  CameraPreview.swift
//  Camera On Top
//
//  Created by Philippe Casgrain on 2020-10-04.
//

import AppKit
import AVFoundation


class CameraPreview: NSView {

    var previewLayer: AVCaptureVideoPreviewLayer?
    var session = AVCaptureSession()

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        self.session = session
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
