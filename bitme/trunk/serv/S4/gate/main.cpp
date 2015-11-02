#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef WIN32
	#include <winsock2.h>
	#include <Windows.h>
#else
	#include <signal.h>
#endif
#include "gate.h"
#include "LuaInterface.h"




#ifdef ENABLE_ENCRYPT
char *g_e_key = NULL;
#endif
LuaInterface *g_luavm = 0;
GameTime *g_time = 0;
ARand *g_rand = 0;
ALog *g_log = 0;
GXContext *g_gx1 = 0;
GXContext *g_gx2 = 0;

int g_duanlianjie = 0;
int g_stop_loop = 0;


// ǰ������ 
void __installHandler();

int message_dispatch(GXContext*,Link* src_link,InternalHeader *hh,int body_len,char *body);
void on_client_cut(GXContext*,Link *ll,int reason,int gxcontext_type);

int message_dispatch_2(GXContext*,Link* src_link,ClientHeader *hh,int body_len,char *body);
void on_client_cut_2(GXContext*,Link *ll,int reason,int gxcontext_type);

void frame_time_driven(timetype now);



int main(int argc, char** argv) {
	if(argc < 2){
		printf("argv error.\n");
		return -1;
	}
	

#ifdef ENABLE_ENCRYPT
	// ������Կ 
	g_e_key = (char*)malloc(256);
	memset(g_e_key,0,256);
	FOR(i,4){
		memcpy(g_e_key+i*32,"VlzjIc1hIgc5Yc6Hxb10Z8Rp5hU3Dc2w",32);
	}
#endif	
	
	FOR(i,argc){
		if(0 == strcmp(argv[i],"--duan")){
			g_duanlianjie = 1;
			printf("use duanlianjie mode\n");
		}
	}
	
	__installHandler();
	
	
	// ��ʼ��ʱ�� 
	g_time = new GameTime();
	g_time->init();
	
	g_rand = new ARand((u32)g_time->getANSITime());
	
	g_log = new ALog();
	char buf1[64];
	snprintf(buf1,60,"log%s",argv[1]);
	if(!g_log->init(buf1)){
		printf("Log init error\n");
		_exit(-1);
	}
	g_log->setTimer(g_time);
	
	
	// ��ȡ�����ļ�
	g_luavm = new LuaInterface();
	g_luavm->Init();
	
	
	// ��ʼ��GX������
	int config_maxconn = g_luavm->callGlobalFunc<int>("getMaxConn");
	int config_readbuflen = g_luavm->callGlobalFunc<int>("getReadBufLen");
	int config_writebuflen = g_luavm->callGlobalFunc<int>("getWriteBufLen");
	
	g_luavm->SetGlobal(LUA_GX_ID,(const char*)argv[1]);
	std::string my_port = g_luavm->callGlobalFunc<std::string>("getMyPort");
	
	g_gx1 = new GXContext();
	g_gx1->init(GXContext::typeFullFunction,argv[1],8,1024*1024*8,1024*1024*8);
	strncpy(g_gx1->ip_and_port_,my_port.c_str(),127);
	
	g_gx1->registerCallback((void*)message_dispatch,0);
	
	g_gx1->registerLinkCutCallback(on_client_cut);
	
	if(!g_gx1->start_listening()){
		_exit(-1);
	}
	
	gx_set_context(g_gx1);
	
	int init_r = g_luavm->callGlobalFunc<int>("PostInit");
	if(0 != init_r){
		printf("Lua PostInit() failed.\n");
		_exit(-2);
	}
	
	
	// �����ڶ���GX�����ģ�Ϊ�ͻ���׼���� 
	my_port = g_luavm->callGlobalFunc<std::string>("getMyPort2");
	
	g_gx2 = new GXContext();
	g_gx2->init(GXContext::typeFullFunction,argv[1],config_maxconn,config_readbuflen,config_writebuflen);
	strncpy(g_gx2->ip_and_port_,my_port.c_str(),127);
	
	g_gx2->registerCallback((void*)message_dispatch_2,1);
	
	g_gx2->registerLinkCutCallback(on_client_cut_2);
	
#ifdef ENABLE_ENCRYPT
	g_gx2->enable_encrypt_ = true;
#endif
	
	if(!g_gx2->start_listening()){
		_exit(-1);
	}
	

	
	// ������ѭ�� 
	static int frame_time_max = 10;		// ÿ֡�����CPU�ȴ�10��ǧ��֮һ�� 
	
	printf("server inited. start running...\n");
	
	while(0 == g_stop_loop){
		g_time->setTime();
		timetype now = g_time->currentTime();
		g_time->incLocalFrame();
		
		
		g_gx2->frame_poll(now,frame_time_max/2);
		g_gx1->frame_poll(now,frame_time_max/2);
		
		// �ڲ�ʱ������
		frame_time_driven(now);
		
		g_gx2->frame_flush(now);
		g_gx1->frame_flush(now);
	}
	
	
	printf("exit main_loop\n");
	fprintf(stderr,"exit main_loop\n");
	
	
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

