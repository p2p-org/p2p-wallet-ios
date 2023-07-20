# Slider

![Slider](Slider.png)

UI Component quite similar to UIPageControl but with custom animation

## Usage

There is a class called **Slider**. It is a subclass from UIView so you can add it as a subview to your view.
No need in specifying width and height constrains, it is calculated depending on amount of dots.
Considering usage of BEPureLayout, you can add it this way:

```swift
Slider()
    .setup { slider in
        slider.tintColor = UIColor.black
    }
    .bind(blackSlider)
```

You can set amount of dots in initializer, default is **4**:

```swift
Slider(count: 5)
```

To trigger animation forward or backward use methods:

```swift
self.blackSlider.prevDot()
self.whiteSlider.nextDot()
```
