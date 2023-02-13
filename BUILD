load("//:copybara.bzl", "copybara")

copybara(
    name = "z3-copybara-import",
    additional_files = ["//copybara/workflow_files:z3.patch"],
    destination_dir = "3rdparty/copybara/z3",
    workflow_defs = "//copybara/workflow_files:z3.sky",
    workflows = ["z3"],
)
