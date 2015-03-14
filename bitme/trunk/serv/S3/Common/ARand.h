#ifndef __ARAND_H
#define __ARAND_H


//随机数生成器，采用LCG算法
//相比C库提供的rand()函数，好处在于：1）速度快 2）参数可控
class ARand{
public:
    ARand(u32 seed){ v_ = seed; }
    u32 rand32(){ v_ = (v_*1103515245+12345) % 4294967296; return (u32)v_; }
private:
    u64 v_;
};


#endif
