#include "cstddef"
#include "iostream"
#include "thread.h"

struct ThreadLocalData {
  char buf[100];
};

struct ThreadInfo {
  unsigned arg;
};

#include "tlsize.cc"

#define TL (Thread::currentMemory())
#define TI (Thread::current()->info())

ConditionVariable *cond[2];
Lock *lock[2];

class ThreadBody : public ThreadAction {
public:
  virtual void main(Thread *self) {
    unsigned k = TI.arg;
    lock[k]->lock();
    cond[k]->signal();
    lock[k]->unlock();
  }
};

int main() {
  Thread *t1, *t2;
  ThreadBody body;
  lock[0] = new Lock();
  lock[1] = new Lock();
  cond[0] = new ConditionVariable(lock[0]);
  cond[1] = new ConditionVariable(lock[1]);
  lock[0]->lock();
  lock[1]->lock();
  t1 = new Thread();
  t2 = new Thread();
  t1->info().arg = 0;
  t2->info().arg = 1;
  t1->run(body); t2->run(body);
  cond[0]->wait(); cond[1]->wait();
  t1->wait();    t2->wait();
  lock[0]->unlock();
  lock[1]->unlock();
  delete t1; delete t2;
  std::cout << "Done.\n";
}
