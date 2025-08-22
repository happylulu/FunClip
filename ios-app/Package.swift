// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FunClipApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FunClipApp",
            targets: ["FunClipApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "FunClipApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Auth", package: "supabase-swift"),
                .product(name: "Realtime", package: "supabase-swift"),
                .product(name: "Storage", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "FunClipApp"
        ),
        .testTarget(
            name: "FunClipAppTests",
            dependencies: ["FunClipApp"],
            path: "FunClipAppTests"
        ),
    ]
)