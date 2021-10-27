# How to use BECollectionView
About `BECollectionView`:

- Creating `ListView` (`UITableView`, `UICollectionView`) in `UIKit` is a painful task which requires a lot of efforts. You firstly has to layout the `ListView`, create `Cell`, register it, bind data to data source and set up delegate. This type of actions is tedious and have to be repeated time to time.

- Plus, in this application we don't use UITableView at all, as its layout is not good for iPhone in landscape mode, and again, it requires a lot of efforts. So I provide a solution named `BECollectionView` (with an embeded UICollectionView) that you can use easily without digging into UIKit's tableView's implementation and get rid of setting dataSource, delegate, registerCell, binding, ... by yourself. You can use it in a replacement for `UITableView` and `UICollectionView`.

- `BECollectionView` was born with the aim is to simplify the process of creating `ListView` by hiding the detail of `UIKit` `ListView`'s implemetation as much as posible, so you can concentrate on bussiness logic. After a few configurations, you got features like Pull to refresh, loading animation, add, remove, replace cells animation,... for free. The only thing that you need to care about is the flow of data.

Bellow is an example of implementing `BECollectionView`, with example from this [task](https://p2pvalidator.atlassian.net/jira/software/projects/P2PW/boards/20?label=iOS&selectedIssue=P2PW-985)

## Create a Model T
Assume that we have to create a collection of recipients, create a struct named `Recipient` to represent a record and conform it to `Hashable`:
```swift
struct Recipient: Hashable {
    let address: String
    let shortAddress: String
    let name: String?
}
```

## Create a ListViewModel that inheritted from BEListViewModel<T>
This class is clearly a `ViewModel` that is responsible for data flow in `BECollectionView`. All these `ViewModel` has to be a subclass of `BEListViewModel<T>`. The only method that you need to inherit right now is `createRequest`:

```swift
import RxSwift
import BECollectionView

class RecipientsListViewModel: BEListViewModel<Recipient> {
    // MARK: - Dependencies
    @Injected private var nameService: NameServiceType
    @Injected private var addressFormatter: AddressFormatterType
    
    // MARK: - Properties
    var name: String = ""
    
    // MARK: - Methods
    /// The only methods that MUST be inheritted
    override func createRequest() -> Single<[Recipient]> {
        guard !name.isEmpty else {return .just([])}
        return nameService
            .getOwners(name)
            .map { [weak addressFormatter] in
                guard let addressFormatter = addressFormatter else { return [] }

                return $0.map {
                    Recipient(
                        address: $0.owner,
                        shortAddress: addressFormatter.shortAddress(of: $0.owner),
                        name: $0.name
                    )
                }
            }
    }
}
```

## Create a UICollectionViewCell that conform to BECollectionViewCell
No need to explain, this class is required to have `setUp(with:)` to handling data presentation, `hideLoading()` and `showLoading()` for handling loading state.

```swift
class RecipientCell: UICollectionViewCell, BECollectionViewCell {
    private let recipientView = RecipientView()
    
    ...
    
    // MARK: - BECollectionViewCell implementation
    func setUp(with item: AnyHashable?) {
        guard let recipient = item as? Recipient else {return}
        recipientView.setRecipient(recipient)
    }
    
    func hideLoading() {
        recipientView.hideLoader()
    }
    
    func showLoading() {
        recipientView.showLoader()
    }
}
```

