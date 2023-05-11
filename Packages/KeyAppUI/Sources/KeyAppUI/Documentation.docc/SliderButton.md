# ``KeyAppUI/SliderButton``

![Conver](SliderButton.png)

## Usage

Use style function to create a slider button with predefined appearance. Get change of state in 'onChanged' function

```swift
SliderButton(
    image: Asset.MaterialIcon.appleLogo.image,
    title: "Change Apple ID", style: .black
).onChanged { [weak self] value in
    guard let self = self else { return }
    self.sliderButton.view?.title = "\(value)"
}
```
