#include "GXContext.h"
#include "ARand.h"
#include "CAS.h"



extern ARand *g_rand;


// HELP FUNCTIONS

int nc_setsockopt_server(int fd)
{
    int size = MY_SO_RCVBUF_MAX_LEN;
    int r;
    r = setsockopt(fd, SOL_SOCKET, SO_RCVBUF,(const char *) &size, sizeof(size)); if (r == -1) return r;
    r = setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (const char *) &size, sizeof(size)); if (r == -1) return r;
    return 0;
}

int nc_setsockopt_client(int fd)
{
    int size = MY_SO_RCVBUF_MAX_LEN;
    int r;
    r = setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (const char *)&size, sizeof(size)); if (r == -1) return r;
    r = setsockopt(fd, SOL_SOCKET, SO_SNDBUF, (const char *)&size, sizeof(size)); if (r == -1) return r;
    return 0;
}


int nc_connect(int sock,const char *ip,int port)
{
    struct sockaddr_in xsin;
    memset(&xsin,0,sizeof(xsin));
    xsin.sin_addr.s_addr = ::inet_addr(ip);
    xsin.sin_family = AF_INET;
    xsin.sin_port = htons((short)port);
    
    return ::connect(sock,(struct sockaddr *)&xsin, sizeof(xsin));
}

int nc_bind(int sock,int port)
{
    struct sockaddr_in xsin;
    memset(&xsin,0,sizeof(xsin));
    xsin.sin_addr.s_addr = 0;
    xsin.sin_family = AF_INET;
    xsin.sin_port = htons((short)port);
    
    int st = ::bind(sock,(struct sockaddr *)&xsin, sizeof(xsin));
    return st;
}

int nc_set_no_delay(int sock)
{
    int on = 1; // TCP_NODELAY
    return ::setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, (const char*)&on, sizeof (on));
}

int nc_set_reuse_addr(int sock)
{
    int on = 1;
    return ::setsockopt(sock,SOL_SOCKET, SO_REUSEADDR, (const char*)&on, sizeof(on));
}

int nc_set_nonblock(int sock)
{
#ifdef WIN32
    unsigned long   w = 1 ;
    ::ioctlsocket(sock ,FIONBIO,&w) ;
#else
    int val = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, val | O_NONBLOCK);
#endif
    return 0;
}

int nc_set_block(int sock)
{
#ifdef WIN32
    unsigned long   w = 0 ;
    ::ioctlsocket(sock ,FIONBIO,&w) ;
#else
    int val = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, val & (~O_NONBLOCK));
#endif
    return 0;
}

int nc_get_ip(int sock,char *out_ip,int max_len)
{
	if(0==out_ip || max_len<64){
		return -1;
	}
	
	sockaddr_in sa;
#ifdef WIN32
    int len = sizeof(sa);
#else
    socklen_t len = sizeof(sa);
#endif
    getpeername(sock,(struct sockaddr *)&sa,&len);
    char *aa = inet_ntoa(*(in_addr *)&sa.sin_addr.s_addr);
    strncpy(out_ip,aa,max_len);
    
    return 0;
}

std::string nc_get_ip(int sock)
{
    sockaddr_in sa;
#ifdef WIN32
    int len = sizeof(sa);
#else
    socklen_t len = sizeof(sa);
#endif
    getpeername(sock,(struct sockaddr *)&sa,&len);
    std::string ip = inet_ntoa(*(in_addr *)&sa.sin_addr.s_addr);
    
    return ip;
}

int nc_read(intptr_t fd,char *buf,int buf_len,int &real_read)
{
	real_read = 0;
#ifdef WIN32
	int nrecv = recv(fd,buf,buf_len,0);
#else
	int nrecv = read(fd,buf,buf_len);
#endif
	
	if(nrecv > 0){
		real_read = nrecv;
		return 1;
	}
	else if(nrecv == 0){
		return 0;
	}
	else{
#ifdef WIN32
		int err = WSAGetLastError();
		if(err==WSAEWOULDBLOCK){
			return 1;
		}
		else{
			return 0;
		}
#else
		if(errno==EAGAIN || errno==EWOULDBLOCK){
			return 1;
		}
		else{
			return 0;
		}
#endif
	}
	return 0;
}

int nc_write(intptr_t fd,char *buf,int buf_len,int &real_write)
{
	real_write = 0;
	if(buf==0 || buf_len<=0) return 1;
	
#ifdef WIN32
	int nrecv = send(fd,buf,buf_len,0);
#else
	int nrecv = write(fd,buf,buf_len);
#endif
	
	if(nrecv > 0){
		real_write = nrecv;
		return 1;
	}
	else if(nrecv == 0){
		return 0;
	}
	else{
#ifdef WIN32
		int err = WSAGetLastError();
		if(err==WSAEWOULDBLOCK){
			return 1;
		}
		else{
			return 0;
		}
#else
		if(errno==EAGAIN || errno==EWOULDBLOCK){
			return 1;
		}
		else{
			return 0;
		}
#endif
	}
	return 0;
}


// =================================================================

#define min(a,b) (a)<(b)?(a):(b)


/*��kfifo�е����ݣ�ǡ������������д����һ��ȫ��д�ꡣ
���������Щ��������kfifo�ڲ����ƺ�����ģ�黯��
���ǲ�����__kfifo_get �����ݴ�kfifo���ó�������������д��������ΪЧ���϶���һ��memcpy��
�����ó��������ݲ�һ����ȫ��д��������ȥ��ûд�������û������kfifo��û�������Ľӿڣ�
Ҳд������
�ڲ�ʹ�ã�����ļ�֮��ĵط���Ӧ�õ��á� 
*/
int __kfifo_2_net(struct kfifo *fifo,intptr_t fd,u32 len)
{
	u32 l = 0;
	int ok = 0;
	int real_write = 0;
	int real_write2 = 0;
	
	len = min(len, fifo->in - fifo->out);

	/* first get the data from fifo->out until the end of the buffer */
	l = min(len, fifo->size - (fifo->out & (fifo->size - 1)));
	// for test
	//if(l < len){
	//	printf("���۷�[%d]���ֽ�\n",len-l);
	//}
	ok = nc_write(fd,(char*)(fifo->buffer + (fifo->out & (fifo->size - 1))),l,real_write);
	if(ok!=1 || real_write<l){
		fifo->out += real_write;
		return real_write;
	}

	/* then get the rest (if any) from the beginning of the buffer */
	ok = nc_write(fd,(char*)fifo->buffer,len - l,real_write2);
	if(ok!=1 || real_write2<(len - l)){
		fifo->out += (l+real_write2);
		return (l+real_write2);
	}

	fifo->out += len;
	
	return len;
}

