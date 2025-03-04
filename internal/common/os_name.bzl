# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Helper function for repository rules
"""

load(":check_version.bzl", "check_version")

OS_ARCH_NAMES = [
    ("windows", "amd64"),
    ("darwin", "amd64"),
    ("darwin", "arm64"),
    ("linux", "amd64"),
    ("linux", "arm64"),
    ("linux", "s390x"),
]

OS_NAMES = ["_".join(os_arch_name) for os_arch_name in OS_ARCH_NAMES]

def os_name(rctx):
    """Get the os name for a repository rule

    Args:
      rctx: The repository rule context

    Returns:
      A string describing the os for a repository rule
    """
    os_name = rctx.os.name.lower()
    if os_name.find("windows") != -1:
        return OS_NAMES[0]

    # This is not ideal, but bazel doesn't directly expose arch.
    arch = rctx.execute(["uname", "-m"]).stdout.strip()
    if os_name.startswith("mac os"):
        if arch == "x86_64":
            return OS_NAMES[1]
        elif arch == "arm64":
            return OS_NAMES[2]
    elif os_name.startswith("linux"):
        if arch == "x86_64":
            return OS_NAMES[3]
        elif arch == "aarch64":
            return OS_NAMES[4]
        elif arch == "s390x":
            return OS_NAMES[5]

    fail("Unsupported operating system {} architecture {}".format(os_name, arch))

def is_windows_os(rctx):
    return os_name(rctx) == OS_NAMES[0]

def is_darwin_os(rctx):
    name = os_name(rctx)
    return name == OS_NAMES[1] or name == OS_NAMES[2]

def is_linux_os(rctx):
    name = os_name(rctx)
    return name == OS_NAMES[3] or name == OS_NAMES[4] or name == OS_NAMES[5]

def node_exists_for_os(node_version, os_name):
    "Whether a node binary is available for this platform"
    is_16_or_greater = check_version(node_version, "16.0.0")

    # There is no Apple Silicon native version of node before 16
    return is_16_or_greater or os_name != "darwin_arm64"

def assert_node_exists_for_host(rctx):
    node_version = rctx.attr.node_version
    if not node_exists_for_os(node_version, os_name(rctx)):
        fail("No nodejs is available for {} at version {}".format(os_name(rctx), node_version) +
             "\n    Consider upgrading by setting node_version in a call to node_repositories in WORKSPACE." +
             "\n    Note that Node 16.x is the minimum published for Apple Silicon (M1 Macs)")
