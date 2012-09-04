#include "cstddef"
#include "iostream"
#include "xthread.h"

struct ThreadLocalData {
  volatile unsigned long counter;
};

struct ThreadInfo {
  unsigned long arg;
  unsigned long result;
};

#include "tlsize.inc"

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

#include <iostream>

int main() {
  Thread *t1, *t2;
  try 
  {
  ThreadBody body;
  ThreadInitMainStack(); // Initialize main thread's thread-local memory.
                         // This has to be done in the main function;
			 // ThreadInitMainStack() is a macro that uses
			 // alloca() to move the stack pointer and will
			 // not work once you return from a function that
			 // calls it.
  t1 = new Thread(); // Create two new threads
  t2 = new Thread(); // Creating threads does not start them
  t1->info().arg = t2->info().arg = 100000000; // Pass arguments to both
  t1->run(body); t2->run(body); // Actually run them
  t1->wait();    t2->wait(); // Wait for both to complete
  std::cout << "Result: " << t1->info().result + t2->info().result << "\n";
  delete t1; delete t2; // reclaim thread memory
  }
  catch( const std::exception & ex ) 
  {
    std::cerr << "There was an exception: " << ex.what() << std::endl;
    throw;
  }
}
