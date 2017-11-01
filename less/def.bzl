load('@io_bazel_rules_js//js:def.bzl', 'npm_install')

LessFiles = FileType(['.less', '.css'])


def less_repositories():
  npm_install(
    name = 'less',
    version = '2.7.2',
    sha256 = 'd57e3f45aa5c7d097728eefbd2fed91b040591b072dece36902a176db777d738',
  )

def _collect_deps(ctx):
  deps = depset(order='postorder')
  for dep in ctx.attr.deps:
    deps += dep.transitive_less
  return deps


def _less_library(ctx):
  transitive_less = _collect_deps(ctx) + LessFiles.filter(ctx.files.srcs)

  return struct(
    files = depset(),
    transitive_less = transitive_less,
  )


def _less_binary(ctx):
  transitive_less = _collect_deps(ctx)

  args = [less.path for less in ctx.files.srcs]
  args += [ctx.outputs.css.path]

  ctx.action(
    inputs     = list(transitive_less) + list(ctx.files.srcs) + \
                 [ctx.executable._node],
    outputs    = [ctx.outputs.css],
    executable = ctx.executable._lessc,
    arguments  = args,
    mnemonic   = 'CompileLess',
  )

srcs_attr = attr.label_list(allow_files=LessFiles)
deps_attr = attr.label_list(providers=['transitive_less'])


less_library = rule(
  _less_library,
  attrs = {
    'srcs': srcs_attr,
    'deps': deps_attr,
  }
)

less_binary = rule(
  _less_binary,
  attrs = {
    'srcs': srcs_attr,
    'deps': deps_attr,

    '_lessc': attr.label(
      executable = True,
      cfg        = 'host',
      default    = Label('@com_vistarmedia_rules_less//less:lessc')),

    '_node': attr.label(
      executable = True,
      cfg        = 'host',
      default    = Label('@io_bazel_rules_js//js/toolchain:node')),
  },
  outputs = {
    'css': '%{name}.css',
  }
)
