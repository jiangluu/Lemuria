#include <stdint.h>
#include <stdlib.h>
#include <string.h>
extern "C"{
	#include <lua.h>
	#include <lauxlib.h>
}



// 注意：以下是来自于 LuaJit2.0.3源码，不代表其他Lua版本也能行
typedef __attribute__((aligned(8))) struct TValue {
	uint32_t gcr;	/* GCobj reference (if any). */
    uint32_t it;	/* Internal object tag. Must overlap MSW of number. */
} TValue;

struct Hack_lua_State {
  uint32_t nextgc; 
  uint8_t marked; 
  uint8_t gct;
  uint8_t dummy_ffid;	/* Fake FF_C for curr_funcisL() on dummy frames. */
  uint8_t status;	/* Thread status. */
  uint32_t glref;		/* Link to global state. */
  uint32_t gclist;		/* GC chain. */
  TValue *base;		/* Base of currently executing function. */
  TValue *top;		/* First free slot in the stack. */
};



#define LJ_TTAB			(~11u)
// END ================================

#define C_ENV_SHARED_LIGHTUD_LEN 512

static void** __make_sure_ptr_pool()
{
	static void** aa = NULL;
	if(NULL == aa){
		int len = sizeof(void*) * C_ENV_SHARED_LIGHTUD_LEN;
		aa = (void**)malloc(len);
		memset(aa,0,len);
	}
	return aa;
}


static int ltopointer(lua_State *L) {
	luaL_checktype(L, 2, LUA_TTABLE);
	lua_Integer index = lua_tointeger(L,1);
	const void * t = lua_topointer(L, 2);
	
	if(index>0 && index<=C_ENV_SHARED_LIGHTUD_LEN){
		void **a = __make_sure_ptr_pool();
		a[index-1] = t;
		
		lua_pushboolean(L,1);
	}
	else{
		lua_pushboolean(L,0);
	}
	
	return 1;
}


static int lrestoretable(lua_State *L) {
	lua_Integer index = lua_tointeger(L,1);
	
	if(index>0 && index<=C_ENV_SHARED_LIGHTUD_LEN){
		void **a = __make_sure_ptr_pool();
		
		struct Hack_lua_State *hl = (struct Hack_lua_State*)L;
		
		// hack below
		lua_pushlightuserdata(L, (void *)0);
		TValue *to_hack = hl->top - 1;
		
		to_hack->gcr = (uint32_t)(a[index-1]);
		to_hack->it = LJ_TTAB;
	}
	else{
		lua_pushboolean(L,0);
	}
	
	return 1;
}

int luaopen_atablepointer(lua_State *L) {
	luaL_Reg l[] = {
		{ "topointer", ltopointer },
		{ "restoretable", lrestoretable },
		{ NULL, NULL },
	};
	luaL_register(L,"atabletopointer",l);
	
	return 1;
}
