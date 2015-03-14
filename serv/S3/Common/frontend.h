#ifndef __FRONT_END_H
#define __FRONT_END_H


#include "GameTime.h"
#include "packet_header.h"
#include "link.h"



//���������ǵ�ubuntuϵͳ�ϣ�ϵͳ��socket����д��������޶���131071 byte
//���cat /proc/sys/net/core/rmem_max
// cat /proc/sys/net/core/wmem_max
// �ʰ����ֵ��Ϊ131071
#define MY_SO_RCVBUF_MAX_LEN 131071


typedef int (*FrontEndMessageDispatch)(Link*,struct InternalHeader*,int,char*);
typedef int (*FrontEndMessageDispatch2)(Link*,struct ClientHeader*,int,char*);
typedef void (*LinkCut)(Link*,int reason,int frontend_type);


struct FrontEnd{
	enum{
		typeFrontEnd = 0,
		typeBackEnd,
	};
	
#ifdef __USING_WINDOWS_IOCP
	HANDLE iocp_handle_;
#else
	int epoll_fd_;
#endif
	
	int		type_;		// FrontEnd or BackEnd
	int		layer_;		// ���� 
	s16		header_type_;
	s16		stat_;
	bool	enable_encrypt_;
	// -------- ������Ϣ --------
	char	ip_and_port_[128];		// FrontEnd���͵��� 
	int		link_pool_size_conf_;
	int		read_buf_len_;
	int		write_fifo_len_;
	
	
	int listening_socket_;
	void *callback_;
	LinkCut link_cut_callback_;
	
	int	link_pool_size_;
	Link *link_pool_;
	
	
	FrontEnd():type_(0),layer_(0),header_type_(0),stat_(0),enable_encrypt_(false),link_pool_size_conf_(0),
	link_pool_size_(0),read_buf_len_(0),write_fifo_len_(0),listening_socket_(-1),
	callback_(0),link_cut_callback_(0),link_pool_(NULL),
	#ifdef __USING_WINDOWS_IOCP
		iocp_handle_(0)
	#else
		epoll_fd_(-1)
	#endif
	{
		ip_and_port_[0] = 0;
	}
	
	bool init(int type,int layer,int pool_size,int read_buf_len,int write_buf_len);
	
	bool resetLinkPool(int poolsize);
	
	void registerCallback(void* pfun,int ftype=0){	// ע����Ϣ�ַ��ص�������ftype Ϊ0��ʾ�ڲ���Ϣ��1��ʾ�ͻ�����Ϣ 
		callback_ = pfun;
		header_type_ = ftype;
	}
	void registerLinkCutCallback(LinkCut pfun){
		link_cut_callback_ = pfun;
	}
	
	bool start_listening();	// FrontEnd���͵Ĳ�Ӧ���� 
	
	bool connect2(char *global_id,char *ip_and_port);	// ������ BackEnd���͵Ĳ�Ӧ���У�����ʵ���ϲ������� 
	int connect2_no_care_id(char *ip_and_port);		// �ڲ�ʹ�ã��ⲿ��Ҫ���� 
	
	void frame_poll(timetype now,int block_time);	// һ֡��ȡ���ݣ��������block_time��֡�ʿ������ⲿ���ƣ���������޷����� 
	int frame_flush(timetype now);	// ����������������flush��ȥ 
	
	
	Link* newLink();
	void releaseLink(Link*);
	Link* getLink(int pool_index);
	void bindLinkWithGlobalID(char *gid,Link*);
	void unbind(char *gid);
	
	void forceCutLink(Link*);
	
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


