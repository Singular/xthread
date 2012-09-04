libs = [ "xthread" ]
cflags = "-g -O0"
linkflags = "-g"

Threads=DefaultEnvironment()

Threads.Append(LIBPATH=".")
Threads.Append(CCFLAGS=cflags)
Threads.Append(LINKFLAGS=linkflags)

conf = Configure(Threads)
if conf.CheckLib("pthread"):
  libs.append("pthread")
# if conf.CheckLib("rt"):
#   libs.append("rt")

Threads.Append(LIBS=libs)

Threads.Library(["xthread"], ["xthread.cc"])
Program("example.cc")
Program("example2.cc")
