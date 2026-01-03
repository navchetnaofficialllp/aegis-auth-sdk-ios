// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AegisAuth",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "AegisAuth",
            targets: ["AegisAuth"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "AegisAuth",
            dependencies: [
                "Alamofire",
                "SwiftyJSON"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AegisAuthTests",
            dependencies: ["AegisAuth"],
            path: "Tests"
        ),
    ]
)