load("@com_github_rules_copybara//:copybara.bzl", "copybara", "copybara_move_commits", "copybara_move_github_pr")

exports_files(["z3.sky",
               "z3.patch",
               "scalaz3.sky",
               "scalaz3.patch",
               "repo_push.sky",
               "github.bara.sky"])


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
# sot -> dest repo
copybara_move_commits(
    name = "sot-to-ext",
    sot_repo = "git@github.com:DhashS/copybara_sot.git",
    sot_branch = "main",
    dest_repo = "git@github.com:DhashS/replicant.git",
    dest_branch = "main",
    committer = "copybara <copybara@example.com>",
    push_files = 'glob(["**"], exclude = ["README.md", "dont_replicate/*"])',
    destination_files = 'glob(["**"], exclude = ["README.md"])'
)
copybara_move_github_pr(
    name = "ext-pr-to-sot",
    sot_repo = "git@github.com:DhashS/copybara_sot.git",
    sot_branch = "main",
    dest_repo = "git@github.com:DhashS/replicant.git",
    dest_branch = "main",
    committer = "copybara <copybara@example.com>",
    push_files = 'glob(["**"], exclude = ["README.md", "dont_replicate/*"])',
    destination_files = 'glob(["**"], exclude = ["README.md"])'
)
