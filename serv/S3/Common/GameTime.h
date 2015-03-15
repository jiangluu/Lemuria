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


typedef u32 timetype;	// ��Ϸʱ�������ݶ�Ϊ32λ���������ֻ�ܳż�ʮ��ͻ����ꡣ��Ҫʱ���� timetypeΪu64���� 


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

    //��ǰʱ�����ֵ����Ϸ���ʱ�䶼Ӧ�������������ע�����ʵʱ�䲢����ͬ
    //���ص�ֵΪ��ǧ��֮һ�뵥λ��ʱ��ֵ
    timetype        currentTime(){ return m_CurrentTime ; }
    
    timetype		localTime(){ return m_LocalTime; }
    
    u64				localUsecTime(){ return m_local_usec_time; }
    
    //����ǰ��ϵͳʱ���ʽ����ʱ���������
    //�������ÿһ֡�����ˣ��߼����벻Ӧ���ٵ��� 
    void            setTime(){	    
	    struct timespec ss;
	    // ������ǰ��Ծ��ʱ�� 
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
    
    // ��  active_mode==0ʱ�������ⲿ������ʱ��ģ�localʱ�仹���Լ����£� 
    void setValue(timetype cur_time,timetype ansi_time,u64 frame){
    	if(0==m_active_mode){
    		m_CurrentTime = cur_time;
    		m_SetTime = ansi_time;
    		m_frame_no = frame;
    	}
    }

    //ȡ�÷������˳�������ʱ��ʱ�����ֵ
    u64        		getStartTime(){ return (timetype)m_local_usec_start_time ; }

    

    // �õ���ʵʱ�䣨��׼ʱ����
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

