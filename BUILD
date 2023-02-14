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
