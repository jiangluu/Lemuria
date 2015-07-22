#ifndef __CAS_H
#define __CAS_H

#ifdef WIN32
//#include <Windows.h>
#else
#endif

/* Atomic operations for lock-free data structures.
 * CAS stands for Compare And Swap, the most common operation. 
 * google "CAS" "lock-free" for more details. */


 /* 语义等同于：
 if (*x == oldval) { *x=newval; return 1; } else return 0; 
 但是是原子操作 */
inline bool cas32(volatile int* x,int oldval,int newval) {
#ifdef WIN32
	//return _InterlockedCompareExchange((volatile long*)x,newval,oldval)==oldval;
	return __sync_bool_compare_and_swap(x,oldval,newval);
#else
	return __sync_bool_compare_and_swap(x,oldval,newval);
#endif
}

inline bool cas16(volatile short* x,short oldval,short newval) {
#ifdef WIN32
	//return _InterlockedCompareExchange16(x,newval,oldval)==oldval;
	return __sync_bool_compare_and_swap(x,oldval,newval);
#else
	return __sync_bool_compare_and_swap(x,oldval,newval);
#endif
}


#endif
