#!/bin/bash

set -euo pipefail

export WORKFLOW_DEFS="{workflow_defs}"
export COMMAND="{command}"


cp ${WORKFLOW_DEFS} copy.bara.sky # gets around symlink shenanigans
cp copybara/workflow_files/* . # load in additional_files
${COMMAND}
