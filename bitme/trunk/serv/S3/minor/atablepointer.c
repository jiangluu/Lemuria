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

struct GCobj {
  uint32_t nextgc; 
  uint8_t marked; 
  uint8_t gct;
 };


#define LJ_TTAB			(~11u)
#define LJ_GC_WHITE0	0x01
#define LJ_GC_BLACK	0x04
#define LJ_GC_FIXED	0x20
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


struct Atableptr{
	struct GCobj *o;
	lua_State *ownerL;
};


static int ltopointer(lua_State *L) {
	luaL_checktype(L, -1, LUA_TTABLE);
	lua_Integer index = lua_tointeger(L,-2);
	const void * t = lua_topointer(L, -1);
	
	if(index>0 && index<=C_ENV_SHARED_LIGHTUD_LEN){
		void **a = __make_sure_ptr_pool();
		Atableptr *u = (Atableptr*)malloc(sizeof(Atableptr));
		u->o = (struct GCobj *)t;
		u->ownerL = L;
		
		a[index-1] = u;
		
		lua_pushboolean(L,1);
		
		// hack
		struct GCobj *o = (struct GCobj*)t;
		o->marked = LJ_GC_WHITE0;
		o->marked |= LJ_GC_FIXED;	// prevent GC
	}
	else{
		lua_pushboolean(L,0);
	}
	
	return 1;
}


void _new_atableptr(lua_State *L,Atableptr *u) ;

// stack +1
void _hacktotable(lua_State *L,void *ptr) {
	struct Hack_lua_State *hl = (struct Hack_lua_State*)L;
	
	lua_pushinteger(L, 0);
	TValue *to_hack = hl->top - 1;
	to_hack->gcr = (uint32_t)(ptr);
	to_hack->it = LJ_TTAB;
}

// 栈顶到栈顶
void _hack_copyvalue(lua_State *srcL,lua_State *destL) {
	// 除了字符串，其他都“偷”
	if(LUA_TSTRING == lua_type(srcL,-1)){
		size_t len = 0;
		const char *str = lua_tolstring(srcL,-1,&len);
		
		lua_pushlstring(destL,str,len);
		lua_pop(srcL,1);
	}
	else if(LUA_TTABLE == lua_type(srcL,-1)){
		const void * t = lua_topointer(srcL, -1);
		
		Atableptr bb;
		bb.ownerL = srcL;
		bb.o = (struct GCobj *)t;
		_new_atableptr(destL,&bb);
		
		lua_pop(srcL,1);
	}
	else{
		struct Hack_lua_State *src_hL = (struct Hack_lua_State*)srcL;
		
		lua_pushinteger(destL,0);
		struct Hack_lua_State *dest_hL = (struct Hack_lua_State*)destL;
		memcpy(dest_hL->top - 1,src_hL->top - 1,sizeof(TValue));
		
		lua_pop(srcL,1);
	}
}

static int llen(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	void * t = lua_touserdata(L, 1);
	Atableptr *ud = (Atableptr*)(t);
	
	// just for safety
	lua_checkstack(L,5);
	lua_checkstack(ud->ownerL,5);
	
	_hacktotable(ud->ownerL,ud->o);
	size_t n = lua_objlen(ud->ownerL,-1);
	lua_pop(ud->ownerL,1);
	
	lua_pushinteger(L,n);
	return 1;
}

