// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SearchMap",
    defaultLocalization: "fr",
    platforms: [.iOS("13.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SearchMap",
            targets: ["SearchMap"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/KAIMAN-IOS/KExtensions", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/ATACommonObjects", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/KCoordinatorKit", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/ActionButton", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/ReverseGeocodingMap", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/TextFieldEffects", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/ATAConfiguration", .branch("master")),
        .package(url: "https://github.com/malcommac/SwiftLocation", from: "5.1.0"),
        .package(url: "https://github.com/malcommac/SwiftDate", from: "6.3.1"),
        .package(url: "https://github.com/KAIMAN-IOS/ATAViews", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/ATAGroup", .branch("master")),
        .package(url: "https://github.com/KAIMAN-IOS/KStorage", .branch("master")),
        .package(name: "AlertsAndPickers", url: "https://github.com/jerometonnelier/alerts-and-pickers", .branch("spm")),
        .package(url: "https://github.com/KennethTsang/GrowingTextView", from: "0.7.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SearchMap",
            dependencies: ["KExtensions",
                           "KCoordinatorKit",
                           "ActionButton",
                           "ReverseGeocodingMap",
                           "TextFieldEffects",
                           "ATAConfiguration",
                           "SwiftLocation",
                           "ATAViews",
                           "AlertsAndPickers",
                           "ATAGroup",
                           "SwiftDate",
                           "GrowingTextView",
                           "KStorage",
                           "ATACommonObjects"])
    ]
)
