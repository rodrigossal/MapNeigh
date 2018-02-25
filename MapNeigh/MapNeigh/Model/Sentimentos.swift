//
//  Sentimentos.swift
//  MapNeigh
//
//  Created by Rodrigo Salles Stefani on 23/02/18.
//  Copyright © 2018 Rodrigo Salles Stefani. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision
import CoreVideo

class Sentimentos{
    
    //let model = CNNEmotions()
    private var request : VNRequest!

    
    init() {
        do{
            let model = try VNCoreMLModel(for: CNNEmotions().model)
            request = VNCoreMLRequest(model: model, completionHandler: myResultsMethod)
        } catch {
            //handle error
            print("erro")
        }
    }
    
    func test(imagem: CVPixelBuffer) -> String {
       
        let handler = VNImageRequestHandler(cvPixelBuffer: imagem, orientation: .up) // fix based on your UI orientation
        let algo = try? handler.perform([request])
        print(algo)

        
//        let resultado = try? model.prediction(data: imagem)
        
        return ""
        
    }
    
    func myResultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation]
            else { fatalError("huh") }
        for classification in results {
            print(classification.identifier, // the scene label
                classification.confidence)
        }
    }

}
