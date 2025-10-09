
local util = require("cmake.internal.util")

local M = {
    cmake_executable_path = "cmake",
    build_dir = "build",
    source_dir = ".",
    build_types = { "MinSizeRel", "Debug", "Release", "RelWithDebInfo" },
    build_type = "Debug",
    build_target = "",
    user_args = {
        configuration = {},
        build = {},
        install = {},
    },
}

function M.setup(user_opts)
    user_opts = user_opts or {}
    user_opts.user_args = user_opts.user_args or {}

    M.cmake_executable_path = util.resolve(user_opts.cmake_executable_path) or M.cmake_executable_path
    M.build_dir = util.resolve(user_opts.build_dir) or M.build_dir
    M.source_dir = util.resolve(user_opts.source_dir) or M.source_dir
    M.build_types = util.resolve(user_opts.build_types) or M.build_types
    M.build_type = util.resolve(user_opts.default_build_type) or M.build_type
    M.build_target = M.build_target

    M.user_args = M.user_args or {}
    M.user_args.configuration = util.resolve(user_opts.user_args.configuration) or M.user_args.configuration
    M.user_args.build = util.resolve(user_opts.user_args.build) or M.user_args.build
    M.user_args.install = util.resolve(user_opts.user_args.install) or M.user_args.install
end

return M

