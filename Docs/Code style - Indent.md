# Code style - Indent

### Target
Current value of indent in this project is 4. Reduce it to 2 will improve the quality of code.

### Problem and solution
Since we have introduced a declarative way to write UI, the number of wrapping of has significant increased.
In consequence of that the readability of code in many places become worse. 

Many big tech companies have developed a standard swift code style. The most of them use indent 2 to all projects.
1. [Google](https://google.github.io/swift/)
2. [Raywenderlich](https://github.com/raywenderlich/swift-style-guide)
3. [Airbnb](https://github.com/airbnb/swift)

The core apple frameworks also use indent 2, but not all of them.
1. [Core](https://github.com/apple/swift/tree/main/stdlib/public/core)
2. [AsyncChannel](https://github.com/apple/swift-async-algorithms/blob/main/Sources/AsyncAlgorithms/AsyncChannel.swift)

The following comparing will show the improvement in reading of code by using different value of indent.

Setup: 27 inch 4k monitor

#### Example 1
Code style: 
1. IDE: Appcode
2. Font: Hack
3. Size: 16
4. Line height: 1.3

The left panel show the code with indent 4, the right is with indent 2.

![Screenshot 1](./Assets/Code%20style%20-%20Indent%20-%201.png)

#### Example 2
Code style: 
1. IDE: Appcode
2. Font: Hack
3. Size: 16
4. Line height: 1.3

![Screenshot 2](./Assets/Code%20style%20-%20Indent%20-%202.png)

#### Example 3
Code style: 
1. IDE: Xcode
2. Font: SF Mono
3. Size: 12

![Screenshot 3](./Assets/Code%20style%20-%20Indent%20-%203.png)

#### Example 4
Code style:
1. IDE: Xcode
2. Font: SF Mono
3. Size: 12

![Screenshot 4](./Assets/Code%20style%20-%20Indent%20-%204.png)

#### Example 5
Code style: 
1. IDE: Xcode
2. Font: SF Mono
3. Size: 12

![Screenshot 5](./Assets/Code%20style%20-%20Indent%20-%205.png)
