// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "sdate",
    defaultLocalization: "us",
    platforms: [ .macOS(.v14) ],
    targets: [
       .executableTarget(
            name: "sdate"
       ),
    ]
)
