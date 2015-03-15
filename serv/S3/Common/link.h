#ifndef __LINK_H
#define __LINK_H


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "types.h"
#ifdef WIN32
#include <winsock2.h>
#include <errno.h>
#else
#include <unistd.h>
#include <sys/socket.h>    /* basic socket definitions */
#include <netinet/in.h>    /* sockaddr_in{} and other Internet defns */
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/tcp.h> /* for TCP_NODELAY */
#include <errno.h>                // for errno
#include <sys/epoll.h>
#endif

#include "kfifo.h"

//#define ENABLE_ENCRYPT 1

#ifdef ENABLE_ENCRYPT
	#include "polarssl/aes.h"
#endif


#ifdef WIN32
#define __USING_WINDOWS_IOCP 1
#else
#define closesocket close
#endif


#define LINK_APP_POOL_INDEX_NUM 2
#define LINK_ID_LEN 16


struct FrontEnd;

extern char *g_e_key;


// @NOTE: Link is NOT thread-safe 
#ifdef __USING_WINDOWS_IOCP
struct Link: public WSAOVERLAPPED{
	WSABUF	iocp_buff_;
    DWORD	bytes_recv_;
    DWORD	iocp_flag_;
    // IOCP因为是先投递请求，之后系统会把数据写到我们提供的buffer上，所以每个投递必须有自己的buffer，不能共享。 
#else
struct Link{
	struct epoll_event ev_;
	
#endif

#ifdef ENABLE_ENCRYPT
	aes_context aes_c_dec_;
#endif


	s16		pool_stat_;
	s16		link_stat_;
	bool	enable_encrypt_;
	char	link_id_[LINK_ID_LEN];
	int		pool_index_;	// 在池中的下标 
	int		sock_;
	int		read_buf_len_;
	char	*read_buf_;
	int		read_buf_offset_;
	kfifo	write_fifo_;
	
	int		lk_times_;		// 流控-包个数 
	int		lk_traffic_;	// 流控-流量 
	u32		last_active_time_;
	u32		first_packet_time_;
	u32		total_traffic_;
	// ========下面这几个数据概念上来说属于session数据，非客户端连接也许用不到 
	s32		session_link_index_; 	// 此session在哪个link 
	//s32		app_pool_index_[LINK_APP_POOL_INDEX_NUM];
	u16		app_box_id_;
	u16		app_actor_id_;
	u64		usersn_;
	
	
	virtual void cleanup(){
	#ifdef __USING_WINDOWS_IOCP
		// It's important to have the 2 lines below for windows
		WSAOVERLAPPED *ol = this;
		memset(ol,0,sizeof(WSAOVERLAPPED));
		iocp_buff_.buf = 0;
		iocp_buff_.	len = 0;
		bytes_recv_ = 0;
		iocp_flag_ = 0;
	#else
		ev_.events = EPOLLIN;
		ev_.data.ptr = this;
	#endif
	
	#ifdef ENABLE_ENCRYPT
		#define ENCRYPT_KEY_LEN 128
		aes_init(&aes_c_dec_);
		aes_setkey_dec(&aes_c_dec_,g_e_key,ENCRYPT_KEY_LEN);
	#endif
		link_stat_ = 0;
		enable_encrypt_ = false;
		link_id_[0] = 0;
		pool_index_ = 0;
		sock_ = -1;
		read_buf_offset_ = 0;
		kfifo_cleanup(&write_fifo_);
		
		lk_times_ = 0;
		lk_traffic_ = 0;
		last_active_time_ = 0;
		first_packet_time_ = 0;
		total_traffic_ = 0;
		
		session_link_index_ = -1;
		//app_pool_index_[0] = -1;
		//app_pool_index_[1] = -1;
		app_box_id_ = -1;
		app_actor_id_ = -1;
		usersn_ = 0;
	}
	
	void releaseSystemHandle(FrontEnd *nc);
	
	#ifdef __USING_WINDOWS_IOCP
	int post_recv(){
		iocp_buff_.buf = read_buf_+read_buf_offset_;
		int left = read_buf_len_ - read_buf_offset_;
		left = left>0?left:0;
		iocp_buff_.len = left;
		bytes_recv_ = 0;
        iocp_flag_ = 0;
        int rr = WSARecv(sock_, &iocp_buff_, 1, &bytes_recv_, &iocp_flag_, this, NULL);
        if( (SOCKET_ERROR == rr) && (WSA_IO_PENDING != WSAGetLastError())) {
        	fprintf(stderr,"WSAGetLastError [%d]\n",WSAGetLastError());
        	return 1;
        }
        return 0;
	}
	#else
	// EPOLL，注册读事件（永久的，直到显式反注册） 
	int register_read_event(FrontEnd *nc);
	#endif
	
	void allocate_mem(int read_buf_len,int write_fifo_len){
		read_buf_len_ = read_buf_len;
		read_buf_ = new char[read_buf_len];
		kfifo_init(&write_fifo_,write_fifo_len);
	}
	
	Link():pool_stat_(0),read_buf_len_(0),read_buf_(0){
		cleanup();
	}
	
	~Link(){
		if(read_buf_) delete []read_buf_;
		read_buf_ = 0;
		kfifo_free(&write_fifo_);
	}
	
	bool isOnline(){
		return 1==link_stat_;
	}
	
	// 从未在线的Link不分配输入输出缓存 
	void becomeOnline(int read_buf_len,int write_fifo_len){
		if(!isOnline() && NULL==read_buf_){
			allocate_mem(read_buf_len,write_fifo_len);
		}
		link_stat_ = 1;
	}
	
	bool isService(){
		return 'S'==link_id_[0];
	}
	
};





#endif
