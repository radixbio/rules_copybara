load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

CopybaraInfo = provider(fields = ["skys", "additional", "script"])

def _copybara_impl(ctx):
    # pull in .sky file with the copybara workflow
    workflow_defs_path = ctx.attr.workflow_defs.files.to_list()[0]

    # get the copybara provider
    copybara = ctx.attr._copybara[DefaultInfo]

    script = str("")
    workflow_defs = []
    additional_files = []
    if len(ctx.attr.deps) > 0:
        for dep in ctx.attr.deps:
            if ctx.attr.run_deps:
                script = script + dep[CopybaraInfo].script
            additional_files.extend(dep[CopybaraInfo].additional)
            workflow_defs.extend(dep[CopybaraInfo].skys)

    for tgt in ctx.attr.additional_files:
        additional_files.extend(tgt.files.to_list())
    for workflow in ctx.attr.workflows:
        command = []

        # the copybara jar
        command.append(str(copybara.files_to_run.executable.short_path))
        command.append("migrate")

        # the wrapper will copy the workflow file to this constant string (idk, it's not happy w/ a symlink or a nested file)
        command.append("copy.bara.sky")

        # drop the workflow name into the command
        command.append(workflow)

        # if the copybara callsite specifies a folder to do things in
        if ctx.attr.destination_dir != "":
            command.append("--folder-dir")
            command.append("${BUILD_WORKSPACE_DIRECTORY}/" + str(ctx.attr.destination_dir))

        # append additional command line args
        if ctx.attr.cli_args != "":
            command.append(str(ctx.attr.cli_args))

        # form the actual cli command
        command = " ".join(command)

        # make the templates
        script = script + """

        cp {workflow_defs} copy.bara.sky
        {command}

        """.format(
            workflow_defs = str(workflow_defs_path.path),
            command = command,
        )

    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = "set -euo pipefail" + "\n" + "set -x" + "\n" + script,
    )

    copybara_info = CopybaraInfo(
        script = script,
        skys = workflow_defs + [workflow_defs_path],
        additional = additional_files,
    )

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            runfiles = ctx.runfiles(
                files = copybara.files.to_list() +
                        copybara_info.skys +
                        copybara_info.additional +
                        copybara.default_runfiles.files.to_list(),
            ),
        ),
        copybara_info,
    ]

copybara = rule(
    implementation = _copybara_impl,
    attrs = {
        "workflow_defs": attr.label(
            allow_single_file = True,
        ),
        "workflows": attr.string_list(),
        "destination_dir": attr.string(
            mandatory = False,
            default = "",
        ),
        "additional_files": attr.label_list(
            allow_files = True,
        ),
        "cli_args": attr.string(
            mandatory = False,
            default = "",
        ),
        "deps": attr.label_list(
            mandatory = False,
            providers = [CopybaraInfo],
        ),
        "run_deps": attr.bool(
            default = True,
        ),
        "_copybara": attr.label(
            allow_files = True,
            default = "@com_github_google_copybara//java/com/google/copybara",
        ),
    },
    executable = True,
)

def _copybara_move_commits_impl(ctx):
    push = ctx.actions.declare_file("push.bara.sky")
    ctx.actions.expand_template(
        template = ctx.file._tmpl,
        output = push,
        substitutions = {
            "{sotRepo}": ctx.attr.sot_repo,
            "{sotBranch}": ctx.attr.sot_branch,
            "{destinationRepo}": ctx.attr.dest_repo,
            "{destinationBranch}": ctx.attr.dest_branch,
            "{committer}": ctx.attr.committer,
            "{push_files}": ctx.attr.push_files,
            "{destination_files}": ctx.attr.destination_files,
            "{mode}": ctx.attr.mode,
            "{push_transformations}": str(ctx.attr.push_transformations).replace('\\"', "🛐").replace('"', '').replace("🛐", '"'),
            "{pr_transformations}": str(ctx.attr.pr_transformations).replace('\\"', "🛐").replace('"', '').replace("🛐", '"')
        }
    )

    copybara = ctx.attr._copybara[DefaultInfo]

    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = """
        #!/bin/sh
        rm -f copy.bara.sky
        cp {tmpl} copy.bara.sky
        {command} migrate copy.bara.sky push
        """.format(tmpl = str(push.short_path),
                   command = str(copybara.files_to_run.executable.short_path))

    )

    return DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = ctx.runfiles(files = [push] + copybara.files.to_list() + copybara.default_runfiles.files.to_list())
    )




