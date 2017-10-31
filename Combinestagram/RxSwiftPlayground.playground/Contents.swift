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

struct Student {
    var score: Variable<Int>
}

let bag = DisposeBag()

example(of: "flatMapLatest") {

    let ryan = Student(score: Variable(80))
    let charlotte = Student(score: Variable(90))
    

    let student = PublishSubject<Student>()

    student.asObserver()
        .flatMapLatest {
            $0.score.asObservable()
        }
        .subscribe(onNext: {
            print("value: \($0)")
        }).addDisposableTo(bag)

    student.onNext(ryan)
    ryan.score.value = 85

    student.onNext(charlotte)
    ryan.score.value = 95
    charlotte.score.value = 100
}