// =================================================================


struct PortalPrint{
	int stat_;
	int pool_index_;
};
	

bool GXContext::init(int type,const char* ID,int pool_size,int read_buf_len,int write_buf_len)
{
	type_ = type;
	
	strncpy(gx_id_,ID,LINK_ID_LEN);
	
	link_pool_size_conf_ = pool_size;
	read_buf_len_ = read_buf_len;
	write_fifo_len_ = write_buf_len;
	
#ifdef WIN32
	WORD wVersionRequested;
    WSADATA wsaData;
    wVersionRequested = MAKEWORD( 2, 2 );
    int err = WSAStartup( wVersionRequested, &wsaData ); 
    iocp_handle_ = CreateIoCompletionPort(INVALID_HANDLE_VALUE,NULL,0,1);
    if(NULL == iocp_handle_){
    	printf("Init IOCP failed!! exit...\n");
    	exit(-1);
    }
    
#else
	epoll_fd_ = epoll_create(100);		//  Since Linux 2.6.8, the size argument is unused
	if (-1 == epoll_fd_) {
		printf("epoll_create failed!\n");
		exit(-1);
	}
	
	
#endif
	
	link_pool_ = new Link[pool_size];
	if(0 == link_pool_){
		printf("init lnk_pool failed! exit...\n");
    	exit(-1);
	}
	link_pool_size_ = pool_size;
	
	stat_ = 1;
	
	input_context_.reset();
	rs_ = new AStream(0,0);
	void* mem = calloc(1,write_buf_len);
	ws_ = new AStream(write_buf_len,(char*)mem);
	rs_bak_ = rs_;
	ws_bak_ = ws_;
	
	// init luaVM only for self
	{
		lua_vm_ = luaL_newstate();
		luaopen_base(lua_vm_);
		luaopen_table(lua_vm_);
		
		char buf[32];
		FOR(i,GX_LUA_INDICATOR_NUM){
			sprintf(buf,"__indicator%d",i);
			lua_newtable(lua_vm_);
			lua_setfield(lua_vm_, LUA_GLOBALSINDEX, buf);		// prevent it to be GC
			lua_getfield(lua_vm_, LUA_GLOBALSINDEX, buf);
			lua_indicator_[i] = lua_gettop(lua_vm_);
		}
	}
	
	return true;
}

void GXContext::free()
{
	// @TODO
}


bool GXContext::resetLinkPool(int pool_size)
{
	if(link_pool_){
		delete []link_pool_;
		link_pool_ = NULL;
	}
	
	link_pool_ = new Link[pool_size];
	if(0 == link_pool_){
		printf("init lnk_pool failed! exit...\n");
    	exit(-1);
	}
	
	link_pool_size_ = pool_size;
	return true;
}


Link* GXContext::newLink()
{
	//int ff = g_rand->rand32() % link_pool_size_;
	int ff = 0;
	
	for(int i=ff;i<link_pool_size_;++i){
		if(0 == link_pool_[i].pool_stat_){
			Link *aa = link_pool_+i;
			if(cas16(&aa->pool_stat_,0,1)){
				aa->cleanup();
				aa->pool_index_ = i;
			}
			return aa;
		}
	}
	
	FOR(i,ff){
		if(0 == link_pool_[i].pool_stat_){
			Link *aa = link_pool_+i;
			if(cas16(&aa->pool_stat_,0,1)){
				aa->cleanup();
				aa->pool_index_ = i;
			}
			return aa;
		}
	}
	
	return NULL;
}

void GXContext::releaseLink(Link *ll)
{
	// ��֤���ָ���ȷ��һ���Ϸ���link ������Ұָ�� 
	if(link_pool_ <= ll && ll < link_pool_+link_pool_size_){
		ll->pool_stat_ = 0;
	}
	else{
		printf("releaseLink error\n");
	}
}

Link* GXContext::getLink(int pool_index)
{
	if(pool_index<0 || pool_index>=link_pool_size_) return NULL;
	
	Link *aa = link_pool_+pool_index;
	if(1==aa->pool_stat_) return aa;
	
	return NULL;
}

void GXContext::bindLinkWithGlobalID(char *gid,Link *l)
{
	if(NULL==gid || NULL==l) return;
	
	strncpy(l->link_id_,gid,LINK_ID_LEN-1);
	
    lua_pushinteger(lua_vm_,l->pool_index_);
    lua_setfield(lua_vm_,lua_indicator_[0],(const char*)gid);
}

void GXContext::unbind(char *gid)
{	
    lua_pushnil(lua_vm_);
    lua_setfield(lua_vm_,lua_indicator_[0],(const char*)gid);
}

int GXContext::findPortal(int typee,const char* ID)
{
	lua_getfield(lua_vm_,lua_indicator_[0],ID);
	
	if(lua_isnumber(lua_vm_,-1)){
		lua_Integer r = lua_tointeger(lua_vm_,-1);
		lua_pop(lua_vm_,1);
		
		return r;
	}
	else{
		return -1;
	}
}

int GXContext::createPortal(int typee,const char* ID)
{
	Link *l = newLink();
	if(l){
		int index = l->pool_index_;
		bindLinkWithGlobalID(ID,l);
		return index;
	}
	
	return -1;
}

int GXContext::freePortal(int localPoolIndex)
{
	Link *l = getLink(localPoolIndex);
	if(l){
		releaseLink(l);
		return localPoolIndex;
	}
	
	return -1;
}

