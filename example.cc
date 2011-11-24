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

#define TL (Thread::currentMemory())
#define TI (Thread::current()->info())

class ThreadBody : public ThreadAction {
public:
  virtual void main(Thread *self) {
    unsigned long i;
    unsigned long arg = TI.arg;
    for (i=0; i<arg; i++)
      TL.counter++;
    TI.result = TL.counter;
  }
};

int main() {
  Thread *t1, *t2;
  ThreadBody body;
  t1 = new Thread();
  t2 = new Thread();
  t1->info().arg =
  t2->info().arg = 100000000;
  t1->run(body); t2->run(body);
  t1->wait();    t2->wait();
  std::cout << "Result: " << t1->info().result + t2->info().result << "\n";
  delete t1; delete t2;
}
