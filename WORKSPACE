load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

local_repository(
    name = "com_github_rules_copybara",
    path = "."
)


load("@com_github_rules_copybara//:copybara.bzl", "copybara_config")

copybara_config(
    copybara_version = "6cd6432036fd47ba13737aa2ab3703ebf7a8a8cb",
    copybara_sha256 = "6601b287c39a08eb5c6e5ed15c920ed2bfeb9140220190ef29c117f2abe5b55d"
)

load("@com_github_rules_copybara//:copybara_dependencies.bzl", "copybara_dependency")

copybara_dependency()

load("@com_github_google_copybara//:repositories.bzl", "copybara_repositories")

copybara_repositories()

load("@com_github_google_copybara//:repositories.maven.bzl", "copybara_maven_repositories")

copybara_maven_repositories()

load("@com_github_google_copybara//:repositories.go.bzl", "copybara_go_repositories")

copybara_go_repositories()
