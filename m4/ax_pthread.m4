dnl ===========================================================================
dnl        http://www.gnu.org/software/autoconf-archive/ax_pthread.html
dnl ===========================================================================
dnl
dnl @SYNOPSIS  AX_PTHREAD([ACTION-IF-FOUND[, ACTION-IF-NOT-FOUND]])
dnl
dnl @summary figure out how to build C programs using POSIX threads
dnl
dnl   This macro figures out how to build C programs using POSIX threads. It
dnl   sets the PTHREAD_LIBS output variable to the threads library and linker
dnl   flags, and the PTHREAD_CFLAGS output variable to any special C compiler
dnl   flags that are needed. (The user can also force certain compiler
dnl   flags/libs to be tested by setting these environment variables.)
dnl
dnl   Also sets PTHREAD_CC to any special C compiler that is needed for
dnl   multi-threaded programs (defaults to the value of CC otherwise). (This
dnl   is necessary on AIX to use the special cc_r compiler alias.)
dnl
dnl   NOTE: You are assumed to not only compile your program with these flags,
dnl   but also link it with them as well. e.g. you should link with
dnl   $PTHREAD_CC $CFLAGS $PTHREAD_CFLAGS $LDFLAGS ... $PTHREAD_LIBS $LIBS
dnl
dnl   If you are only building threads programs, you may wish to use these
dnl   variables in your default LIBS, CFLAGS, and CC:
dnl
dnl     LIBS="$PTHREAD_LIBS $LIBS"
dnl     CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
dnl     CC="$PTHREAD_CC"
dnl
dnl   In addition, if the PTHREAD_CREATE_JOINABLE thread-attribute constant
dnl   has a nonstandard name, defines PTHREAD_CREATE_JOINABLE to that name
dnl   (e.g. PTHREAD_CREATE_UNDETACHED on AIX).
dnl
dnl   Also HAVE_PTHREAD_PRIO_INHERIT is defined if pthread is found and the
dnl   PTHREAD_PRIO_INHERIT symbol is defined when compiling with
dnl   PTHREAD_CFLAGS.
dnl
dnl   ACTION-IF-FOUND is a list of shell commands to run if a threads library
dnl   is found, and ACTION-IF-NOT-FOUND is a list of commands to run it if it
dnl   is not found. If ACTION-IF-FOUND is not specified, the default action
dnl   will define HAVE_PTHREAD.
dnl
dnl   Please let the authors know if this macro fails on any platform, or if
dnl   you have any other suggestions or comments. This macro was based on work
dnl   by SGJ on autoconf scripts for FFTW (http://www.fftw.org/) (with help
dnl   from M. Frigo), as well as ac_pthread and hb_pthread macros posted by
dnl   Alejandro Forero Cuervo to the autoconf macro repository. We are also
dnl   grateful for the helpful feedback of numerous users.
dnl
dnl   Updated for Autoconf 2.68 by Daniel Richard G.
dnl
dnl LICENSE
dnl
dnl   Copyright (c) 2008 Steven G. Johnson <stevenj@alum.mit.edu>
dnl   Copyright (c) 2011 Daniel Richard G. <skunk@iSKUNK.ORG>
dnl
dnl   This program is free software: you can redistribute it and/or modify it
dnl   under the terms of the GNU General Public License as published by the
dnl   Free Software Foundation, either version 3 of the License, or (at your
dnl   option) any later version.
dnl
dnl   This program is distributed in the hope that it will be useful, but
dnl   WITHOUT ANY WARRANTY; without even the implied warranty of
dnl   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
dnl   Public License for more details.
dnl
dnl   You should have received a copy of the GNU General Public License along
dnl   with this program. If not, see <http://www.gnu.org/licenses/>.
dnl
dnl   As a special exception, the respective Autoconf Macro's copyright owner
dnl   gives unlimited permission to copy, distribute and modify the configure
dnl   scripts that are the output of Autoconf when processing the Macro. You
dnl   need not follow the terms of the GNU General Public License when using
dnl   or distributing such scripts, even though portions of the text of the
dnl   Macro appear in them. The GNU General Public License (GPL) does govern
dnl   all other use of the material that constitutes the Autoconf Macro.
dnl
dnl   This special exception to the GPL applies to versions of the Autoconf
dnl   Macro released by the Autoconf Archive. When you make and distribute a
dnl   modified version of the Autoconf Macro, you may extend this special
dnl   exception to the GPL to apply to your modified version as well.

