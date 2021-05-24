load("@com_vistarmedia_rules_js//js:def.bzl", "npm_install")

LessFiles = [".less", ".css"]
LessLibrary = provider(fields = ["transitive_srcs"])

def less_repositories():
    npm_install(
        name = "less",
        version = "2.7.2",
        sha256 = "d57e3f45aa5c7d097728eefbd2fed91b040591b072dece36902a176db777d738",
    )

def _less_library(ctx):
    return [
        LessLibrary(
            transitive_srcs = depset(
                direct = ctx.files.srcs,
                transitive = [
                    dep[LessLibrary].transitive_srcs
                    for dep in ctx.attr.deps
                ],
            ),
        ),
    ]

def _less_binary(ctx):
    args = ctx.actions.args()
    args.add_all(ctx.files.srcs)
    args.add(ctx.outputs.css.path)

    ctx.actions.run(
        inputs = depset(
            direct = ctx.files.srcs,
            transitive = [dep[LessLibrary].transitive_srcs for dep in ctx.attr.deps],
        ),
        outputs = [ctx.outputs.css],
        executable = ctx.executable._lessc,
        tools = [ctx.executable._node],
        arguments = [args],
        mnemonic = "CompileLess",
    )

srcs_attr = attr.label_list(allow_files = LessFiles)
deps_attr = attr.label_list(providers = [LessLibrary])

less_library = rule(
    _less_library,
    attrs = {
        "srcs": srcs_attr,
        "deps": deps_attr,
    },
)

less_binary = rule(
    _less_binary,
    attrs = {
        "srcs": srcs_attr,
        "deps": deps_attr,
        "_lessc": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@com_vistarmedia_rules_less//less:lessc"),
        ),
        "_node": attr.label(
            executable = True,
            cfg = "host",
            default = Label("@com_vistarmedia_rules_js//js/toolchain:node"),
        ),
    },
    outputs = {
        "css": "%{name}.css",
    },
)