default_push_transformations = [
    'metadata.restore_author("ORIGINAL_AUTHOR", search_all_changes = True)',
    'metadata.expose_label("COPYBARA_INTEGRATE_REVIEW")'
]
copybara_move_commits = rule(
    implementation = _copybara_move_commits_impl,
    attrs = {
        "sot_repo": attr.string(
            mandatory = True
        ),
        "sot_branch": attr.string(
            mandatory = True
        ),
        "dest_repo": attr.string(
            mandatory = True
        ),
        "dest_branch": attr.string(
            mandatory = True
        ),
        "committer": attr.string(),
        "push_files": attr.string(), # this is a string since the workflow can run on foreign repos
        "destination_files": attr.string(),
        "mode": attr.string(
            default = "ITERATIVE"
        ),
        "push_transformations": attr.string_list(
            default = default_push_transformations
        ),
        "pr_transformations": attr.string_list(
            default = []
        ),
        "cli_args": attr.string(
            mandatory = False
        ),
        "_copybara": attr.label(
            allow_files = True,
            default = "@com_github_google_copybara//java/com/google/copybara",
        ),
        "_tmpl": attr.label(
            allow_single_file = True,
            default = "//:push.bara.sky.tmpl"
        )
    },
    executable = True
)

def _copybara_move_github_pr_impl(ctx):
    push = ctx.actions.declare_file("pr.bara.sky")
    ctx.actions.expand_template(
        template = ctx.file._tmpl,
        output = push,
        substitutions = {
            "{sotRepo}": ctx.attr.sot_repo,
            "{sotBranch}": ctx.attr.sot_branch,
            "{destinationRepo}": ctx.attr.dest_repo,
            "{destinationBranch}": ctx.attr.dest_branch,
            "{committer}": ctx.attr.committer,
            "{push_files}": ctx.attr.push_files,
            "{destination_files}": ctx.attr.destination_files,
            "{mode}": ctx.attr.mode,
            "{pr_transformations}": str(ctx.attr.pr_transformations).replace('\\"', "🛐").replace('"', '').replace("🛐", '"').replace("{destinationRepo}", ctx.attr.dest_repo)
        }
    )

    copybara = ctx.attr._copybara[DefaultInfo]

    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = """
        #!/bin/sh
        rm -f copy.bara.sky
        cp {tmpl} copy.bara.sky
        {command} migrate copy.bara.sky pr $@
        """.format(tmpl = str(push.short_path),
                   command = str(copybara.files_to_run.executable.short_path))

    )

    return DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = ctx.runfiles(files = [push] + copybara.files.to_list() + copybara.default_runfiles.files.to_list())
    )

default_move_pr_transformations = [
    'metadata.save_author("ORIGINAL_AUTHOR")',
    'metadata.expose_label("GITHUB_PR_NUMBER", new_name = "Closes", separator = "{destinationRepo}".replace("git@github.com", " ").replace(".git", "#"))'
]
# move from dest to sot
copybara_move_github_pr = rule(
    implementation = _copybara_move_github_pr_impl,
    attrs = {
        "sot_repo": attr.string(
            mandatory = True
        ),
        "sot_branch": attr.string(
            mandatory = True
        ),
        "dest_repo": attr.string(
            mandatory = True
        ),
        "dest_branch": attr.string(
            mandatory = True
        ),
        "committer": attr.string(),
        "push_files": attr.string(), # this is a string since the workflow can run on foreign repos
        "destination_files": attr.string(),
        "mode": attr.string(
            default = "CHANGE_REQUEST"
        ),
        "pr_transformations": attr.string_list(
            default = default_move_pr_transformations
        ),
        "cli_args": attr.string(
            mandatory = False
        ),
        "_copybara": attr.label(
            allow_files = True,
            default = "@com_github_google_copybara//java/com/google/copybara",
        ),
        "_tmpl": attr.label(
            allow_single_file = True,
            default = ":pr.bara.sky.tmpl"
        )
    },
    executable = True
)


def _store_copybara_config(repository_ctx):
    version = repository_ctx.attr.copybara_version
    version_sha = repository_ctx.attr.copybara_sha256

    config_file_content = "\n".join([
        "COPYBARA_VERSION='" + version + "'",
        "COPYBARA_SHA256='" + version_sha + "'",
    ])

    repository_ctx.file("config.bzl", config_file_content)
    repository_ctx.file("BUILD")

_config_repository = repository_rule(
    implementation = _store_copybara_config,
    attrs = {
        "copybara_version": attr.string(
            mandatory = True,
        ),
        "copybara_sha256": attr.string(
            mandatory = True,
        ),
    },
)

def copybara_config(
        copybara_version,
        copybara_sha256):
    _config_repository(
        name = "com_github_rules_copybara_config",
        copybara_version = copybara_version,
        copybara_sha256 = copybara_sha256
    )
