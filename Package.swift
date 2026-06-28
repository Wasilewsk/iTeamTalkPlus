// TeamTalkKit.swiftpackage.swift
// Package.swift
import PackageDescription

let package = Package(
    name: "TeamTalkPlus-iOS",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "TeamTalkKit",
            targets: ["TeamTalkKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "TeamTalkKit",
            path: "../TeamTalk5/Client/iTeamTalk/TeamTalkKit.zip"
        ),
        .target(
            name: "iTeamTalkPlus",
            dependencies: [
                "TeamTalkKit"
            ],
            path: "iTeamTalkPlus"
        ),
        .testTarget(
            name: "iTeamTalkPlusTests",
            dependencies: [
                "iTeamTalkPlus"
            ],
            path: "iTeamTalkPlusTests"
        )
    ]
)
