//
//  ImageClassifierService.swift
//  ImagesClassifier
//
//  Created by Artem Makaroff on 12.02.2020.
//  Copyright © 2020 Artem Makaroff. All rights reserved.
//

import UIKit
import Vision

enum ImageClassifierServiceState {
  case startRequest, requestFailed, receiveResult(resultModel: ClassifierResultModel)
}

class ImageClassifierService {
  var onDidUpdateState: ((ImageClassifierServiceState) -> Void)?
  
  func classifyImage(_ image: UIImage) {
    onDidUpdateState?(.startRequest)
    
    guard let model = makeImageClassifierModel(), let ciImage = CIImage(image: image) else {
      onDidUpdateState?(.requestFailed)
      return
    }
    makeClassifierRequest(for: model, ciImage: ciImage)
  }
  
  private func makeImageClassifierModel() -> VNCoreMLModel? {
    return try? VNCoreMLModel(for: MyImageClassifier().model)
  }
  
  private func makeClassifierRequest(for model: VNCoreMLModel, ciImage: CIImage) {
    let request = VNCoreMLRequest(model: model) { [weak self] request, error in
      self?.handleClassifierResults(request.results)
    }
    
    let handler = VNImageRequestHandler(ciImage: ciImage)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        self.onDidUpdateState?(.requestFailed)
      }
    }
  }
  
  private func handleClassifierResults(_ results: [Any]?) {
    guard let results = results as? [VNClassificationObservation],
      let firstResult = results.first else {
      onDidUpdateState?(.requestFailed)
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      let confidence = (firstResult.confidence * 100).rounded()
      let resultModel = ClassifierResultModel(identifier: firstResult.identifier, confidence: Int(confidence))
      self?.onDidUpdateState?(.receiveResult(resultModel: resultModel))
    }
  }
}
