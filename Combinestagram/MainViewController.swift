/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift

final class MainViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private weak var imagePreview: UIImageView!
    @IBOutlet private weak var buttonClear: UIButton!
    @IBOutlet private weak var buttonSave: UIButton!
    @IBOutlet private weak var itemAdd: UIBarButtonItem!

    // MARK: - propeties
    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([]) // 1
    private var imageCache = [Int]()

    // MARK:life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        let imagesObservable = images.asObservable().share()

        imagesObservable.asObservable()
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] photos in // 2
            guard let preview = self?.imagePreview else { return }
            preview.image = UIImage.collage(images: photos, size: preview.frame.size)
        }).addDisposableTo(bag)

        imagesObservable.asObservable()
            .subscribe(onNext: { [weak self] photos in
            self?.updateUI(photos: photos)
        }).addDisposableTo(bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("resources: \(RxSwift.Resources.total)")
    }

    // MARK: - IBAction
    @IBAction private func actionClear() {
        images.value = [] // 3
        imageCache = []
    }

    @IBAction private func actionSave() {
        guard let image = imagePreview.image else { return }
        PhotoWriter.save(image).subscribe(
            onError: { [weak self] error in
                self?.showMessage("Error", description: error.localizedDescription)},
            onCompleted: { [weak self] in
                self?.showMessage("Save")
                self?.actionClear()
        }).addDisposableTo(bag)
    }

    @IBAction private func actionAdd() {
        let photosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotosViewController") as? PhotosViewController

        let newPhotos = photosViewController?.selectedPhotos.share()

        newPhotos?
            .takeWhile({ [weak self] image in
                return (self?.images.value.count ?? 0) < 6
            })
            .filter({ newImage in
                return newImage.size.width > newImage.size.height

            })
            .filter({ [weak self] newImage in
                let len = UIImagePNGRepresentation(newImage)?.count ?? 0
                guard self?.imageCache.contains(len) == false else {
                    return false
                }
                self?.imageCache.append(len)
                return true
            })
            .subscribe(onNext: { [weak self] newImage in // 4
                guard let images = self?.images else { return }
                images.value.append(newImage) // 3
                }, onDisposed: {
                    print("completed photo selection")
            })
            .addDisposableTo((photosViewController?.bag)!)

        newPhotos?
            .ignoreElements()
            .subscribe(onCompleted: {
                self.updateNavigationIcon()
            }).addDisposableTo((photosViewController?.bag)!)
        
        navigationController?.pushViewController(photosViewController!, animated: true)
    }

    // MARK: - private function
    private func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }

    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }

    // MARK: - public function
    func showMessage(_ title: String, description: String? = nil) {
        alert(title: title, text: description)
        .subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
        .addDisposableTo(bag)
    }
}
