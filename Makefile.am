ACLOCAL_AMFLAGS = -I m4

AM_CPPFLAGS = -I${srcdir} -I${builddir} 
AM_CFLAGS = ${PIPE}
AM_CXXFLAGS = -Wextra -Wall ${PIPE} $(CXXTEMPLFLAGS)

if WANT_DEBUG
  LIB_G=libxthread_g.la
else
  LIB_G=
endif

libxthread_LTLIBRARIES = libxthread.la ${LIB_G}
libxthreaddir = $(libdir)

CXXTEMPLFLAGS = 
### --no-exceptions ## -fno-implicit-templates

libxthread_la_CFLAGS   = -O3 -fomit-frame-pointer ${PIPE}
libxthread_g_la_CFLAGS = ${PIPE}

libxthread_la_CXXFLAGS   = -O3 -fomit-frame-pointer ${PIPE} ${CXXTEMPLFLAGS}
## --no-rtti 
libxthread_g_la_CXXFLAGS = -g -Wextra -Wall -pedantic ${PIPE} ${CXXTEMPLFLAGS}
libxthread_g_la_LDFLAGS = -g -Wextra -Wall -pedantic
# -fdiagnostics-show-option 

libxthread_g_la_CPPFLAGS = ${AM_CPPFLAGS} -DDEBUG_THREADS

SOURCES  = xthread.cc
libxthread_la_SOURCES   = $(SOURCES)
libxthread_g_la_SOURCES = $(SOURCES)

# $(RT_LIBS) # librt is for the POSIX realtime extensions. I think it's only needed on Solaris.
libxthread_la_LIBADD = $(PTHREAD_LIBS)
libxthread_g_la_LIBADD = $(PTHREAD_LIBS)

# where should the header go?
libxthread_includedir  =$(includedir)/xthread/

libxthread_include_HEADERS = xthread.h tlsize.inc
nodist_libxthread_include_HEADERS = xthread_config.h

if WANT_DEBUG
TESTS = example-s-g example-s-r example-d-g example-d-r example2-s-g example2-s-r example2-d-g example2-d-r 
else
TESTS = example-s-r example-d-r example2-s-r example2-d-r 
endif
check_PROGRAMS = $(TESTS)



examplesources = example.cc
example_s_r_SOURCES = $(examplesources)
example_s_g_SOURCES = $(examplesources)
example_d_r_SOURCES = $(examplesources)
example_d_g_SOURCES = $(examplesources)

example_s_r_CFLAGS = -O3 -fomit-frame-pointer ${AM_CFLAGS}
example_d_r_CFLAGS = -O3 -fomit-frame-pointer ${AM_CFLAGS}

example_s_r_LDFLAGS = -static ${AM_LDFLAGS}
example_s_g_LDFLAGS = -static ${AM_LDFLAGS}

example_s_r_CXXFLAGS = -O3 -fomit-frame-pointer ${AM_CXXFLAGS}
example_s_g_CXXFLAGS = -g -pedantic ${AM_CXXFLAGS}
example_d_r_CXXFLAGS = -O3 -fomit-frame-pointer ${AM_CXXFLAGS}
example_d_g_CXXFLAGS = -g -pedantic ${AM_CXXFLAGS}

example_s_r_LDADD = libxthread.la
example_s_g_LDADD = libxthread_g.la
example_d_r_LDADD = libxthread.la
example_d_g_LDADD = libxthread_g.la

example_s_g_CPPFLAGS = ${AM_CPPFLAGS} -DDEBUG_THREADS
example_d_g_CPPFLAGS = ${AM_CPPFLAGS} -DDEBUG_THREADS

example2sources = example2.cc
example2_s_r_SOURCES = $(example2sources)
example2_s_g_SOURCES = $(example2sources)
example2_d_r_SOURCES = $(example2sources)
example2_d_g_SOURCES = $(example2sources)

example2_s_r_CFLAGS = -O3 -fomit-frame-pointer ${AM_CFLAGS}
example2_d_r_CFLAGS = -O3 -fomit-frame-pointer ${AM_CFLAGS}

example2_s_r_LDFLAGS = -static ${AM_LDFLAGS}
example2_s_g_LDFLAGS = -static ${AM_LDFLAGS}

example2_s_r_CXXFLAGS = -O3 -fomit-frame-pointer ${AM_CXXFLAGS}
example2_s_g_CXXFLAGS = -g -pedantic ${AM_CXXFLAGS}
example2_d_r_CXXFLAGS = -O3 -fomit-frame-pointer ${AM_CXXFLAGS}
example2_d_g_CXXFLAGS = -g -pedantic ${AM_CXXFLAGS}

example2_s_r_LDADD = libxthread.la
example2_s_g_LDADD = libxthread_g.la
example2_d_r_LDADD = libxthread.la
example2_d_g_LDADD = libxthread_g.la

example2_s_g_CPPFLAGS = ${AM_CPPFLAGS} -DDEBUG_THREADS
example2_d_g_CPPFLAGS = ${AM_CPPFLAGS} -DDEBUG_THREADS


