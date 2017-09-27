lane :build do |options|
xcodebuild(
    configuration: "Debug",
    clean: options[:clean],
    build: true,
    destination: "generic/platform=iOS",
    build_settings: {
        "CODE_SIGNING_REQUIRED" => "NO",
        "CODE_SIGN_IDENTITY" => ""
    }
)
end
