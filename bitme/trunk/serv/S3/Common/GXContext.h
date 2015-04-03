#ifndef __GXCONTEXT_H
#define __GXCONTEXT_H


#include <string>
#include "GameTime.h"
#include "packet_header.h"
#include "AStream.h"
#include "link.h"
#include "omt.h"



//查了在我们的ubuntu系统上，系统的socket读、写缓存的上限都是163840 byte
//命令：cat /proc/sys/net/core/rmem_max
// cat /proc/sys/net/core/wmem_max
// 故把这个值定为163840
#define MY_SO_RCVBUF_MAX_LEN 163840

struct GXContext;

typedef int (*GXContextMessageDispatch)(GXContext*,Link*,struct InternalHeader*,int,char*);
typedef int (*GXContextMessageDispatch2)(GXContext*,Link*,struct ClientHeader*,int,char*);
typedef void (*LinkCut)(GXContext*,Link*,int reason,int gxcontext_type);


struct GXContext{
	enum{
		typeFullFunction = 0,
		typeSimple,
	};
	
	enum{
		typePortalRouter = 0,
		typePortalCustom,
	};
	
#ifdef __USING_WINDOWS_IOCP
	HANDLE iocp_handle_;
#else
	int epoll_fd_;
#endif
	
	s16		type_;		// typeFullFunction or typeSimple
	s16		layer_;		// 层数 
	s16		header_type_;
	s16		stat_;
	bool	enable_encrypt_;
	// -------- 配置信息 --------
	char	ip_and_port_[128];		// 本上下文的物理地址
	int		link_pool_size_conf_;
	int		read_buf_len_;
	int		write_fifo_len_;
	
	
	int listening_socket_;
	void *callback_;
	LinkCut link_cut_callback_;
	
	int	link_pool_size_;
	Link *link_pool_;
	
	struct omt_tree *map_portal_;
	
	struct InputContext{
		struct GXContext *gxc_;
		int src_link_pool_index_;
		int header_type_;
		InternalHeader header_;
		ClientHeader header2_;
		
		AStream *rs_;
		AStream *ws_;
		
		void reset(){	// 不释放内存，只是为了复用 
			gxc_ = 0;
			src_link_pool_index_ = -1;
			header_type_ = 0;
			memset(&header_,0,sizeof(header_));
			memset(&header2_,0,sizeof(header2_));
		}
	};
	
	InputContext input_context_;
	
	
	GXContext():type_(0),layer_(0),header_type_(0),stat_(0),enable_encrypt_(false),link_pool_size_conf_(0),
	link_pool_size_(0),read_buf_len_(0),write_fifo_len_(0),listening_socket_(-1),
	callback_(0),link_cut_callback_(0),link_pool_(NULL),map_portal_(NULL),
	#ifdef __USING_WINDOWS_IOCP
		iocp_handle_(0)
	#else
		epoll_fd_(-1)
	#endif
	{
		ip_and_port_[0] = 0;
	}
	
	bool init(int type,int pool_size,int read_buf_len,int write_buf_len);
	
	void free();
	
	bool resetLinkPool(int poolsize);
	
	void registerCallback(void* pfun,int ftype=0){	// 注册消息分发回调函数。ftype 为0表示内部消息，1表示客户端消息 
		callback_ = pfun;
		header_type_ = ftype;
	}
	void registerLinkCutCallback(LinkCut pfun){
		link_cut_callback_ = pfun;
	}
	
	bool start_listening();
	
	bool connect2(char *global_id,char *ip_and_port);
	
	
	void frame_poll(timetype now,int block_time);	// 一帧拉取数据，最多阻塞block_time。帧率控制由外部控制，这个函数无法控制 
	int frame_flush(timetype now);	// 把输出缓冲里的数据flush出去 
	
	
	Link* newLink();
	void releaseLink(Link*);
	Link* getLink(int pool_index);
	void bindLinkWithGlobalID(char *gid,Link*);
	void unbind(char *gid);
	
	void forceCutLink(Link*);
	
	int connect2_no_care_id(char *ip_and_port);
	
	
	// GX functions
	int sendToPortal(const char* destID,int datalen,void *data);
	int sendToPortal(int localPoolIndex,const char* destID,int datalen,void *data);		// faster version of above
	int createPortal(int typee,const char* ID);
	int freePortal(int typee,const char* ID);
	int freePortal(int localPoolIndex);
	int findPortal(int typee,const char* ID);
	
	// level-1
	int syncWriteBack(int msgid,int datalen,void *data);
	
	// level-2
	
	// level-3
	int packetRouteToNode(const char* destID,int msgid,int datalen,void *data);
	
private:
	int try_deal_one_msg_s(Link *ioable,int &begin);
};



// JUST HELP FUNCTIONS
int nc_setsockopt_server(int fd);
int nc_setsockopt_client(int fd);
int nc_connect(int sock,const char *ip,int port);
int nc_bind(int sock,int port);
int nc_set_no_delay(int sock);
int nc_set_reuse_addr(int sock);
int nc_set_nonblock(int sock);
int nc_get_ip(int sock,char *out_ip,int max_len);
int nc_read(intptr_t fd,char *buf,int buf_len,int &real_read);
int nc_write(intptr_t fd,char *buf,int buf_len,int &real_write);



#endif