static int lindex(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	void * t = lua_touserdata(L, 1);
	Atableptr *ud = (Atableptr*)(t);
	
	// we should ensure ownerL's stack unchanged
	int stack_before = lua_gettop(ud->ownerL);
	
	// just for safety
	lua_checkstack(L,5);
	lua_checkstack(ud->ownerL,5);
	
	//hack
	if(LUA_TNUMBER == lua_type(L,2)){
		lua_Number n = lua_tonumber(L,-1);
		
		_hacktotable(ud->ownerL,ud->o);
		lua_pushnumber(ud->ownerL,n);
		lua_rawget(ud->ownerL,-2);
		
		_hack_copyvalue(ud->ownerL,L);
		lua_pop(ud->ownerL,1);
	}
	else if(LUA_TSTRING == lua_type(L,2)){
		size_t len = 0;
		const char *str = lua_tolstring(L,-1,&len);
		
		_hacktotable(ud->ownerL,ud->o);
		lua_pushlstring(ud->ownerL,str,len);
		lua_rawget(ud->ownerL,-2);
		
		_hack_copyvalue(ud->ownerL,L);
		lua_pop(ud->ownerL,1);
	}
	else{
		lua_pushstring(L,"tabletopointer  key must be string or interger");
		lua_error(L);
	}
	
	if(lua_gettop(ud->ownerL) != stack_before){
		lua_pushstring(L,"tabletopointer  ownerL stack changed");
		lua_error(L);
	}
	
	return 1;
}

// does NOT pop srcL
int _copy_number_or_string(lua_State *srcL,int src_index,lua_State *destL)
{
	int r = 0;
	int second_param = lua_type(srcL,src_index);
	if(LUA_TNUMBER==second_param){
		lua_Number n = lua_tonumber(srcL,src_index);
		lua_pushnumber(destL,n);
		r = 1;
	}
	else if(LUA_TSTRING==second_param){
		size_t len = 0;
		const char* s = lua_tolstring(srcL,src_index,&len);
		lua_pushlstring(destL,s,len);
		r = 1;
	}
	
	return r;
}

static int Lnext(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct Atableptr *p = (struct Atableptr*)lua_topointer(L, 1);
	
	int stack_before = lua_gettop(p->ownerL);
	lua_checkstack(p->ownerL,5);
	
	_hacktotable(p->ownerL,p->o);
	int second_param = lua_type(L,2);
	// copy key. key just support number or string
	if(LUA_TNUMBER==second_param || LUA_TSTRING==second_param){
		_copy_number_or_string(L,2,p->ownerL);
	}
	else{
		lua_pushnil(p->ownerL);
	}
	
	// call next
	int r = lua_next(p->ownerL,-2);
	if(LUA_TNONE!=lua_type(L,2)){
		lua_pop(L,1);
	}
	
	if(0 == r){		// it's over
		lua_pop(p->ownerL,1);
		if(stack_before != lua_gettop(p->ownerL)){
			lua_pushstring(L,"tabletopointer  ownerL stack changed");
			lua_error(L);
		}
		return 0;
	}
	else{
		int r2 = _copy_number_or_string(p->ownerL,-2,L);
		_hack_copyvalue(p->ownerL,L);
		
		lua_pop(p->ownerL,2);
		
		if(stack_before != lua_gettop(p->ownerL)){
			lua_pushstring(L,"tabletopointer  ownerL stack changed");
			lua_error(L);
		}
		if(0 == r2){
			lua_pushstring(L,"tabletopointer  Lnext key must be number or string");
			lua_error(L);
		}
		
		return 2;
	}
}

static int Lpairs(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	lua_checkstack(L,5);
	
	lua_pushcfunction(L,Lnext);
	lua_insert(L,-2);
	lua_pushnil(L);
	
	return 3;
}

// stack +1
void _new_atableptr(lua_State *L,Atableptr *u) {
	void *ud = lua_newuserdata(L,sizeof(Atableptr));
	memcpy(ud,u,sizeof(Atableptr));
	
	if (luaL_newmetatable(L, "atablepointer")) {
		lua_pushcfunction(L, lindex);
		lua_setfield(L, -2, "__index");
		lua_pushcfunction(L, llen);
		lua_setfield(L, -2, "__len");
	}
	lua_setmetatable(L, -2);
}

static int lrestoretable(lua_State *L) {
	lua_Integer index = lua_tointeger(L,-1);
	
	if(index>0 && index<=C_ENV_SHARED_LIGHTUD_LEN){
		void **a = __make_sure_ptr_pool();
		Atableptr *u = (Atableptr*)(a[index-1]);
		
		_new_atableptr(L,u);
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
		{ "pairs", Lpairs },
		{ NULL, NULL },
	};
	luaL_register(L,"atabletopointer",l);
	
	return 1;
}
