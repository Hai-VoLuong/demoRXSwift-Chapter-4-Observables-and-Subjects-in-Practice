//
//  UIAlertViewController.swift
//  Combinestagram
//
//  Created by Hai Vo L. on 10/27/17.
//  Copyright © 2017 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    func alert(title: String, text: String?) -> Observable<Void> {
        return Observable.create({ observable in
            let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)

            alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: {_ in
                observable.onCompleted()
            }))

            self.present(alertVC, animated: true, completion: nil)
                return Disposables.create {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
}
