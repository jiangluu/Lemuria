#include "link.h"
#include "GXContext.h"


#ifndef __USING_WINDOWS_IOCP
int Link::register_read_event(GXContext *nc){
	ev_.events = EPOLLIN;
	ev_.data.ptr = this;
	int r = epoll_ctl(nc->epoll_fd_, EPOLL_CTL_ADD, sock_, &ev_);
	return r;
}

int Link::register_readwrite_event(GXContext *nc){
	ev_.events = EPOLLIN | EPOLLOUT;
	ev_.data.ptr = this;
	int r = epoll_ctl(nc->epoll_fd_, EPOLL_CTL_ADD, sock_, &ev_);
	return r;
}

int Link::unregister_event(GXContext *nc){
	int r = epoll_ctl(nc->epoll_fd_, EPOLL_CTL_DEL, sock_ , &ev_);
	return r;
}
#endif


void Link::releaseSystemHandle(GXContext *nc){
#ifdef __USING_WINDOWS_IOCP
	CancelIo((HANDLE)sock_);
	//shutdown((HANDLE)sock_, SD_BOTH );
#else
	epoll_ctl(nc->epoll_fd_, EPOLL_CTL_DEL, sock_ , &ev_);
#endif
	closesocket(sock_);
	sock_ = -1;
}


