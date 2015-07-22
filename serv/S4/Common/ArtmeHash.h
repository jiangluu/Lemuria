#ifndef __ARTME_HASH_H
#define __ARTME_HASH_H

#include <string.h>


/* ArtMe��ĿHash�㷨��
���㷨����Ŀ�ĺ���֮һ����client��ID������client�ھ�����һ�����̣������ȫ�ֱ�
����˵�ÿ�����������˵���̣� ��Ӧ���д������� 
*/


// �õ�client���ĸ�service 
inline s32 artme_hash_c_service(u64 user_sn){
	// ��ܿ����׶Σ�ֱ�Ӹ�0��service 
	return 0;
}

// �õ�client���ĸ�gate
inline s32 artme_hash_c_gate(u64 user_sn){
	// ��ܿ����׶Σ�ֱ�Ӹ�0��gate
	return 0;
}

// �õ��������ĸ�DBInstance�� ע�� DBInstance������cache 
inline s32 artme_hash_c_dbinstance(u64 user_sn){
	return user_sn % 128;
}


int string_hash_with_client(const char *str);

// �ַ���ɢ�к��� 
inline u32 artme_string_hash(const char *str){
	if(str){
		return string_hash_with_client(str);
	}
	return 0;
}


// ���ͻ���һ����ɢ�к��� 
inline int string_hash_with_client(const char *str){
	if(NULL==str){
		return 0;
	}
	/*
	char* chPtr = (char*)str;
	int num = 0x15051505;
	int num2 = num;
	int* numPtr = (int*) chPtr;
	int str_len = strlen(str);
	for (int i = str_len; i > 0; i -= 4) {
		num = (((num << 5) + num) + (num >> 0x1b)) ^ ((int)numPtr);
		if (i <= 2) break;

		num2 = (((num2 << 5) + num2) + (num2 >> 0x1b)) ^ ((int)numPtr);
		numPtr += 2;
	}
	return (num + (num2 * 0x5d588b65));
	*/
	
	int length = strlen(str);
	{
    	char * cc = (char*)str;
        char * end = cc + length - 1;
    	int h = 0;
        for (;cc < end; cc += 2) {
                h = (h << 5) - h + *cc;
                h = (h << 5) - h + cc [1];
        }
        ++end;
        if (cc < end)
			h = (h << 5) - h + *cc;
        return h;
    }
}


#endif
