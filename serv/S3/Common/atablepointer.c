#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>



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



/*
	table
	return pointer
 */
static int
ltopointer(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	const void * t = lua_topointer(L, 1);
	lua_pushlightuserdata(L, (void *)t);
	return 1;
}

/*
	pointer
	return table
 */
static int
lrestoretable(lua_State *L) {
	luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
	void *pp = lua_touserdata(L, 1);
	
	struct Hack_lua_State *hl = (struct Hack_lua_State*)L;
	
	// hack below
	lua_pushlightuserdata(L, (void *)0);
	TValue *to_hack = hl->top - 1;
	
	to_hack->gcr = (uint32_t)pp;
	to_hack->it = LJ_TTAB;
	
	
	return 1;
}

int
luaopen_atablepointer(lua_State *L) {
	luaL_Reg l[] = {
		{ "topointer", ltopointer },
		{ "restoretable", lrestoretable },
		{ NULL, NULL },
	};
	luaL_register(L,"atabletopointer",l);
	
	return 1;
}
