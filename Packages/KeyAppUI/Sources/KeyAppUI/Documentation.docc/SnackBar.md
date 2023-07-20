# ``KeyAppUI/SnackBar``

A component for showing notifications.

![Conver](Snackbar.png)

## Usage

Creating component:

```swift
SnackBar(
    icon: Asset.MaterialIcon.arrowBack.image.withTintColor(Asset.Colors.cloud.color, renderingMode: .alwaysOriginal),
    text: "Text",
    trailing: TextButton
        .style(
            title: "Button", 
            style: .primary, 
            size: .medium
        )
)
```

To show component on top of view controller, use ``show(in:autoHide:hideCompletion:)`` method of instance.
```swift
SnackBar(
    icon: .add, 
    text: "Text", 
    buttonTitle: "Close",
    buttonAction: { SnackBar.hide() }
).show(
    in: view,
    autoHide: true,
    hideCompletion: { print("I am closed") }
)
```
