#include "link.h"
#include "frontend.h"


#ifndef __USING_WINDOWS_IOCP
int Link::register_read_event(FrontEnd *nc){
	ev_.events = EPOLLIN;
	ev_.data.ptr = this;
	int r = epoll_ctl(nc->epoll_fd_, EPOLL_CTL_ADD, sock_, &ev_);
	return r;
}
#endif


void Link::releaseSystemHandle(FrontEnd *nc){
#ifdef __USING_WINDOWS_IOCP
	CancelIo((HANDLE)sock_);
	//shutdown((HANDLE)sock_, SD_BOTH );
#else
	epoll_ctl(nc->epoll_fd_, EPOLL_CTL_DEL, sock_ , &ev_);
#endif
	closesocket(sock_);
	sock_ = -1;
}


