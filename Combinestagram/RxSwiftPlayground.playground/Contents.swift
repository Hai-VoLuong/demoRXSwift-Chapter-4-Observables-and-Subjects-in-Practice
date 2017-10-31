import UIKit
import RxSwift

public func example(of description: String, action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

enum MyError: Error {
    case anError
}

func print<T: CustomStringConvertible>(label: String, event: Event<T>) {
    print(label, event.element ?? event.error ?? event)
}

let disposeBag = DisposeBag()

example(of: "skipWhile") {

   Observable.of(4, 3, 4, 5, 6)
    .skipWhile { integer in
        integer % 2 == 0
    }.subscribe(onNext: {
        print($0)
    }).addDisposableTo(disposeBag)
}
