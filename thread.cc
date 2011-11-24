#include <list>
#include <vector>

#include <stdint.h>
#include <sys/mman.h>

#include "thread.h"

using namespace std;

static Lock threadManagerLock;
static list<ThreadID> threadIDs;
static ThreadID maxThreadID;

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
  size_t tlssize = (sizeof(Thread) +
    threadLocalDataSize() + threadInfoSize() + pagesize - 1)
    & ~(pagesize -1);
  addr = mmap(0, 2 * STACK_AREA_SIZE, PROT_READ|PROT_WRITE,
    MAP_PRIVATE|MAP_ANONYMOUS, -1 , 0);
  result = THREADP((((uintptr_t) addr) + (STACK_AREA_SIZE-1))
    & STACK_AREA_MASK);
  munmap(addr, CHARP(result)-CHARP(addr));
  munmap(CHARP(result)+STACK_AREA_SIZE,
    CHARP(addr)-CHARP(result)+STACK_AREA_SIZE);
  /* generate a stack overflow protection area */
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
  pthread_attr_setstack(&attr, stack_bottom, stack_size);
  pthread_create(&descriptor, &attr, dispatchThread, &body);
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
