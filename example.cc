#include "cstddef"
#include "iostream"
#include "thread.h"

struct ThreadLocalData {
  volatile unsigned long counter;
};

struct ThreadInfo {
  unsigned long arg;
  unsigned long result;
};

#include "tlsize.cc"

ConditionVariable *cond;
Lock *lock;

class ThreadBody : public ThreadAction {
public:
  virtual void main(Thread *self) {
    unsigned long i;
    unsigned long arg = self->info().arg;
    for (i=0; i<arg; i++)
      self->memory().counter++;
    self->info().result = self->memory().counter;
    lock->lock(); cond->signal(); lock->unlock();
  }
};

int main() {
  Thread *t1, *t2;
  ThreadBody body;
  lock = new Lock();
  cond = new ConditionVariable(lock);
  lock->lock();
  t1 = new Thread();
  t2 = new Thread();
  t1->info().arg =
  t2->info().arg = 100000000;
  t1->run(body); t2->run(body);
  cond->wait();  cond->wait();
  t1->wait();    t2->wait();
  lock->unlock();
  std::cout << "Result: " << t1->info().result + t2->info().result << "\n";
  delete t1; delete t2;
}
