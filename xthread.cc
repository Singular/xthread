#include <list>
#include <vector>

#include <cstring>
#include <unistd.h>
#include <sys/mman.h>

#include "xthread.h"

using namespace std;

static Lock threadManagerLock;
static list<ThreadID> threadIDs;
static ThreadID maxThreadID;

size_t threadLocalDataSize_ = threadLocalDataSize();
size_t threadInfoSize_ = threadInfoSize();

class BasicThreadAction : public ThreadAction {
private:
  void (*body)(Thread *);
public:
  BasicThreadAction(void (*body0)(Thread *)) {
    body = body0;
  }
  virtual void main(Thread *arg) {
    body(arg);
  }
};

void ThreadError(const char *message) {
  throw new ThreadException(message);
}

Thread::Thread() {
  threadManagerLock.lock();
  if (!threadIDs.empty()) {
    thread_num = threadIDs.front();
    threadIDs.pop_front();
  } else {
    thread_num = ++maxThreadID;
  }
  threadManagerLock.unlock();
  memset(&info(), 0, threadInfoSize());
  memset(&memory(), 0, threadLocalDataSize());
}

void Thread::Thread0() {
  thread_num = 0;
  descriptor = pthread_self();
  memset(&info(), 0, threadInfoSize());
  memset(&memory(), 0, threadLocalDataSize());
}


Thread::~Thread() {
  threadManagerLock.lock();
  threadIDs.push_back(thread_num);
  threadManagerLock.unlock();
}

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

#define CHARP(x) (reinterpret_cast<char *>(x))
#define VOIDP(x) (reinterpret_cast<char *>(x))
#define THREADP(x) (reinterpret_cast<Thread *>(x))

void* Thread::operator new(size_t size) {
  void *addr;
  Thread *result;
  size_t pagesize = getpagesize();
  // Thread-local storage area is rounded up the next highest multiple
  // of the page size.
  size_t tlssize = (sizeof(Thread) +
    threadLocalDataSize() + threadInfoSize() + pagesize - 1)
    & ~(pagesize -1);
  // Allocate twice the needed memory with anonymous mmap().
  addr = mmap(0, 2 * STACK_AREA_SIZE, PROT_READ|PROT_WRITE,
    MAP_PRIVATE|MAP_ANONYMOUS, -1 , 0);
  // Find the smallest multiple of STACK_AREA_SIZE within the area.
  result = THREADP((((uintptr_t) addr) + (STACK_AREA_SIZE-1))
    & STACK_AREA_MASK);
  // Unmap all memory before and after it.
  munmap(addr, CHARP(result)-CHARP(addr));
  munmap(CHARP(result)+STACK_AREA_SIZE,
    CHARP(addr)-CHARP(result)+STACK_AREA_SIZE);
  // Generate a stack overflow protection area and record
  // the size and start of the actual stack.
#ifdef STACK_GROWS_UP
  mprotect(CHARP(result) + STACK_AREA_SIZE - tlssize - pagesize,
    pagesize, PROT_NONE);
  result->stack_bottom = CHARP(result) + tlssize;
#else
  mprotect(CHARP(result) + tlssize, pagesize, PROT_NONE);
  result->stack_bottom = CHARP(result) + tlssize + pagesize;
#endif
  result->stack_size = STACK_AREA_SIZE - tlssize - pagesize;
  return result;
}

void Thread::operator delete(void *memory) {
  munmap(memory, STACK_AREA_SIZE);
}

static void *dispatchThread(void *arg) {
  ThreadAction* action = static_cast<ThreadAction*>(arg);
  action->main(Thread::current());
}

void Thread::run(ThreadAction &body) {
  pthread_attr_t attr;
  pthread_attr_init(&attr);
  // Regardless of which direction the stack grows, the
  // pthread_attr_setstack() call requires a pointer to the
  // start of it.
  pthread_attr_setstack(&attr, stack_bottom, stack_size);
  if (pthread_create(&descriptor, &attr, dispatchThread, &body) < 0)
    ThreadError("could not start thread");
}

void Thread::run(void (*body)(Thread *)) {
  BasicThreadAction action(body);
  run(action);
}

void Thread::wait() {
  if (!thread_num)
    ThreadError("cannot wait for main thread");
  pthread_join(descriptor, NULL);
}

void ThreadGrowMainStack() {
  // This function makes sure that all pages on the main stack get paged
  // in in the proper order; some operating systems will cause a page fault
  // and crash if stack area allocation skips too many pages.
  char *tls = reinterpret_cast<char *>(Thread::current());
  size_t pagesize = getpagesize();
  char *p = CHARP(alloca(pagesize/2));
  // alloca() may allocate more bytes than requested, so
  // we proceed in steps smaller than the actual page size.
#ifdef STACK_GROWS_UP
  tls += STACK_AREA_SIZE;
  while (p < tls) {
#else
  while (p > tls) {
#endif
    *p = '\0'; /* touch page */
    p = CHARP(alloca(pagesize/2));
  }
  // And finally, initialize the thread-local storage.
  Thread::current()->Thread0();
}

void Semaphore::wait() {
  lock.lock();
  waiting++;
  while (count == 0)
    condition.wait();
  waiting--;
  count--;
  lock.unlock();
}

void Semaphore::post() {
  lock.lock();
  if (count++ == 0 && waiting)
    condition.signal();
  lock.unlock();
}
