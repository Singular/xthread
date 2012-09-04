AC_INIT([xthread], [0.1])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([auxes])
AC_CONFIG_SRCDIR([xthread.h])
AC_CONFIG_HEADER([xthread_config.h])

AM_MAINTAINER_MODE
AM_INIT_AUTOMAKE([-Wall foreign subdir-objects]) # -Wno-extra-portability -Werror silent-rules

dnl Check if build env is sane
AM_SANITY_CHECK

#
# - Check for CC and CXX but be careful about CFLAGS.
#
test "${CFLAGS+set}" = set || cflags_expl_set=no
AC_PROG_CC
test "${CXXFLAGS+set}" = set || cxxflags_expl_set=no
AC_PROG_CXX
if test "x$GCC" != xyes && test "x$GXX" != xyes; then
  AC_MSG_WARN(you better use gcc to compile Factory)
else
  if test "x$GXX" = xyes && test "x$cxxflags_expl_set" = xno; then
    AC_MSG_WARN([we use \`' as default for \`CXXFLAGS'
                    (instead of the configure default \`-g -O')])
  fi
  if test "x$GCC" = xyes && test "x$cflags_expl_set" = xno; then
    AC_MSG_WARN([we use \`' as default for \`CFLAGS'
                    (instead of the configure default \`-g -O')])
  fi
fi

AM_PROG_CC_C_O
# AM_PROG_AR

AC_PROG_LN_S
AC_PROG_INSTALL

AC_FUNC_MALLOC
AC_HEADER_STDC
AC_CHECK_HEADERS([stdlib.h string.h unistd.h sys/mman.h])

AC_CHECK_FUNCS(posix_memalign mmap mprotect alloca)
# __builtin_frame_address

#AX_CHECK_FUNC_IN(alloca.h, alloca, [], [AC_MSG_ERROR([Sorry but alloca is necessary!])])
#AX_CHECK_FUNC_IN(sys/mman.h, mmap, [], [AC_MSG_ERROR([Sorry but mmap is necessary!])])
#AX_CHECK_FUNC_IN(sys/mman.h, mprotect, [], [AC_MSG_ERROR([Sorry but mprotect is necessary!])])
#AX_CHECK_FUNC_IN(stdlib.h, posix_memalign, [], [])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
#AC_HEADER_STDBOOL
#AC_TYPE_SIZE_T

# Turn off shared libraries during beta-testing, since they
# make the build process take too long.
LT_INIT
# ([shared])
# LT_INIT(dlopen disable-static) # doesn't work on PowerPC!


SING_CHECK_PIPE

AX_CHECK_ATOMIC_OPS

AX_GCC_ALWAYS_INLINE

# ?????
# AC_CHECK_LIB(rt, aio_error, RT_LIBS=-lrt, RT_LIBS=)
# AC_SUBST(RT_LIBS)

# In fact, a lot of the code in this directory depends on pthreads
AX_PTHREAD([], [AC_MSG_ERROR([Sorry but pthread is necessary!])])

LIBS="$PTHREAD_LIBS $LIBS"
CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
CC="$PTHREAD_CC"

AC_CHECK_LIB(pthread, pthread_attr_setstack,[], [AC_MSG_ERROR([Sorry but pthread_attr_setstack from pthread is necessary!])])

AX__THREAD


AC_ARG_ENABLE(debug, AS_HELP_STRING([--enable-debug], [build the debugging version of the libraries]),
 [if test "x$enableval"  = "xyes"; then
   ENABLE_DEBUG=yes
 fi], ENABLE_DEBUG=no)

AM_CONDITIONAL(WANT_DEBUG, test x"${ENABLE_DEBUG}" == xyes)

#if test x"${ENABLE_DEBUG}" == xyes; then
#  AC_DEFINE([DEBUG_THREADS],[1],[Enable Thread Debugging checks])
#fi

# CFLAGS
if test "x$GCC" = xyes && test "x$cflags_expl_set" = xno; then
  CFLAGS=""
fi
  
# CXXFLAGS
if test "x$GXX" = xyes && test "x$cxxflags_expl_set" = xno; then
  CXXFLAGS=""
fi

# Add pre'prefixed config
AX_PREFIX_CONFIG_H([xthread_config.h],[],[xthread_config.h])

AH_VERBATIM([PTHREADS_CRASHES_IF_RUN_TOO_EARLY],
	    [/* Mark the systems where we know it's bad if pthreads runs too
   early before main (before threads are initialized, presumably).  */
#ifdef __FreeBSD__
#define PTHREADS_CRASHES_IF_RUN_TOO_EARLY 1
#endif])


AH_BOTTOM([/* This can be used instead of 'inline' key-word wherever it is time-critical */
#ifdef GCC_ALWAYS_INLINE
#define FORCE_INLINE GCC_ALWAYS_INLINE
#else
#define FORCE_INLINE inline
#endif
])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
