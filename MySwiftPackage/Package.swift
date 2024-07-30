// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SplitTheBill",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/pvieito/PythonKit.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "PythonIntegration",
            dependencies: ["PythonKit"]
        )
    ]
)