#serial 18

AU_ALIAS([ACX_PTHREAD], [AX_PTHREAD])
AC_DEFUN([AX_PTHREAD], [
AC_REQUIRE([AC_CANONICAL_HOST])
AC_LANG_PUSH([C])
ax_pthread_ok=no

dnl We used to check for pthread.h first, but this fails if pthread.h
dnl requires special compiler flags (e.g. on True64 or Sequent).
dnl It gets checked for in the link test anyway.

dnl First of all, check if the user has set any of the PTHREAD_LIBS,
dnl etcetera environment variables, and if threads linking works using
dnl them:
if test x"$PTHREAD_LIBS$PTHREAD_CFLAGS" != x; then
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        AC_MSG_CHECKING([for pthread_join in LIBS=$PTHREAD_LIBS with CFLAGS=$PTHREAD_CFLAGS])
        AC_TRY_LINK_FUNC(pthread_join, ax_pthread_ok=yes)
        AC_MSG_RESULT($ax_pthread_ok)
        if test x"$ax_pthread_ok" = xno; then
                PTHREAD_LIBS=""
                PTHREAD_CFLAGS=""
        fi
        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"
fi

dnl We must check for the threads library under a number of different
dnl names; the ordering is very important because some systems
dnl (e.g. DEC) have both -lpthread and -lpthreads, where one of the
dnl libraries is broken (non-POSIX).

dnl Create a list of thread flags to try.  Items starting with a "-" are
dnl C compiler flags, and other items are library names, except for "none"
dnl which indicates that we try without any flags at all, and "pthread-config"
dnl which is a program returning the flags for the Pth emulation library.

ax_pthread_flags="pthreads none -Kthread -kthread lthread -pthread -pthreads -mthreads pthread --thread-safe -mt pthread-config"

dnl The ordering *is* (sometimes) important.  Some notes on the
dnl individual items follow:

dnl pthreads: AIX (must check this before -lpthread)
dnl none: in case threads are in libc; should be tried before -Kthread and
dnl       other compiler flags to prevent continual compiler warnings
dnl -Kthread: Sequent (threads in libc, but -Kthread needed for pthread.h)
dnl -kthread: FreeBSD kernel threads (preferred to -pthread since SMP-able)
dnl lthread: LinuxThreads port on FreeBSD (also preferred to -pthread)
dnl -pthread: Linux/gcc (kernel threads), BSD/gcc (userland threads)
dnl -pthreads: Solaris/gcc
dnl -mthreads: Mingw32/gcc, Lynx/gcc
dnl -mt: Sun Workshop C (may only link SunOS threads [-lthread], but it
dnl      doesn't hurt to check since this sometimes defines pthreads too;
dnl      also defines -D_REENTRANT)
dnl      ... -mt is also the pthreads flag for HP/aCC
dnl pthread: Linux, etcetera
dnl --thread-safe: KAI C++
dnl pthread-config: use pthread-config program (for GNU Pth library)

case ${host_os} in
        solaris*)

        dnl On Solaris (at least, for some versions), libc contains stubbed
        dnl (non-functional) versions of the pthreads routines, so link-based
        dnl tests will erroneously succeed.  (We need to link with -pthreads/-mt/
        dnl -lpthread.)  (The stubs are missing pthread_cleanup_push, or rather
        dnl a function called by this macro, so we could check for that, but
        dnl who knows whether they'll stub that too in a future libc.)  So,
        dnl we'll just look for -pthreads and -lpthread first:

        ax_pthread_flags="-pthreads pthread -mt -pthread $ax_pthread_flags"
        ;;

        darwin*)
        ax_pthread_flags="-pthread $ax_pthread_flags"
        ;;
esac

if test x"$ax_pthread_ok" = xno; then
for flag in $ax_pthread_flags; do

        case $flag in
                none)
                AC_MSG_CHECKING([whether pthreads work without any flags])
                ;;

                -*)
                AC_MSG_CHECKING([whether pthreads work with $flag])
                PTHREAD_CFLAGS="$flag"
                ;;

                pthread-config)
                AC_CHECK_PROG(ax_pthread_config, pthread-config, yes, no)
                if test x"$ax_pthread_config" = xno; then continue; fi
                PTHREAD_CFLAGS="`pthread-config --cflags`"
                PTHREAD_LIBS="`pthread-config --ldflags` `pthread-config --libs`"
                ;;

                *)
                AC_MSG_CHECKING([for the pthreads library -l$flag])
                PTHREAD_LIBS="-l$flag"
                ;;
        esac

        save_LIBS="$LIBS"
        save_CFLAGS="$CFLAGS"
        LIBS="$PTHREAD_LIBS $LIBS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        dnl Check for various functions.  We must include pthread.h,
        dnl since some functions may be macros.  (On the Sequent, we
        dnl need a special flag -Kthread to make this header compile.)
        dnl We check for pthread_join because it is in -lpthread on IRIX
        dnl while pthread_create is in libc.  We check for pthread_attr_init
        dnl due to DEC craziness with -lpthreads.  We check for
        dnl pthread_cleanup_push because it is one of the few pthread
        dnl functions on Solaris that doesn't have a non-functional libc stub.
        dnl We try pthread_create on general principles.
        AC_LINK_IFELSE([AC_LANG_PROGRAM([#include <pthread.h>
                        static void routine(void *a) { a = 0; }
                        static void *start_routine(void *a) { return a; }],
                       [pthread_t th; pthread_attr_t attr;
                        pthread_create(&th, 0, start_routine, 0);
                        pthread_join(th, 0);
                        pthread_attr_init(&attr);
                        pthread_cleanup_push(routine, 0);
                        pthread_cleanup_pop(0) /* ; */])],
                [ax_pthread_ok=yes],
                [])

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        AC_MSG_RESULT($ax_pthread_ok)
        if test "x$ax_pthread_ok" = xyes; then
                break;
        fi

        PTHREAD_LIBS=""
        PTHREAD_CFLAGS=""
