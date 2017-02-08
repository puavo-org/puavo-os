#!/usr/bin/env python3

import sys
from datetime import datetime

from PyQt5.QtCore import *
#from PyQt5.QtGui import *
from PyQt5.QtGui import QImage
from PyQt5.QtWidgets import (QApplication, QDialog, QLabel, QComboBox, QPushButton, QGridLayout, QDesktopWidget)
from PyQt5.QtMultimedia import (QCamera, QCameraImageCapture, QImageEncoderSettings, QMultimedia)
from PyQt5.QtMultimediaWidgets import QCameraViewfinder

class WebcamImageCapture(QDialog):
    # ------------------------------------------------------
    def __init__(self, parent = None):
        super(WebcamImageCapture, self).__init__(parent)

        self.camera = None
        self.capture = None
        self.capturedImage = None

        if len(QCamera.availableDevices()) == 0:
            QMessageBox.critical(self, "No Cameras", "This system has no webcams available, or they cannot be accessed.")
            #sys.exit()
            self.reject()
            return

        sourceLabel = QLabel("Which camera to use:")
        sourceLabel.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
        sourceBox = QComboBox()
        #sourceBox.setToolTip("Choose the camera to use")

        # put available cameras in the combobox
        for deviceName in QCamera.availableDevices():
            description = QCamera.deviceDescription(deviceName)
            sourceBox.addItem(description)

        # select the first available camera
        cameraName = QCamera.availableDevices()[0]
        self.camera = QCamera(cameraName)
        self.camera.CaptureMode = QCamera.CaptureStillImage
        #self.camera.stateChanged.connect(self.cameraStateChanged)
        self.camera.error.connect(self.cameraError)

        # the capture object actually captures the image
        self.capture = QCameraImageCapture(self.camera)
        #self.capture.setCaptureDestination(QCameraImageCapture.CaptureToFile)
        self.capture.setCaptureDestination(QCameraImageCapture.CaptureToBuffer)
        self.capture.readyForCaptureChanged.connect(self.readyForCapture)
        self.capture.imageCaptured.connect(self.storeCapturedImage)

        # image encoder
        self.encoder = QImageEncoderSettings()
        self.encoder.setCodec("image/jpeg")
        self.encoder.setQuality(QMultimedia.VeryHighQuality)
        #self.encoder.setResolution(640, 480)
        self.capture.setEncodingSettings(self.encoder)

        # create a viewfinder for the camera
        self.viewfinder = QCameraViewfinder()
        self.camera.setViewfinder(self.viewfinder)

        # buttons
        self.cancelButton = QPushButton("Close")
        self.cancelButton.setToolTip("Closes the window without taking an image")
        self.cancelButton.clicked.connect(self.reject)
        self.captureButton = QPushButton("Capture image")
        self.captureButton.setToolTip("Captures an image and closes the window")
        self.captureButton.clicked.connect(self.takeImage)
        self.captureButton.setEnabled(False)

        # layout
        grid = QGridLayout()
        grid.setSpacing(10)
        grid.addWidget(sourceLabel, 0, 0)
        grid.addWidget(sourceBox, 0, 1)
        grid.addWidget(self.viewfinder, 1, 0, 1, 2)
        grid.addWidget(self.cancelButton, 2, 0)
        grid.addWidget(self.captureButton, 2, 1)

        # setup the window
        self.setLayout(grid)
        self.setMinimumSize(640, 480)
        self.setGeometry(0, 0, 640, 480)
        self.setWindowTitle("Import image from webcam")

        # center the window
        fg = self.frameGeometry()
        cp = QDesktopWidget().availableGeometry().center()
        fg.moveCenter(cp)
        self.move(fg.topLeft())

        self.camera.start()

    # ------------------------------------------------------
    def stopCamera(self):
        if self.camera is not None:
            self.camera.stop()

    # ------------------------------------------------------
    def closeEvent(self, event):
        self.stopCamera()

    # ------------------------------------------------------
    def cameraError(self, error):
        QMessageBox.critical(self, "Error", "The camera returned the following error message:\n\n\t" +
            self.camera.errorString())

    # ------------------------------------------------------
    def readyForCapture(self, ready):
        self.captureButton.setEnabled(True)
        self.captureButton.setDefault(True)

    # ------------------------------------------------------
    def takeImage(self, state):
        self.captureButton.setEnabled(False)
        self.cancelButton.setEnabled(False)
        self.capture.capture()

    # ------------------------------------------------------
    def storeCapturedImage(self, requestId, img):
        #kuva = QImage(img)
        #name = datetime.today().strftime("/home/jarmo/%Y%m%d-%H%M%S.png")
        #kuva.save(name)
        #print("Tallennettu kuva \"" + name + "\"")
        self.capturedImage = QImage(img)
        self.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = WebcamImageCapture()
    result = win.exec_()

    if result == QDialog.Accepted:
        print("An image was captured")
        name = datetime.today().strftime("/home/jarmo/%Y%m%d-%H%M%S.png")
        win.capturedImage.save(name)
        print("Saved \"" + name + "\"")
    else:
        print("No image captured")

    # HACK HACK HACK HACK, closeEvent() is not called when the window closes
    # normally, so the camera *can* remain active (ie. busy) and unusable
    if win.camera is not None:
        win.camera.stop()

    #sys.exit(app.exec_())
