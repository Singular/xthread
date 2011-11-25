#ifndef _THREAD_H
#define _THREAD_H

#include <limits.h>
#include <pthread.h>
#include <stdint.h>
#include <alloca.h>
#include <cstddef>
#include <exception>

#if LONG_BIT == 32
#define LOG2_STACK_AREA_SIZE 18
#else
#define LOG2_STACK_AREA_SIZE 20
#endif

#define STACK_AREA_SIZE (1<<LOG2_STACK_AREA_SIZE)
#define STACK_AREA_MASK ~(STACK_AREA_SIZE-1)

#ifdef STACK_GROWS_UP
#define ThreadInitMainStack() \
  do { \
    int dummy[0]; \
    alloca(STACK_AREA_SIZE-(((uintptr_t) dummy) & ~STACK_AREA_MASK)); \
    ThreadGrowMainStack(); \
  } while (0)
#else
#define ThreadInitMainStack() \
  do { \
    int dummy[0]; \
    alloca(((uintptr_t) dummy) & ~STACK_AREA_MASK); \
    ThreadGrowMainStack(); \
  } while (0)
#endif

struct ThreadLocalData;
struct ThreadInfo;

std::size_t threadLocalDataSize();
std::size_t threadInfoSize();

extern std::size_t threadLocalDataSize_;
extern std::size_t threadInfoSize_;

class ThreadAction;
typedef long ThreadID;

class ThreadException : public std::exception {
private:
  const char *message;
public:
  virtual const char *what() const throw() {
    return message;
  }
  ThreadException(const char *message_init) { message = message_init; }
};

void ThreadError(const char *message);

class Thread {
private:
  void *stack_bottom;
  std::size_t stack_size;
  pthread_t descriptor;
  ThreadID thread_num;
public:
  Thread();
  void Thread0(); // pseudo constructor for main thread
  ~Thread();
  ThreadID id() { return thread_num; }
  void* operator new(std::size_t size);
  void operator delete(void *memory);
  void run(ThreadAction& body);
  void run(void (*body)(Thread *));
  void wait();
  static Thread* current() {
    void *stack;
#ifdef __GNUC__
    stack = __builtin_frame_address(0);
#else
    int dummy[0];
    stack = dummy;
#endif
    return reinterpret_cast<Thread *>(((uintptr_t) stack) & STACK_AREA_MASK);
  }
  ThreadLocalData& memory() {
    char *base = reinterpret_cast<char *>(this);
    return *reinterpret_cast<ThreadLocalData*>(
      base + sizeof(Thread)
    );
  }
  ThreadInfo& info() {
    char *base = reinterpret_cast<char *>(this);
    return *reinterpret_cast<ThreadInfo*>(
      base + sizeof(Thread) + threadLocalDataSize_
    );
  }
  static ThreadLocalData& currentMemory() {
    return current()->memory();
  }
};

class ThreadAction {
public:
  virtual void main(Thread *thread) = 0;
};

void ThreadGrowMainStack();

class ConditionVariable;

class Lock {
private:
  pthread_mutex_t mutex;
  friend class ConditionVariable;
#ifdef DEBUG_THREADS
  Thread *owner;
#endif
public:
  Lock() {
    pthread_mutex_init(&mutex, NULL);
#ifdef DEBUG_THREADS
    owner = NULL;
#endif
  }
  ~Lock() {
    pthread_mutex_destroy(&mutex);
  }
  void lock() {
#ifdef DEBUG_THREADS
    if (owner == Thread::current())
      ThreadError("locking mutex twice");
#endif
    pthread_mutex_lock(&mutex);
#ifdef DEBUG_THREADS
    owner = Thread::current();
#endif
  }
  void unlock() {
#ifdef DEBUG_THREADS
    if (owner != Thread::current());
      ThreadError("unlocking unowned lock");
#endif
    pthread_mutex_unlock(&mutex);
  }
};

class ReadWriteLock {
private:
  pthread_rwlock_t rwlock;
public:
  ReadWriteLock() {
    pthread_rwlock_init(&rwlock, NULL);
  }
  ~ReadWriteLock() {
    pthread_rwlock_destroy(&rwlock);
  }
  void readLock() {
    pthread_rwlock_rdlock(&rwlock);
  }
  void writeLock() {
    pthread_rwlock_wrlock(&rwlock);
  }
  void unlock() {
    pthread_rwlock_unlock(&rwlock);
  }
};

class ConditionVariable {
private:
  pthread_cond_t condition;
  Lock *lock;
  friend class Semaphore;
  ConditionVariable() { }
public:
  ConditionVariable(Lock *lock0) {
    lock = lock0;
    pthread_cond_init(&condition, NULL);
  }
  ~ConditionVariable() {
    pthread_cond_destroy(&condition);
  }
  void wait() {
#ifdef DEBUG_THREADS
    if (lock->owner != Thread::current())
      ThreadError("waited on condition without locked mutex");
#endif
    pthread_cond_wait(&condition, &lock->mutex);
  }
  void signal() {
#ifdef DEBUG_THREADS
    if (lock->owner != Thread::current())
      ThreadError("signaled condition without locked mutex");
#endif
    pthread_cond_signal(&condition);
  }
  void broadcast() {
#ifdef DEBUG_THREADS
    if (lock->owner != Thread::current())
      ThreadError("signaled condition without locked mutex");
#endif
    pthread_cond_broadcast(&condition);
  }
};

class Semaphore {
private:
  Lock lock;
  ConditionVariable condition;
  unsigned count;
  unsigned waiting;
public:
  Semaphore() {
    condition.lock = &lock;
    count = 0;
  }
  Semaphore(unsigned count0) {
    count = count0;
  }
  void wait();
  void post();
};

#endif // _THREAD_H
