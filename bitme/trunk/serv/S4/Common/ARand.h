#ifndef __ARAND_H
#define __ARAND_H


//�����������������LCG�㷨
//���C���ṩ��rand()�������ô����ڣ�1���ٶȿ� 2�������ɿ�
class ARand{
public:
    ARand(u32 seed){ v_ = seed; }
    u32 rand32(){ v_ = (v_*1103515245+12345) % 4294967296; return (u32)v_; }
private:
    u64 v_;
};


#endif