int GXContext::freePortal(int typee,const char* ID)
{
	int pool_index = findPortal(typee,ID);
	if(pool_index >= 0){
		int r = freePortal(pool_index);
		unbind(ID);
		return r;
	}
	
	return -1;
}

int GXContext::sendToPortal(int localPoolIndex,const char* destID,int datalen,void *data)
{
	Link *l = getLink(localPoolIndex);
	if(l && (NULL==destID || 0 == strncmp(destID,l->link_id_,LINK_ID_LEN))){
		kfifo *ff = &l->write_fifo_;
		return __kfifo_put(ff,(unsigned char*)data,datalen);
	}
	
	return -1;
}

int GXContext::sendToPortal(const char* destID,int datalen,void *data)
{
	if(NULL == destID) return -1;
	int index = findPortal(0,destID);
	if(index >= 0){
		return sendToPortal(index,destID,datalen,data);
	}
	
	return -1;
}

int GXContext::syncWriteBack(int msgid,int datalen,void *data)
{
	datalen = datalen>0?datalen:0;
	
	int index = input_context_.src_link_pool_index_;
	Link *l = getLink(index);
	if(l){
		kfifo *ff = &l->write_fifo_;
		if(0 == input_context_.header_type_){
			InternalHeader h;
			// ���ﲻֱ���� input_context_.header_��ԭ���ǣ�������h���������side effect 
			memcpy(&h,&input_context_.header_,sizeof(h));
			h.message_id_ = msgid;
			h.len_ = CLIENT_HEADER_LEN + datalen;
			h.flag_ |= HEADER_FLAG_BACK;
			
			__kfifo_put(ff,(unsigned char*)&h,INTERNAL_HEADER_LEN);
		}
		else{
			ClientHeader &h = input_context_.header2_;
			h.message_id_ = msgid;
			h.len_ = CLIENT_HEADER_LEN + datalen;
			
			__kfifo_put(ff,(unsigned char*)&h,CLIENT_HEADER_LEN);
		}
		
		int r = 0;
		if(data && datalen>0){
			r = __kfifo_put(ff,(unsigned char*)data,datalen);
		}
		
		if(0 == input_context_.header_type_){
			InternalHeader &h = input_context_.header_;
			if(0 != (h.flag_ & HEADER_FLAG_ROUTE)){
				int ee = TAIL_JUMP_LEN*h.jumpnum_ <= TAIL_JUMP_MEM_LEN ? TAIL_JUMP_LEN*h.jumpnum_ : TAIL_JUMP_MEM_LEN;
				__kfifo_put(ff,(unsigned char*)input_context_.tail_mem_,ee);
			}
		}
		
		return r;
	}
	
	return -1;
}

int GXContext::pushTailJump(u32 local_link_index,const char *ID,kfifo *f)
{
	if(NULL == ID || NULL == f) return -1;
	
	TailJump aa;
	aa.local_index_ = local_link_index;
	strncpy(aa.portal_id_,ID,TAIL_ID_LEN);
	
	return __kfifo_put(f,(unsigned char*)&aa,TAIL_JUMP_LEN);
}

int GXContext::packetRouteToNode(const char* destID,int msgid,int datalen,void *data)
{
	datalen = datalen>0?datalen:0;
	if(NULL == destID){
		return -1;
	}
	
	int r = findPortal(0,destID);
	if(r >= 0){
		// �ڱ���������ֱ�Ӷ�λ���ˣ�����route�ˣ�PS����Ϊ��������������� 
		Link *l = getLink(r);
		if(l){
			kfifo *ff = &l->write_fifo_;
			
			if(0 == input_context_.header_type_){
				InternalHeader h;
				memcpy(&h,&input_context_.header_,sizeof(h));
				h.message_id_ = msgid;
				h.len_ = CLIENT_HEADER_LEN + datalen;
				h.flag_ = 0;
				
				__kfifo_put(ff,(unsigned char*)&h,INTERNAL_HEADER_LEN);
			}
			else{
				ClientHeader &h = input_context_.header2_;
				h.message_id_ = msgid;
				h.len_ = CLIENT_HEADER_LEN + datalen;
				
				__kfifo_put(ff,(unsigned char*)&h,CLIENT_HEADER_LEN);
			}
			
			if(data && datalen>0){
				return __kfifo_put(ff,(unsigned char*)data,datalen);
			}
			else{
				return 0;
			}
		}
		else{
			return -1;
		}
	}
	else{
		// ��λ������Ҫroute 
		if(0 != input_context_.header_type_){	// ��֧���Զ����ʽ����route 
			return -1;
		}
		
		Link *first_router = NULL;
		FOR(i,link_pool_size_){
			Link *ll = link_pool_+i;
			if(ll->isOnline() && 'R'==ll->link_id_[0]){
				first_router = ll;
				break;
			}
		}
		
		if(NULL == first_router){
			fprintf(stderr,"find NO router\n");
			return -1;
		}
		
				InternalHeader h;
				memcpy(&h,&input_context_.header_,sizeof(h));
				h.message_id_ = msgid;
				h.len_ = CLIENT_HEADER_LEN + datalen;
				h.flag_ = 0;
				h.flag_ |= HEADER_FLAG_ROUTE;
				h.jumpnum_ = 1;
				
				kfifo *ff = &first_router->write_fifo_;
				__kfifo_put(ff,(unsigned char*)&h,INTERNAL_HEADER_LEN);
				
				if(data && datalen>0){
					__kfifo_put(ff,(unsigned char*)data,datalen);
				}
				
				return pushTailJump(-1,destID,ff);
	}
	
	
	return -1;
}


void GXContext::forceCutLink(Link* ll)
{
	// ��֤���ָ���ȷ��һ���Ϸ���link ������Ұָ�� 
	if(link_pool_ <= ll && ll < link_pool_+link_pool_size_){
		ll->releaseSystemHandle(this);
		releaseLink(ll);
	}
}

