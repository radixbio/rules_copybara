load(":copybara.bzl", "copybara_dependencies", "copybara")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

#copybara_dependencies()
#http_archive(
#    name = "com_github_google_copybara",
#    sha256 = "0b7263399f1f66c478dec09a157ef6a57bdcac4aa5acbe00a429f8d4f26455b6",
#    strip_prefix = "copybara-master",
#    url = "https://github.com/google/copybara/archive/refs/heads/master.zip",
#)

http_archive(
    name = "com_github_google_copybara",
    sha256 = "6601b287c39a08eb5c6e5ed15c920ed2bfeb9140220190ef29c117f2abe5b55d",
    strip_prefix = "copybara-6cd6432036fd47ba13737aa2ab3703ebf7a8a8cb",
    url = "https://github.com/google/copybara/archive/6cd6432036fd47ba13737aa2ab3703ebf7a8a8cb.zip",
)


load("@com_github_google_copybara//:repositories.bzl", "copybara_repositories")

copybara_repositories()

load("@com_github_google_copybara//:repositories.maven.bzl", "copybara_maven_repositories")

copybara_maven_repositories()

load("@com_github_google_copybara//:repositories.go.bzl", "copybara_go_repositories")

copybara_go_repositories()
