// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "aitronos",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "aitronos",
            targets: ["aitronos"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "aitronos",
            dependencies: [
                "Alamofire"
            ]
        ),
        .testTarget(
            name: "aitronos-swift-packageTests",
            dependencies: ["aitronos"],
            resources: [
                .process("Config.plist")
            ]
        ),
    ]
)
