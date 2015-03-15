#ifndef __GAME_TIME_H
#define __GAME_TIME_H


/*
#ifndef WIN32
	#include <sys/utsname.h>
	#include <sys/time.h>
#else
	#include <sys/types.h>
	#include <sys/timeb.h>
#endif
*/
// use this linux api for we use mingw
#include <time.h>
#include <sys/time.h>
#include "types.h"


#ifdef WIN32
	#define GX_CLOCK_MONOTONIC CLOCK_MONOTONIC
	#define GX_CLOCK_REALTIME CLOCK_REALTIME
#else
	#define GX_CLOCK_MONOTONIC CLOCK_MONOTONIC_COARSE
	#define GX_CLOCK_REALTIME CLOCK_REALTIME_COARSE
#endif


typedef u32 timetype;	// 游戏时间类型暂定为32位。但是这个只能撑几十天就会走完。需要时定义 timetype为u64即可 


struct GameTime
{
    GameTime() { init(); }
    

    void            init(int active_mode = 1){
    	/*
		#ifdef WIN64
		struct __timeb64 timebuffer;
		_ftime64(&timebuffer);
		m_StartTime = timebuffer.time*1000 + timebuffer.millitm;
		#endif
		
		#ifdef WIN32
		struct __timeb32 timebuffer;
		_ftime32(&timebuffer);
		m_StartTime = timebuffer.time*1000 + timebuffer.millitm;
		#endif
		
		    
		#ifdef __LINUX__
		struct timeval aa;
		gettimeofday(&aa,0);
		m_StartTime = aa.tv_sec*1000L+aa.tv_usec/1000;
		#endif
		*/
		m_active_mode = active_mode;
		m_SetTime = 0;
		m_LocalSetTime = 0;
		m_LocalTime = 0;
		m_CurrentTime = 0;
		m_frame_no = 0;
		m_local_frame_no = 0;
		
		struct timespec ss;
		int r2 = clock_gettime(GX_CLOCK_MONOTONIC,&ss);
		m_local_usec_start_time = ((u64)ss.tv_sec)*1000000L + ss.tv_nsec/1000;
		m_local_usec_time = 0;
		
		setTime();
    }

    //当前时间计数值，游戏里得时间都应该用这个函数。注意跟现实时间并不等同
    //返回的值为：千分之一秒单位的时间值
    timetype        currentTime(){ return m_CurrentTime ; }
    
    timetype		localTime(){ return m_LocalTime; }
    
    u64				localUsecTime(){ return m_local_usec_time; }
    
    //将当前的系统时间格式化到时间管理器里
    //框架里在每一帧调用了，逻辑代码不应该再调用 
    void            setTime(){	    
	    struct timespec ss;
	    // 不会向前跳跃的时间 
	    int r2 = clock_gettime(GX_CLOCK_MONOTONIC,&ss);
	    m_local_usec_time = ((u64)ss.tv_sec)*1000000L + ss.tv_nsec/1000 - m_local_usec_start_time;
	    m_LocalTime = timetype(m_local_usec_time / 1000);
	    
	    // wall-clock
	    r2 = clock_gettime(GX_CLOCK_REALTIME,&ss);
	    m_LocalSetTime = ss.tv_sec;
	    
	    if(0!=m_active_mode){
	    	m_CurrentTime = m_LocalTime;
	    	m_SetTime = m_LocalSetTime;
	    }
    }
    
    bool isActiveMode(){ return 0!=m_active_mode; }
    
    // 在  active_mode==0时，依赖外部来更新时间的（local时间还是自己更新） 
    void setValue(timetype cur_time,timetype ansi_time,u64 frame){
    	if(0==m_active_mode){
    		m_CurrentTime = cur_time;
    		m_SetTime = ansi_time;
    		m_frame_no = frame;
    	}
    }

    //取得服务器端程序启动时的时间计数值
    u64        		getStartTime(){ return (timetype)m_local_usec_start_time ; }

    

    // 得到现实时间（标准时区）
    timetype        getANSITime(){ return (timetype)m_SetTime; }
    
    u64				getFrame(){ return m_frame_no; }
    u64				getLocalFrame(){ return m_local_frame_no; }
    void			incLocalFrame(){ ++m_local_frame_no; }

private:
	int			m_active_mode;
	timetype     m_LocalTime ;
    timetype     m_CurrentTime ;
    time_t       m_SetTime ;
    time_t       m_LocalSetTime ;
	u64			m_frame_no;
	u64			m_local_frame_no;
	u64			m_local_usec_time;
	u64			m_local_usec_start_time;
};



#endif

