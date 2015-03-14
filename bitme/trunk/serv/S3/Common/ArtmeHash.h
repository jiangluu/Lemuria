#ifndef __ARTME_HASH_H
#define __ARTME_HASH_H

#include <string.h>


/* ArtMe项目Hash算法。
本算法是项目的核心之一，由client的ID决定此client在具体哪一个进程，避免查全局表。
服务端的每个组件（或者说进程） 都应该有此能力。 
*/


// 得到client在哪个service 
inline s32 artme_hash_c_service(u64 user_sn){
	// 框架开发阶段，直接给0号service 
	return 0;
}

// 得到client在哪个gate
inline s32 artme_hash_c_gate(u64 user_sn){
	// 框架开发阶段，直接给0号gate
	return 0;
}

// 得到数据在哪个DBInstance。 注： DBInstance不等于cache 
inline s32 artme_hash_c_dbinstance(u64 user_sn){
	return user_sn % 128;
}


int string_hash_with_client(const char *str);

// 字符串散列函数 
inline u32 artme_string_hash(const char *str){
	if(str){
		return string_hash_with_client(str);
	}
	return 0;
}


// 跟客户端一样的散列函数 
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
