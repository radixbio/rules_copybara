load("//:copybara.bzl", "copybara")

# z3
copybara(
    name = "z3-copybara-import",
    additional_files = ["//examples:z3.patch"],
    destination_dir = "3rdparty/copybara/z3",
    workflow_defs = "//examples:z3.sky",
    workflows = ["z3"],
)
# scalaz3
copybara(
    name = "scalaz3-copybara-import",
    additional_files = ["//examples:scalaz3.patch"],
    destination_dir = "3rdparty/copybara/scalaz3",
    workflow_defs = "//examples:scalaz3.sky",
    workflows = ["scalaz3"],
    deps = [":z3-copybara-import"]
)
# push from one repo to the other
copybara(
    name = "replicant_push",
    workflow_defs = "//examples:repo_push.sky",
    workflows = ["push"],
    cli_args = "--force 1"
)
# push pull requests from one repo to the other
copybara(
    name = "replicant_pull",
    workflow_defs = "//examples:repo_push.sky",
    workflows = ["pull"],
    additional_files = ["//examples:github.bara.sky"],
    cli_args = "--force 1"
)
