//
//  PhotoEditorViewController.swift
//  P-effect
//
//  Created by Illya on 1/25/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import UIKit

protocol PhotoEditorDelegate: class {
    
    func photoEditor(photoEditor: PhotoEditorViewController, didChooseEffect: UIImage)
    func imageForPhotoEditor(photoEditor: PhotoEditorViewController, withEffects: Bool) -> UIImage
    
}

class PhotoEditorViewController: UIViewController {
    
    @IBOutlet private weak var effectsPickerContainer: UIView!
    @IBOutlet private weak var imageContainer: UIView!
    @IBOutlet private weak var leftToolbarButton: UIBarButtonItem!
    @IBOutlet private weak var rightToolbarButton: UIBarButtonItem!
    
    var model: PhotoEditorModel!
    var effectsPickerController: EffectsPickerViewController? {
        didSet {
            effectsPickerController?.delegate = self
        }
    }
    var imageController: ImageViewController?
    weak var delegate: PhotoEditorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "back")
        navigationItem.leftBarButtonItem = newBackButton;
    }
    
    @IBAction private func postEditedImage() {
        guard ReachabilityHelper.isInternetAccessAvailable() else{
            suggestSaveToPhotoLibrary()
            
            return
        }
        postToTheNet()
    }
    
    @IBAction private func saveToImageLibrary() {
        guard let image = delegate?.imageForPhotoEditor(self, withEffects: true) else {
            ExceptionHandler.handle(Exception.CantApplyEffects)
            
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        AlertService.simpleAlert("Image saved to library")
    }
    
    private func postToTheNet() {
        do {
            guard let image = delegate?.imageForPhotoEditor(self, withEffects: true) else {
                throw Exception.CantApplyEffects
            }
            let pictureData = UIImageJPEGRepresentation(image, 0.5)!
            guard let file = PFFile(name: "image", data: pictureData) else {
                throw Exception.CantCreateParseFile
            }
            SaverService.saveAndUploadPost(file)
            navigationController!.popViewControllerAnimated(true)
        } catch let exception {
            ExceptionHandler.handle(exception as! Exception)
        }
    }
    
    private func suggestSaveToPhotoLibrary() {
        let alertController = UIAlertController(
            title: Exception.NoConnection.rawValue,
            message: "Would you like to save results to photo library or post after internet access appears?",
            preferredStyle: .ActionSheet
        )
        
        let saveAction = UIAlertAction(title: "Save now", style: .Default) { _ in
            self.saveToImageLibrary()
        }
        alertController.addAction(saveAction)
        
        let postAction = UIAlertAction(title: "Post with delay", style: .Default) { _ in
            self.postToTheNet()
        }
        alertController.addAction(postAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func back() {
        let alertController = UIAlertController(title: "Results didn't saved", message: "Would you like to save results to the photo library?", preferredStyle: .ActionSheet)
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { _ in
            self.saveToImageLibrary()
            self.navigationController!.popViewControllerAnimated(true)
        }
        alertController.addAction(saveAction)
        
        let dontSaveAction = UIAlertAction(title: "Don't save", style: .Default) { _ in
            self.navigationController!.popViewControllerAnimated(true)
        }
        alertController.addAction(dontSaveAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func didChooseEffectFromPicket(effect: UIImage) {
        delegate?.photoEditor(self, didChooseEffect: effect)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var size = imageContainer.frame.size
        size.width = UIScreen.mainScreen().bounds.width
        size.height = size.width
        imageContainer.bounds.size = size
        size.height = effectsPickerContainer.frame.height
        effectsPickerContainer.bounds.size = size
        
        leftToolbarButton.width = UIScreen.mainScreen().bounds.width * 0.5
        rightToolbarButton.width = UIScreen.mainScreen().bounds.width * 0.5
        view.superview?.layoutIfNeeded()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.PhotoEditor.ImageViewControllerSegue:
            imageController = segue.destinationViewController as? ImageViewController
            imageController?.model = ImageViewModel.init(image: model.originalImage())
            delegate = imageController
        case Constants.PhotoEditor.EffectsPickerSegue:
            effectsPickerController = segue.destinationViewController as? EffectsPickerViewController
            effectsPickerController?.model = EffectsPickerModel()
        default:
            break
        }
        
        super.prepareForSegue(segue, sender: sender)
    }
}
