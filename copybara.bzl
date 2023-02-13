load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def copybara_dependencies():
    maybe(
        http_archive,
        name = "com_github_google_copybara",
        sha256 = "6601b287c39a08eb5c6e5ed15c920ed2bfeb9140220190ef29c117f2abe5b55d",
        strip_prefix = "copybara-6cd6432036fd47ba13737aa2ab3703ebf7a8a8cb",
        url = "https://github.com/google/copybara/archive/6cd6432036fd47ba13737aa2ab3703ebf7a8a8cb.zip",
    )
    skylib_version = "398f3122891b9b711f5aab1adc7597d9fce09085"
    skylib_sha256 = "2d9a5be0c710c62e04d0b684f783c531d70e13f90378a4a8d9d1925e3bc487af"
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = skylib_sha256,
        strip_prefix = "bazel-skylib-" + skylib_version,
        url = "https://github.com/bazelbuild/bazel-skylib/archive/" + skylib_version + ".zip",
    )
    bazel_version = "668b0da527a43299f6f6ac49bb5cc37be2265c45"
    bazel_sha256 = "0c2919a9f0b4bd24c53c2d27e3a721ff00fec9bd1f5247eb700e8977934da253"
    maybe(
        http_archive,
        name = "io_bazel",
        sha256 = bazel_sha256,
        strip_prefix = "bazel-" + bazel_version,
        url = "https://github.com/bazelbuild/bazel/archive/" + bazel_version + ".zip",
    )
#    maybe(
#        http_archive,
#        name = "JCommander",
#        sha256 = "e7ed3cf09f43d0d0a083f1b3243c6d1b45139a84a61c6356504f9b7aa14554fc",
#        urls = [
#            "https://github.com/cbeust/jcommander/archive/05254453c0a824f719bd72dac66fa686525752a5.zip",
#        ],
#        build_file = Label("//external/third_party:jcommander.BUILD"),
#    )
#    load("@com_github_google_copybara//:repositories.bzl", "copybara_repositories")
#
#    copybara_repositories()
#
#    load("@com_github_google_copybara//:repositories.maven.bzl", "copybara_maven_repositories")
#
#    copybara_maven_repositories()
#
#    load("@com_github_google_copybara//:repositories.go.bzl", "copybara_go_repositories")
#
#    copybara_go_repositories()







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
