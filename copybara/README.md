# Copybara
**Last Updated:** *Octt 26, 2022 @ PR #446*


## Authors & Maintainers
- **Shaan H** (Maintainer)

## Summary
Copybara lets you transport and transform 3rdparty dependencies natively using bazel.

## Usage
1. Define a Copybara workflow you would like to execute in `./workflow_files`
2. Define a git-patchfile if needed in `./workflow_files`
3. Expose both the workflow file and the patchfile in `./BUILD`
4. Create a build target in `monorepo/BUILD`
5. Execute your build target with `bazel run //:<your_target_name>`

## Quirks
1. Targets tagged with `copybara-prebuild` in `monorepo/BUILD` will automatically be run and persist when the `just _bazel_deps` is executed
2. The `3rdparty/copybara` folder is wiped everytime `just _bazel_deps` is run and only tagged targets will be rebuilt.

## Example
Scala Z3 and Z3 Native are two existing targets that can be used and tested as part of PR#446

### Run the command:

`bazel run //:z3-copybara-import` or `bazel run //:scalaz3-copybara-import`

### Set the dependencies:

set the `EXPORTS` and `DEPS` field on the build rule that you want to consume scalaz3 to `//3rdparty/copybara/scalaz3:scalaz3`

Addtionally you will need to include `//shared/shared_jvm:native-loader` as a `DEPS` and `EXPORTS` in order to use nativeLib.Scala

### Import the correct library

In order for ScalaZ3 to work you need to import `nativeLib.Scala` and utilize the `NativeLib.loadLibraries()` method in your code to ensure all required libraries are loaded