done
fi

dnl Various other checks:
if test "x$ax_pthread_ok" = xyes; then
        save_LIBS="$LIBS"
        LIBS="$PTHREAD_LIBS $LIBS"
        save_CFLAGS="$CFLAGS"
        CFLAGS="$CFLAGS $PTHREAD_CFLAGS"

        dnl Detect AIX lossage: JOINABLE attribute is called UNDETACHED.
        AC_MSG_CHECKING([for joinable pthread attribute])
        attr_name=unknown
        for attr in PTHREAD_CREATE_JOINABLE PTHREAD_CREATE_UNDETACHED; do
            AC_LINK_IFELSE([AC_LANG_PROGRAM([#include <pthread.h>],
                           [int attr = $attr; return attr /* ; */])],
                [attr_name=$attr; break],
                [])
        done
        AC_MSG_RESULT($attr_name)
        if test "$attr_name" != PTHREAD_CREATE_JOINABLE; then
            AC_DEFINE_UNQUOTED(PTHREAD_CREATE_JOINABLE, $attr_name,
                               [Define to necessary symbol if this constant
                                uses a non-standard name on your system.])
        fi

        AC_MSG_CHECKING([if more special flags are required for pthreads])
        flag=no
        case ${host_os} in
            aix* | freebsd* | darwin*) flag="-D_THREAD_SAFE";;
	    osf* | hpux* | *-*-netbsd* ) flag="-D_REENTRANT";; # Required define if using POSIX threads.
            solaris*)
            if test "$GCC" = "yes"; then
                flag="-D_REENTRANT"
            else
                flag="-mt -D_REENTRANT"
            fi
            ;;
        esac
        AC_MSG_RESULT(${flag})
        if test "x$flag" != xno; then
            PTHREAD_CFLAGS="$flag $PTHREAD_CFLAGS"
        fi

        AC_CACHE_CHECK([for PTHREAD_PRIO_INHERIT],
            ax_cv_PTHREAD_PRIO_INHERIT, [
                AC_LINK_IFELSE([
                    AC_LANG_PROGRAM([[#include <pthread.h>]], [[int i = PTHREAD_PRIO_INHERIT;]])],
                    [ax_cv_PTHREAD_PRIO_INHERIT=yes],
                    [ax_cv_PTHREAD_PRIO_INHERIT=no])
            ])
        AS_IF([test "x$ax_cv_PTHREAD_PRIO_INHERIT" = "xyes"],
            AC_DEFINE([HAVE_PTHREAD_PRIO_INHERIT], 1, [Have PTHREAD_PRIO_INHERIT.]))

        LIBS="$save_LIBS"
        CFLAGS="$save_CFLAGS"

        dnl More AIX lossage: must compile with xlc_r or cc_r
        if test x"$GCC" != xyes; then
          AC_CHECK_PROGS(PTHREAD_CC, xlc_r cc_r, ${CC})
        else
          PTHREAD_CC=$CC
        fi

	dnl The next part tries to detect GCC inconsistency with -shared on some
	dnl architectures and systems. The problem is that in certain
	dnl configurations, when -shared is specified, GCC "forgets" to
	dnl internally use various flags which are still necessary.
	
	dnl
	dnl Prepare the flags
	dnl
	save_CFLAGS="$CFLAGS"
	save_LIBS="$LIBS"
	save_CC="$CC"
	
	dnl Try with the flags determined by the earlier checks.
	dnl
	dnl -Wl,-z,defs forces link-time symbol resolution, so that the
	dnl linking checks with -shared actually have any value
	dnl
	dnl FIXME: -fPIC is required for -shared on many architectures,
	dnl so we specify it here, but the right way would probably be to
	dnl properly detect whether it is actually required.
	CFLAGS="-shared -fPIC -Wl,-z,defs $CFLAGS $PTHREAD_CFLAGS"
	LIBS="$PTHREAD_LIBS $LIBS"
	CC="$PTHREAD_CC"
	
	dnl In order not to create several levels of indentation, we test
	dnl the value of "$done" until we find the cure or run out of ideas.
	done="no"
	
	dnl First, make sure the CFLAGS we added are actually accepted by our
	dnl compiler.  If not (and OS X's ld, for instance, does not accept -z),
	dnl then we can't do this test.
	if test x"$done" = xno; then
	   AC_MSG_CHECKING([whether to check for GCC pthread/shared inconsistencies])
	   AC_TRY_LINK(,, , [done=yes])
	
	   if test "x$done" = xyes ; then
	      AC_MSG_RESULT([no])
	   else
	      AC_MSG_RESULT([yes])
	   fi
	fi
	
	if test x"$done" = xno; then
	   AC_MSG_CHECKING([whether -pthread is sufficient with -shared])
	   AC_TRY_LINK([#include <pthread.h>],
	      [pthread_t th; pthread_join(th, 0);
	      pthread_attr_init(0); pthread_cleanup_push(0, 0);
	      pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
	      [done=yes])
	   
	   if test "x$done" = xyes; then
	      AC_MSG_RESULT([yes])
	   else
	      AC_MSG_RESULT([no])
	   fi
	fi
	
	dnl
	dnl Linux gcc on some architectures such as mips/mipsel forgets
	dnl about -lpthread
	dnl
	if test x"$done" = xno; then
	   AC_MSG_CHECKING([whether -lpthread fixes that])
	   LIBS="-lpthread $PTHREAD_LIBS $save_LIBS"
	   AC_TRY_LINK([#include <pthread.h>],
	      [pthread_t th; pthread_join(th, 0);
	      pthread_attr_init(0); pthread_cleanup_push(0, 0);
	      pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
	      [done=yes])
	
	   if test "x$done" = xyes; then
	      AC_MSG_RESULT([yes])
	      PTHREAD_LIBS="-lpthread $PTHREAD_LIBS"
	   else
	      AC_MSG_RESULT([no])
	   fi
	fi
	dnl
	dnl FreeBSD 4.10 gcc forgets to use -lc_r instead of -lc
	dnl
	if test x"$done" = xno; then
	   AC_MSG_CHECKING([whether -lc_r fixes that])
	   LIBS="-lc_r $PTHREAD_LIBS $save_LIBS"
	   AC_TRY_LINK([#include <pthread.h>],
	       [pthread_t th; pthread_join(th, 0);
	        pthread_attr_init(0); pthread_cleanup_push(0, 0);
	        pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
	       [done=yes])
	
	   if test "x$done" = xyes; then
	      AC_MSG_RESULT([yes])
	      PTHREAD_LIBS="-lc_r $PTHREAD_LIBS"
	   else
	      AC_MSG_RESULT([no])
	   fi
	fi
	if test x"$done" = xno; then
	   dnl OK, we have run out of ideas
	   AC_MSG_WARN([Impossible to determine how to use pthreads with shared libraries])
	
	   dnl so it's not safe to assume that we may use pthreads
	   ax_pthread_ok=no
	fi
	
	AC_MSG_CHECKING([whether what we have so far is sufficient with -nostdlib])
	CFLAGS="-nostdlib $CFLAGS"
	dnl we need c with nostdlib
	LIBS="$LIBS -lc"
	AC_TRY_LINK([#include <pthread.h>],
	      [pthread_t th; pthread_join(th, 0);
	       pthread_attr_init(0); pthread_cleanup_push(0, 0);
	       pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
	      [done=yes],[done=no])

	if test "x$done" = xyes; then
	   AC_MSG_RESULT([yes])
	else
	   AC_MSG_RESULT([no])
	fi
	
	if test x"$done" = xno; then
	   AC_MSG_CHECKING([whether -lpthread saves the day])
	   LIBS="-lpthread $LIBS"
	   AC_TRY_LINK([#include <pthread.h>],
	      [pthread_t th; pthread_join(th, 0);
	       pthread_attr_init(0); pthread_cleanup_push(0, 0);
	       pthread_create(0,0,0,0); pthread_cleanup_pop(0); ],
	      [done=yes],[done=no])

	   if test "x$done" = xyes; then
	      AC_MSG_RESULT([yes])
	      PTHREAD_LIBS="$PTHREAD_LIBS -lpthread"
	   else
	      AC_MSG_RESULT([no])
	      AC_MSG_WARN([Impossible to determine how to use pthreads with shared libraries and -nostdlib])
	   fi
	fi

	CFLAGS="$save_CFLAGS"
	LIBS="$save_LIBS"
	CC="$save_CC"

else
        PTHREAD_CC="$CC"
fi

AC_SUBST(PTHREAD_LIBS)
AC_SUBST(PTHREAD_CFLAGS)
AC_SUBST(PTHREAD_CC)

dnl Finally, execute ACTION-IF-FOUND/ACTION-IF-NOT-FOUND:
if test x"$ax_pthread_ok" = xyes; then
        ifelse([$1],,AC_DEFINE(HAVE_PTHREAD,1,[Define if you have POSIX threads libraries and header files.]),[$1])
        :
else
        ax_pthread_ok=no
        $2
fi
AC_LANG_POP
])dnl AX_PTHREAD
