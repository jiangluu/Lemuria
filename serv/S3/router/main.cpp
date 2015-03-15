#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef WIN32
	#include <winsock2.h>
	#include <Windows.h>
#else
	#include <signal.h>
#endif
#include "router.h"
//#include "LuaInterface.h"



#ifdef ENABLE_ENCRYPT
char *g_e_key = NULL;
#endif


// «∞÷√…˘√˜ 
void __installHandler();


int main(int argc, char** argv) {
	

#ifdef ENABLE_ENCRYPT
	// …Ë÷√√ÿ‘ø 
	g_e_key = (char*)malloc(256);
	FOR(i,256){
		g_e_key[i] = 'a'+(i%50);
	}
#endif	
	
	__installHandler();
	
	
	return 0;
}


void __defaultHandler(int sig)
{
#ifndef WIN32
	printf("signal  %d  got\n",sig);
	if(SIGSEGV == sig){
		_exit(-1);
	}
#endif
}

void __installHandler()
{
#ifndef WIN32
    signal(SIGHUP,   __defaultHandler);   /* 1 : hangup */
    signal(SIGINT,   __defaultHandler);   /* 2 : interrupt (rubout) */
    signal(SIGQUIT,  __defaultHandler);   /* 3 : quit (ASCII FS) */
    signal(SIGILL,   __defaultHandler);   /* 4 : illegal instruction */
    signal(SIGTRAP,  __defaultHandler);   /* 5 : trace trap */
    signal(SIGABRT,  __defaultHandler);   /* 6 : abort,replace SIGIOT in the future */
    signal(SIGBUS,  SIG_IGN);   /* 7: BUS error */
    signal(SIGFPE,   __defaultHandler);   /* 8 : floating point exception */
    signal(SIGKILL,  __defaultHandler);   /* 9 : Kill process */
    signal(SIGSEGV,  __defaultHandler);   /* 11 : segmentation violation */
    
    signal(SIGPIPE,  SIG_IGN); /* 13 : write on a pipe with no one to read it */
    signal(SIGALRM,  SIG_IGN);   /* 14 : alarm clock */
    signal(SIGTERM,  __defaultHandler);   /* 15 : software termination signal from kill */
    signal(SIGSTKFLT,  __defaultHandler);   /* 16 : Stack fault */
    //signal(SIGCHLD,  func);   /* 17 :Child status has changed*/
    //signal(SIGCONT,  SIG_IGN);   /* 18 :Continue*/
    //signal(SIGSTOP,   func);   /* 19 : Stop, unblockable*/
    //signal(SIGTSTP, func);   /* 20 : Keyboard stop */
    signal(SIGTTIN,   SIG_IGN);   /* 21 : Background read from tty*/
    signal(SIGTTOU,    SIG_IGN);   /* 22 : Background write to tty */
    //signal(SIGURG,    SIG_IGN);   /* 23 : Urgent condition on socket */
    
    //signal(SIGXCPU,  SIG_IGN);   /* 24 : CPU limit exceeded*/
    signal(SIGXFSZ,  __defaultHandler);   /* 25 : File size limit exceeded */
    //signal(SIGVTALRM,  SIG_IGN);   /* 26 : Virtual alarm clock*/
    //signal(SIGPROF,  SIG_IGN);   /* 27 : Profiling alarm clock */
    //signal(SIGWINCH,SIG_IGN);   /* 28 : Window size change */
    //signal(SIGIO,  func);   /* 29 : I/O now possible */
    signal(SIGPWR,  __defaultHandler);   /* 30 : Power failure restart*/
    //signal(SIGSYS,  func);   /* 31 : Bad system call */
#endif
}

