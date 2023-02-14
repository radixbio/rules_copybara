load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")


def _copybara_impl(ctx):
    # pull in .sky file with the copybara workflow
    workflow_defs_path = ctx.attr.workflow_defs.files.to_list()[0]

    # get the copybara provider
    copybara = ctx.attr._copybara[DefaultInfo]

    copybara_scripts = []
    runnables = []
    additional_files = []
    for tgt in ctx.attr.additional_files:
        additional_files.extend(tgt.files.to_list())
    for workflow in ctx.attr.workflows:
        # set up the wrapper script to call copybara with the named workflow
        script = ctx.actions.declare_file("{}_wrapper.sh".format(workflow))
        copybara_scripts.append(script)

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
        ctx.actions.expand_template(
            template = ctx.file._deployment_script_template,
            output = script,
            substitutions = {
                "{workflow_defs}": str(workflow_defs_path.path),
                "{command}": command,
            },
            is_executable = True,
        )

        # build a runnable DefaultInfo per workflow target
        runnable = DefaultInfo(
            executable = script,
            runfiles = ctx.runfiles(files = copybara.files.to_list() + [workflow_defs_path] + additional_files + copybara.default_runfiles.files.to_list()),
            files = depset([]),
        )
        runnables.append(runnable)

    return runnables

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
        "deps": attr.label_list(),  # TODO run these copybara rules first
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