#ifdef __USING_WINDOWS_IOCP
DWORD WINAPI __AcceptThreadProc(void* lpParam)
{
	GXContext *nc = (GXContext*)lpParam;
	int listen_sock = nc->listening_socket_;
	printf("running IOCP. accept thread ready to run.\n");
	
	
	while(true){	// this should be endless
		struct sockaddr_storage ss;
    	int socklen = sizeof(ss);
    
		int new_fd = accept(listen_sock,(struct sockaddr *)&ss,&socklen);
		if(new_fd==-1){
			continue;
		}
		nc_set_no_delay(new_fd);
	    nc_set_nonblock(new_fd);
	    nc_setsockopt_client(new_fd);
	    
	    
	    Link *new_ioable = nc->newLink();
	    if(0 == new_ioable){
	    	printf("IOAble pool is full\n");
	    	closesocket(new_fd);
	    	continue;
	    }
	    
	    new_ioable->sock_ = new_fd;
	    
	    HANDLE new_hd = CreateIoCompletionPort((HANDLE)new_fd, nc->iocp_handle_, (DWORD)new_ioable , 1);
	    if(NULL == new_hd){
	    	fprintf(stderr,"CreateIoCompletionPort return NULL after accept(). fd[%d]\n",new_fd);
	    	// free resource
	    	nc->releaseLink(new_ioable);
	    	closesocket(new_fd);
	    	continue;
	    }
	    
	    //printf("accepted new con. pool index[%d]\n",new_ioable->pool_index_);
	    new_ioable->enable_encrypt_ = nc->enable_encrypt_;
	    new_ioable->becomeOnline(nc->read_buf_len_,nc->write_fifo_len_);
	    
	    //Post initial Recv
	    //This is a right place to post a initial Recv
	    //Posting a initial Recv in WorkerThread will create scalability issues.
	    if(new_ioable->post_recv() != 0){
	    	fprintf(stderr,"first recv after accept failed.\n");
	    }
    
	}
	
	printf("accept thread ended.  This should NOT happen\n");
	fprintf(stderr,"accept thread ended.  This should NOT happen\n");
	
	return -1;
}
#endif


bool GXContext::start_listening()
{
	int gate_sock = ::socket(PF_INET,SOCK_STREAM,0);
    nc_set_reuse_addr(gate_sock);
	//nc_set_nonblock(gate_sock);
	char *delimiter = strstr(ip_and_port_,":");
	if(0==delimiter) return false;
	
    int port = atoi(delimiter+1);
    if(nc_bind(gate_sock,port)!=0){
        fprintf(stderr,"listening socket initialize error. port:[%u]\n",port);
        return false;
    }
    if(::listen(gate_sock,10)!=0){
        fprintf(stderr,"listening socket initialize error. port:[%u]\n",port);
        return false;
    }
    
    listening_socket_ = gate_sock;
	
#ifdef __USING_WINDOWS_IOCP
	// ���� accept() ����IOCP֧�֣���һ���������߳�ר������ accept 
	DWORD threadID = 0;
	HANDLE thread_hd = ::CreateThread(0, 0, __AcceptThreadProc, (void*)this , 0, &threadID);
	if(NULL == thread_hd){
		fprintf(stderr,"CreateThread failed\n");
		return false;
	}
#else
	nc_set_nonblock(gate_sock);
	
	Link *listen_link = newLink();
	listen_link->sock_ = gate_sock;
	int r = listen_link->register_read_event(this);
	if(-1 == r){
		printf("listening socket epoll failed.\n");
		return false;
	}
	
	bindLinkWithGlobalID("listen0",listen_link);
	
#endif
	return true;
}


bool GXContext::connect2(char *global_id,char *ip_and_port)
{
/*
	if(0 == ip_and_port) return false;
	
	
	
	char buf2[256];
	strncpy(buf2,ip_and_port,255);
	
	char *delimiter = strstr(buf2,":");
	if(0 == delimiter) return false;
	
	int port = atoi(delimiter+1);
	delimiter[0] = 0;
	
	
	int sock = ::socket(PF_INET,SOCK_STREAM,0);
    nc_setsockopt_client(sock);
    nc_set_no_delay(sock);
    
    
    if(nc_connect(sock,buf2,port)!=0){
    	printf("connect to peer failed.\n");
    	return false;
    }
    
	nc_set_nonblock(sock);
	
	link *ll = newLink();
	if(0 == ll || ll->isOnline()){
		return false;
	}
	
	
	ll->sock_ = sock;
	
	
#ifdef __USING_WINDOWS_IOCP
	HANDLE new_hd = CreateIoCompletionPort((HANDLE)sock, iocp_handle_, (DWORD)ll , 1);
	if(NULL == new_hd){
	    fprintf(stderr,"CreateIoCompletionPort return NULL after accept(). fd[%d]\n",sock);
	    // free resource
	    releaseLink(ll);
	    closesocket(sock);
	    return false;
	}
	
	ll->becomeOnline(read_buf_len_,write_fifo_len_);
	
	ll->post_recv();
#else
	ll->register_read_event(this);
#endif
*/
	int link_index = connect2_no_care_id(ip_and_port);
	if(link_index < 0) return false;
	
	Link *ll = getLink(link_index);
	if(NULL == ll) return false;
	
	bindLinkWithGlobalID(global_id,ll);

	{
		// Auth
		// I_SayHi
	}
	
	return true;
}

int GXContext::connect2_no_care_id(char *ip_and_port)
{
	if(0 == ip_and_port) return -1;
	
	
	
	char buf2[256];
	strncpy(buf2,ip_and_port,255);
	
	char *delimiter = strstr(buf2,":");
	if(0 == delimiter) return -1;
	
	int port = atoi(delimiter+1);
	delimiter[0] = 0;
	
	
	int sock = ::socket(PF_INET,SOCK_STREAM,0);
    nc_setsockopt_client(sock);
    nc_set_no_delay(sock);
    
    
    if(nc_connect(sock,buf2,port)!=0){
    	printf("connect to peer failed.\n");
    	return -1;
    }
    
	nc_set_nonblock(sock);
	
	Link *ll = newLink();
	if(0 == ll || ll->isOnline()){
		return -1;
	}
	
	
	ll->sock_ = sock;
	
	
#ifdef __USING_WINDOWS_IOCP
	HANDLE new_hd = CreateIoCompletionPort((HANDLE)sock, iocp_handle_, (DWORD)ll , 1);
	if(NULL == new_hd){
	    fprintf(stderr,"CreateIoCompletionPort return NULL after accept(). fd[%d]\n",sock);
	    // free resource
	    releaseLink(ll);
	    closesocket(sock);
	    return -1;
	}
	
	ll->becomeOnline(read_buf_len_,write_fifo_len_);
	
	ll->post_recv();
#else
	ll->register_read_event(this);
	
	ll->becomeOnline(read_buf_len_,write_fifo_len_);
#endif

	return ll->pool_index_;
}

