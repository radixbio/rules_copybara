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
            command = command
        )

    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = "set -euo pipefail" + '\n' + "set -x" + '\n' + script
    )

    copybara_info = CopybaraInfo(
        script = script,
        skys = workflow_defs + [workflow_defs_path],
        additional = additional_files
    )

    return [DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = ctx.runfiles(
            files = copybara.files.to_list() +
            copybara_info.skys +
            copybara_info.additional +
            copybara.default_runfiles.files.to_list()
        )
    ),
            copybara_info
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
            default = ""
        ),
        "deps": attr.label_list(
            mandatory = False,
            providers = [CopybaraInfo]
        ),
        "run_deps": attr.bool(
            default = True
        ),
        "_deployment_script_template": attr.label(
            allow_single_file = True,
            default = "//copybara:wrapper.sh.tpl",
        ),
        "_copybara": attr.label(
            allow_files = True,
            default = "@com_github_google_copybara//java/com/google/copybara",
        ),
    },
    executable = True,
)
