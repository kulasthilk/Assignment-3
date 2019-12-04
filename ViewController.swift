//
//  ViewController.swift
//  Kate Assignment 3 App
//
//  Created by user919256 on 11/13/19.
//  Copyright © 2019 user919256. All rights reserved.
//



import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var CameraView: UIImageView!
    
    @IBOutlet weak var ShutterButton: UIButton!
    
    @IBOutlet weak var EnglishResponseLabel: UILabel!
    
    
    
    var imagePicker: ImagePicker?
    
    let cognitivesServicesAPIKey = "1d985353-a9bf-4314-9855-9ddbe36ce8da"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initialise image picker
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    // Handle button press
    @IBAction func showPicker(_ sender: UIButton) {
        imagePicker?.present()
    }
    
    
    // Retrieve tags
    private func getTags(selectedImage: UIImage?) {
        guard let selectedImage = selectedImage else { return }
        
        // URL for cognitive services tag API
        guard let url = URL(string: "https://azure.microsoft.com/en-us/services/cognitive-services/computer-vision/v2.1/analyze") else { return }
        
        // API request
       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
       request.setValue(cognitivesServicesAPIKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.httpBody = selectedImage.pngData()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
//                let responseString = String(data: data, encoding: .utf8)
                let describeImage = try? JSONDecoder().decode(DescribeImage.self, from: data)
                guard let captions = describeImage?.description?.captions else { return }
                DispatchQueue.main.async {
                    if captions.count > 0 {
                        self.EnglishResponseLabel.text = captions[0].text
                    } else {
                        self.EnglishResponseLabel.text = "No captions available"
                    }
                    
                }
            } else {
                DispatchQueue.main.async {
                    self.EnglishResponseLabel.text = error?.localizedDescription
                }
            }
        }
        
        // Resume task
        task.resume()
    }
}

extension ViewController: ImagePickerDelegate {
    
    // Delegate function
    func didSelectImage(image: UIImage?) {
        self.CameraView.image = image
        getTags(selectedImage: image)
        
    }
}