#define CLIENT_MSG_MAX_LEN (1024*7)

int GXContext::try_deal_one_msg_s(Link *ioable,int &begin)
{
	if(0==ioable) return -1;
	
	int end = ioable->read_buf_offset_;
	
	if(0 == header_type_){
		if((end-begin)>=INTERNAL_HEADER_LEN){
			InternalHeader *hh = (InternalHeader*)(ioable->read_buf_+begin);
			if(hh->len_<CLIENT_HEADER_LEN){
				// ������ڲ����ӣ���̧����
				begin = ioable->read_buf_offset_;
				return -1;
			}
			
			if(0 == (hh->flag_ & HEADER_FLAG_ROUTE)){
				int full_len = hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN);
				if(full_len<=(end-begin)){
					if(callback_){
						// ׼����������
						input_context_.reset();
						
						input_context_.gxc_ = this;
						input_context_.src_link_pool_index_ = ioable->pool_index_;
						input_context_.header_type_ = header_type_;
						memcpy(&input_context_.header_,hh,INTERNAL_HEADER_LEN);
						
						rs_ = rs_bak_;
						ws_ = ws_bak_;
						ws_->cleanup();
						rs_->reset(full_len-INTERNAL_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
						
						int r = ((GXContextMessageDispatch)callback_)(this,ioable,hh,full_len-INTERNAL_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
					}
					
					begin += full_len;
					return 1;
				}
			}
			else{	// ��route�� 
				int full_len = hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN) + TAIL_JUMP_LEN*hh->jumpnum_;
				if(full_len<=(end-begin)){
					if(0 != (hh->flag_ & HEADER_FLAG_BACK)){
						// �ǻذ� 
						if(hh->jumpnum_ > 1){
							// ��δ����Ŀ�ĵ� 
							-- hh->jumpnum_;
							TailJump *jj = (TailJump*)(ioable->read_buf_+begin+hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN));
							jj += hh->jumpnum_;
							
							int r = sendToPortal(jj->local_index_,jj->portal_id_,full_len-TAIL_JUMP_LEN,ioable->read_buf_+begin);
							if(-1 == r){
								r = sendToPortal(jj->portal_id_,full_len-TAIL_JUMP_LEN,ioable->read_buf_+begin);
							}
							if(r != full_len-TAIL_JUMP_LEN){
								fprintf(stderr,"auto back send failed. request [%d] sent [%d]\n",full_len-TAIL_JUMP_LEN,r);
								// TODO: �Ƿ���Ҫ�и��ദ���ȷ�����һ����ʾû���ʹ�Ļذ� 
							}
						}
						else{
							// �������Ŀ�ĵ� 
							// ========================================================================================
							if(callback_){
								// ׼����������
								input_context_.reset();
								
								input_context_.gxc_ = this;
								input_context_.src_link_pool_index_ = ioable->pool_index_;
								input_context_.header_type_ = header_type_;
								memcpy(&input_context_.header_,hh,INTERNAL_HEADER_LEN);
								input_context_.header_.flag_ = 0;	// ��Ҫ���Ѿ������һ�����أ������� 
								input_context_.header_.jumpnum_ = 0;
								
								rs_ = rs_bak_;
								ws_ = ws_bak_;
								ws_->cleanup();
								rs_->reset(hh->len_-CLIENT_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
								
								int r = ((GXContextMessageDispatch)callback_)(this,ioable,hh,hh->len_-CLIENT_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
							}
							// ========================================================================================
						}
					}
					else{
						// ��ȥ�� 
						TailJump *jj = (TailJump*)(ioable->read_buf_+begin+hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN));
						
						if(0 == strncmp(jj->portal_id_,this->gx_id_,TAIL_ID_LEN)){
							// it's me
							// ========================================================================================
							if(callback_){
								// ׼����������
								input_context_.reset();
								
								input_context_.gxc_ = this;
								input_context_.src_link_pool_index_ = ioable->pool_index_;
								input_context_.header_type_ = header_type_;
								memcpy(&input_context_.header_,hh,INTERNAL_HEADER_LEN);
								
								int ee = TAIL_JUMP_LEN*hh->jumpnum_ <= TAIL_JUMP_MEM_LEN ? TAIL_JUMP_LEN*hh->jumpnum_ : TAIL_JUMP_MEM_LEN;
								memcpy(input_context_.tail_mem_,jj,ee);
								rs_ = rs_bak_;
								ws_ = ws_bak_;
								ws_->cleanup();
								rs_->reset(hh->len_-CLIENT_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
								
								int r = ((GXContextMessageDispatch)callback_)(this,ioable,hh,hh->len_-CLIENT_HEADER_LEN,ioable->read_buf_+begin+INTERNAL_HEADER_LEN);
							}
							// ========================================================================================
						}
						else{
							// find destiny
							int r = findPortal(0,jj->portal_id_);
							if(r >= 0){
								Link *ll = getLink(r);
								if(ll){
									++ hh->jumpnum_;
									int r2 = __kfifo_put(&ll->write_fifo_,(unsigned char*)hh,full_len);
									if(r2 == full_len){
										pushTailJump(ioable->pool_index_,ioable->link_id_,&ll->write_fifo_);
									}
								}
								else{
									begin += full_len;
									return -1;
								}
							}
							else{
								// continue route
								// �����2��ѭ���� �ڱ����������ҳ�һ��û�С������� ����router 
								Link *next_router = NULL;
								FOR(i,link_pool_size_){
									Link *ll = link_pool_+i;
									if(ll->isOnline() && 'R'==ll->link_id_[0]){
										bool found = false;
										for(int rev=hh->jumpnum_-1;rev>=0;--rev){
											TailJump *aa = jj+rev;
											if(0 == strncmp(ll->link_id_,aa->portal_id_,TAIL_ID_LEN)){
												found = true;
												break;
											}
										}
										
										if(!found){
											next_router = ll;
											break;
										}
									}
								}
								
								if(next_router){
									++ hh->jumpnum_;
									int r2 = __kfifo_put(&next_router->write_fifo_,(unsigned char*)hh,full_len);
									if(r2 == full_len){
										pushTailJump(ioable->pool_index_,ioable->link_id_,&next_router->write_fifo_);
									}
								}
								else{
									fprintf(stderr,"NO more router\n");
									begin += full_len;
									return -1;
								}
							}
						}
					}
					
					
					begin += full_len;
					return 1;
				}
			}
		}
	}
	else if(1 == header_type_){
		if((end-begin) >= CLIENT_HEADER_LEN){
			ClientHeader *hh = (ClientHeader*)(ioable->read_buf_+begin);
			if(hh->len_<CLIENT_HEADER_LEN || hh->len_>CLIENT_MSG_MAX_LEN){
				return -4;
			}
			
			int full_len = hh->len_;
		#ifdef ENABLE_ENCRYPT
			#define ENCRYPT_OFFSET 2
			#define ENCRYPT_KEY_LEN 128
			#define ENCRYPT_ECB_BLOCK 16
			#define E_BUF_LEN 256
			#define E_BUF_OUTPUT_OFFSET 128
			
			int encrypt_len = full_len - ENCRYPT_OFFSET;
			
			if(ioable->enable_encrypt_){
				// ���뵽�����16������ 
				int dd = encrypt_len / ENCRYPT_ECB_BLOCK;
				if(dd*ENCRYPT_ECB_BLOCK != encrypt_len){
					encrypt_len = (dd+1)*ENCRYPT_ECB_BLOCK;
				}
				else{
					encrypt_len = (dd+1)*ENCRYPT_ECB_BLOCK;		// ����Ҫ��16���ֽ� �� 
				}
			}
			//printf("full_len[%d]  encrypt_len[%d]\n",full_len,encrypt_len);
			if(encrypt_len+ENCRYPT_OFFSET<=(end-begin)){
		#else
			if(full_len<=(end-begin)){
		#endif
			
			#ifdef ENABLE_ENCRYPT
				if(ioable->enable_encrypt_){
					static char *e_buf = NULL;
					if(NULL == e_buf){
						e_buf = (char*)	malloc(E_BUF_LEN);
					}
					
					int plain_len = full_len - ENCRYPT_OFFSET;
					char *e_begin = ioable->read_buf_+begin+ENCRYPT_OFFSET;
					int encrypt_len_bak = encrypt_len;
					while(encrypt_len > 0){
						int len2 = encrypt_len>=ENCRYPT_ECB_BLOCK ? ENCRYPT_ECB_BLOCK : encrypt_len;
						memcpy(e_buf,e_begin,len2);
						int e_r = aes_crypt_ecb(&ioable->aes_c_dec_,AES_DECRYPT,e_buf,e_buf+E_BUF_OUTPUT_OFFSET);
						// �ѽ��ܺ���������ȥ
						memcpy(e_begin,e_buf+E_BUF_OUTPUT_OFFSET,len2);
						
						encrypt_len -= ENCRYPT_ECB_BLOCK;
						plain_len -= ENCRYPT_ECB_BLOCK;
						e_begin += ENCRYPT_ECB_BLOCK;
						
						if(0 != e_r){
							fprintf(stderr,"DECRYPT error\n");
						}
					}
					encrypt_len = encrypt_len_bak;
				}
			#endif
				int r = 0;
				if(callback_){
					// ׼����������
					input_context_.reset();
					
					input_context_.gxc_ = this;
					input_context_.src_link_pool_index_ = ioable->pool_index_;
					input_context_.header_type_ = header_type_;
					input_context_.header2_ = *hh;
					//memcpy(&input_context_.header2_,hh,CLIENT_HEADER_LEN);
					
					rs_ = rs_bak_;
					ws_ = ws_bak_;
					ws_->cleanup();
					rs_->reset(full_len-CLIENT_HEADER_LEN,ioable->read_buf_+begin+CLIENT_HEADER_LEN);
					
					r = ((GXContextMessageDispatch2)callback_)(this,ioable,hh,full_len-CLIENT_HEADER_LEN,ioable->read_buf_+begin+CLIENT_HEADER_LEN);
				}
				
				if(-999 == r){
					full_len = hh->len_+(INTERNAL_HEADER_LEN-CLIENT_HEADER_LEN);
					begin += full_len;
				}
				else{
				#ifdef ENABLE_ENCRYPT
					if(ioable->enable_encrypt_){
						begin += encrypt_len+ENCRYPT_OFFSET;
					}
					else{
						begin += full_len;
					}
				#else
					begin += full_len;
				#endif
				}
				return 1;
			}
		}
	}
	
	return -1;
}


/*
 ʹ��IOCP��Ҫע���һЩ����

1- ��ҪΪÿ��С���ݰ�����һ��IOCP����,���������׺ľ�IOCP���ڲ�����.....�Ӷ�����10055����.

2- ��Ҫ��ͼ�ڷ��ͳ�IOCP����֮��,�յ����֪֮ͨǰ�޸�������ʹ�õ����ݻ��������,��Ϊ�����ʱ��,ϵͳ���ܻ�����ȡ��Щ����.
 
3- Ϊ�˱����ڴ濽��,���Գ��Թر�SOCKET�ķ��ͺͽ��ջ�����,����������,����Ҫ����Ľ�������POST��һ�����������Ƚϴ��SOCKET,�Ӷ���֤ϵͳһֱ�����ҵ�BUFFER����ȡ����������.

4- �ڷ���������������ʱ��,������WORKTHREAD��ֹһ��,һ��Ҫʹ��һЩ�ֶ�����֤������ɵ����ݰ��շ��ͽ��������˳����,����,����������ݰ��û��ҵ�˳����������Ĵ��������.....

5- ˵�����߳�, ���Ҫ����MS�Ľ���, �� CPU����*2+2 ��, ����㲻�˽�IOCP�Ĺ���ԭ��Ļ�.

6- IOCP�Ĺ����߳���ϵͳ�Ż��͵��ȵ�, �Լ��Ͳ���Ҫ���ж���Ĺ�����.��������������ǻۺ;��鳬��MS�Ĺ���ʦ, ���㻹��ҪIOCPô....

7-����һ��Send����֮�󣬾Ͳ���Ҫ��ȥ����Ƿ�����������Ϊiocp�������������飬��Щ��˵iocpû����������飬���iocp�ĸ�Ч������㣵ģ������������������β��Ա�����IocpҪô�Ͽ����ӣ�Ҫô�Ͱ����ÿ���������󶼷���������

8- �������ݴ��ҵ�ʱ�򣬲�Ҫ�ţ�Ҫ�Ӷ��̵߳ĽǶȼ����Ľ����ͷ������ݰ��Ĵ��룬�����ǲ�����˳���ϵ����⡣

9- ��������ֵ��ڴ�����ʱ���𽥵ļ��ٹ����̵߳����������԰��������������ⷢ����Ǳ��λ�á�

10-ͬ���������ڴ�����ʱ������ȥ�����Ŀͻ����ڷ��������ڲ�ӳ�������ͷ��Ƿ������⡣����ҪС�ĵı�дiocp���ʧ�ܵĴ�����룬��ֹ����һ��������ڲ�ӳ�����ĵ�ַ��

11- overlapped����һ��Ҫ�����ڳ־õ�λ�ã����Ҳ���������ɣ����ܳɹ�����ʧ�ܣ���Ҫ�ͷţ�������ܻ�����������ֵ����⡣

12- IOCP�����й��������ڻ�ȡ���״̬���Ǹ������ڲ����е��Ⱥ���ɵģ����Գ���ע�⹤���̵߳�����֮�⣬��Ҫע�⣬���������㹻��Ĺ����̴߳��ڻ�ȡ���״̬���Ǹ��ȴ����棬����������Ҫ���ٹ����̵߳ĸ�����ȷ�������߳��ڲ�Ҫ�����ʱ�Ĺ��������ҵĽ����ǹ����̺߳��߼��̳߳������ֿ���

14- ��������send��recv�Ļ���Ĵ�С��ϵͳҳ���С�ı�������Ϊϵͳ���ͻ��߽������ݵ�ʱ�򣬻����û��ڴ�ģ���ҳ��С�Ļ�����˷ѵ�����һ��ҳ�档����Ϊ��һ���Ĳ��䣬�����С���ϲ��ɴ�����ͣ�
*/


#define __TIMEOUT_ERROR 10000


void GXContext::frame_poll(timetype now,int block_time)
{
	if(0 == stat_) return;
	
#ifdef __USING_WINDOWS_IOCP
		
	FOR(counter_iocp,link_pool_size_){	// Ϊ�˰�ȫ����һ���������  
		DWORD bytesTransfered = 0;
        OVERLAPPED* overlapped = NULL;
        ULONG_PTR completionKey = NULL;

		int ret = GetQueuedCompletionStatus(iocp_handle_, &bytesTransfered, &completionKey, &overlapped, block_time);
		int err = 0;
		if(0 == ret){
			if(0==overlapped){
				// it's just time out
				err = __TIMEOUT_ERROR;
			}
			else{
				// ��graceful�ĶϿ�
				printf("��graceful�ĶϿ�\n"); 
				err = 2;
			}
		}
		else if(0 == bytesTransfered){
			printf("graceful�ĶϿ�\n"); 
			err = 1;
		}
		else if(completionKey == NULL || overlapped == NULL) {
			printf("��graceful�ĶϿ�2\n"); 
			err = 2;
		}
		
		/*
		 �������ӶϿ�ʱ���յ���֪ͨ�����iocp��⵽Socket�����Ѿ��Ͽ����������ϻ��յõ�֪ͨ��������ʱ����յ�����һ��֪ͨ��
		 ��ȡ�������ڸ�socket��Ͷ��WSASend��WSARecv�Ĵ�������������һ��socket��Ͷ����һ��WSASend��һ��WSARecv��
		 ��������Ͷ�ݻ�û�б����ʱ�����socket�Ͽ������ӣ���ôGetQueuedCompletionStatus()�����յ�����֪ͨ
		*/
		
		// TODO: 1��Ҫ�������ͷ���Դ��ѹ��  2��Ҫ�������Ͽ�  3���ո�����ʱ��֪����client����internal 
		
		if(0 == err){
			Link *ioable = (Link*)completionKey;
			int real_read = bytesTransfered;
			ioable->read_buf_offset_ += real_read;
			// test
			//printf("get [%d]  [%s]\n",real_read,ioable->read_buf_);
					
			if(true){
				// �Ƿ�����ڲ�����������������Ӧ���� InternalHeader ��ͷ 
				int byte_begin = 0;
				FOR(limiter,9999){
					int suc = try_deal_one_msg_s(ioable,byte_begin);
					if(1 != suc){
						if(-4==suc){
							err = -1;
							printf("-4==suc\n");
						}
						break;
					}
				}
				if(byte_begin == ioable->read_buf_offset_){
					ioable->read_buf_offset_ = 0;
				}
				else if(ioable->read_buf_offset_ > byte_begin){
					memmove(ioable->read_buf_,ioable->read_buf_+byte_begin,ioable->read_buf_offset_-byte_begin);
					ioable->read_buf_offset_ = ioable->read_buf_offset_-byte_begin;
				}
				else{
					// unlegal
					ioable->read_buf_offset_ = 0;
				}
			}
			
			// ����Ͷ�� 
			if(0 == err){
				int rr = ioable->post_recv();
				if(rr != 0){
					err = 2;
				}	
			}
		}
		
		// If it's timeout, we dont need post_recv again
		
		
		if(err!=0 && err!=__TIMEOUT_ERROR){
			// ���ټ���Ͷ�� 
			
					
			// ���Ͽ����� 
			if(completionKey){
				Link *ioable = (Link*)completionKey;
				printf("���Ͽ�����   [%d]\n",ioable->pool_index_);
				if(link_cut_callback_){
					link_cut_callback_(this,ioable,1,type_);
				}
				ioable->link_stat_ = 0;
				ioable->releaseSystemHandle(this);
				releaseLink(ioable);
		
			}
		}
		
		if(__TIMEOUT_ERROR==err){
			// IOCP��ʱ���أ�Ӧ��û�и�������Ҫ���� 
			return;
		}
	}
#else

#define likely(x) __builtin_expect((x),1)
#define unlikely(x) __builtin_expect((x),0)
	{
		int epoll_err = -1;
		static int s_prev_event_buffer_byte_len = 0;
		static void *s_event_buffer = NULL;
		
		int event_buffer_byte_len = sizeof(struct epoll_event)*(link_pool_size_+4);
		if(unlikely(event_buffer_byte_len != s_prev_event_buffer_byte_len)){
			s_event_buffer = realloc(s_event_buffer,event_buffer_byte_len);
			s_prev_event_buffer_byte_len = event_buffer_byte_len;
			
			if(0==s_event_buffer){
				exit(-1);
			}
		}
		
		void *event_buffer = s_event_buffer;
	
		memset(event_buffer,0,event_buffer_byte_len);
		int n = epoll_wait(this->epoll_fd_ , (struct epoll_event*)event_buffer, link_pool_size_, block_time);
		if(unlikely(-1 == n)){
			epoll_err = 1;
			printf("EPOLL error [%d]\n",errno);
		}
		else if(0==n){
			epoll_err = __TIMEOUT_ERROR;
		}
		else if(n>0){
			epoll_err = 0;
		}
		
		if(likely(0 == epoll_err)){
			FOR(ev_index,n){
				struct epoll_event* ev = ((struct epoll_event*)event_buffer)+ev_index;
				Link *ioable = (Link*)ev->data.ptr;
				
				if(unlikely(ioable->sock_ == listening_socket_)){
					// �Ǽ���socket
					struct sockaddr_storage ss;
    				int socklen = sizeof(ss);
					FOR(i,10){
						int new_fd = ::accept(ioable->sock_,(struct sockaddr *)&ss,(socklen_t*)&socklen);
						if(-1 == new_fd){
							break;
						}
						
						nc_set_no_delay(new_fd);
					    nc_set_nonblock(new_fd);
					    nc_setsockopt_server(new_fd);
						
						Link *aa = newLink();
						if(aa){
							aa->sock_ = new_fd;
							int r = aa->register_read_event(this);
							if(-1 == r){
								printf("register_read_event failed.\n");
								aa->releaseSystemHandle(this);
								releaseLink(aa);
							}
							
							aa->enable_encrypt_ = this->enable_encrypt_;
							aa->becomeOnline(read_buf_len_,write_fifo_len_);
						}
						else{
							closesocket(new_fd);
							printf("pool is full.\n");
						}
					}
					
					
					continue; 
				}
				
				int err = 1;
				int real_read = 0;
				int ok = nc_read(ioable->sock_,ioable->read_buf_+ioable->read_buf_offset_,ioable->read_buf_len_-ioable->read_buf_offset_,real_read);
				if(unlikely(ok != 1)){
					err = 1;
				}
				else{
					err = 0;
					ioable->read_buf_offset_ += real_read;
				}
				bool need_kick = false;
				
				if(likely(0==err)){
					if(true){
						// �Ƿ�����ڲ�����������������Ӧ���� InternalHeader ��ͷ 
						int byte_begin = 0;
						FOR(limiter,9999){
							int suc = try_deal_one_msg_s(ioable,byte_begin);
							if(unlikely(1 != suc)){
								if(-4==suc){
									need_kick = true;
								}
								break;
							}
						}
						if(byte_begin == ioable->read_buf_offset_){
							ioable->read_buf_offset_ = 0;
						}
						else if(ioable->read_buf_offset_ > byte_begin){
							memmove(ioable->read_buf_,ioable->read_buf_+byte_begin,ioable->read_buf_offset_-byte_begin);
							ioable->read_buf_offset_ = ioable->read_buf_offset_-byte_begin;
						}
						else{
							// unlegal
							ioable->read_buf_offset_ = 0;
						}
					}
					
				}
				else{
					need_kick = true;
				}
				
				
				if(need_kick){
					// ���Ͽ����� 
					{
						printf("���Ͽ�����   [%d]\n",ioable->pool_index_);
						
						if(link_cut_callback_){
							link_cut_callback_(this,ioable,1,type_);
						}
						ioable->link_stat_ = 0;
						ioable->releaseSystemHandle(this);
						releaseLink(ioable);
		
					}
				}
			}
		}
	}
#endif
}


//�Կͻ������ӣ�Ӧ������ÿ֡д��ȥ���ֽ�
//�������ֵӦ�ô���ϵͳ����ȽϺã����������ǵ�ubuntuϵͳ�ϣ�ϵͳ��socket����д��������޶���163840 byte
//���cat /proc/sys/net/core/rmem_max
// cat /proc/sys/net/core/wmem_max
// �ʰ����ֵ��Ϊ163840
#define MAX_BYTES_PER_FRAME 163840

int GXContext::frame_flush(timetype now)
{
	if(0 == stat_) return -1;
	
	int counter = 0;
	FOR(i,link_pool_size_){
		Link *aa = link_pool_+i;
		if(aa->isOnline()){
			struct kfifo *ff = &aa->write_fifo_;
			if(ff->in != ff->out){
				if(1 == header_type_){
					int sent = __kfifo_2_net(ff,aa->sock_,MAX_BYTES_PER_FRAME);
					//printf("flushed index[%d] [%d] bytes\n",i,sent);
				}
				else{
					__kfifo_2_net(ff,aa->sock_,1024*1024);
					//printf("flushed index[%d]\n",i);
				}
				++counter;
			}
		}
	}
	return counter;
}




