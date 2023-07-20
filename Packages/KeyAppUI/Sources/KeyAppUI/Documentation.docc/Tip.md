# Tip

![Tip](Tip.png)

UI Component to indicate something for user. For instance, onboarding or new feature release.

## Usage

There is a class called **TipManager**. Use it to create a tip with your content and stylization. Implement **TipManagerDelegate** to react to buttons.

### TipManager

Initialize it.

```swift
private lazy var tipManager: TipManager = {
    let tipManager = TipManager()
    tipManager.delegate = self
    return tipManager
}()
```

Create a tip.
You are responsible to add tip as a subview and positionate it properly. Example:

You need to pass three parameters: 

- TipComponent. This struct represents a content inside a tip. 

- TipTheme. It is an enum for tip style. Can be night, snow and lime.

- TipPointerPosition. A pointer can be flexible put with 12 different options. There is also an option to not use it. Just pass `.none`.

```swift
let tip = tipManager.createTip(content: createTipContent(number: 1, count: 5), theme: .night, pointerPosition: .topRight)
view.addSubview(nextTip)
nextTip.autoPinEdge(.top, to: .bottom, of: firstButton, withOffset: 4)
nextTip.autoPinEdge(.leading, to: .leading, of: view, withOffset: 4)
```

*Warning: creation methods returns UIView*

### TipManagerDelegate

```swift
public protocol TipManagerDelegate: AnyObject {
    func next(after number: Int)
}
```

Respond to button action. A tip has two buttons: Next and Skip (buttons' titles are customizable). Skip button is quite clear - it hides current tip and does not call next action. As it methioned above that you are responsible to add tip as a subview, `next` method is perfect for constracting them in correct order next to correct subviews. If user presses on `next` button with the last current number, tip hides automatically.

```swift
func next(after number: Int) {
    let nextTip: UIView
    switch number {
    case 1:
        nextTip = tipManager.createTip(content: createTipContent(number: 2, count: 5), theme: .snow, pointerPosition: .rightCenter)
        view.addSubview(nextTip)
        nextTip.autoPinEdge(.trailing, to: .leading, of: secondLabel, withOffset: -4)
        nextTip.autoAlignAxis(.horizontal, toSameAxisOf: secondLabel)
    case 2:
        nextTip = tipManager.createTip(content: createTipContent(number: 3, count: 5), theme: .lime, pointerPosition: .bottomLeft)
        view.addSubview(nextTip)
        nextTip.autoPinEdge(.bottom, to: .top, of: thirdLabel, withOffset: -4)
        nextTip.autoPinEdge(.leading, to: .leading, of: thirdLabel, withOffset: -16)
    default:
        fatalError()
    }
    nextTip.autoSetDimension(.width, toSize: 250, relation: .lessThanOrEqual)
}
```

TipExampleViewController demonstrates usage.
