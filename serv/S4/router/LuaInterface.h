//-----------------------------------------------------------------------------
// �ļ��� : LuaInterface.h
// ģ��    :    Script
// ����     :    �ű�ϵͳ�ṩ�����ʹ�õ�Lua�Ľӿ�
// �޸���ʷ:
//-----------------------------------------------------------------------------
#ifndef __LUAINTERFACE_H_
#define __LUAINTERFACE_H_
extern "C"
{
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}
#include "lfs.h"
#include <string>
using std::string;


#define FILENAMEKEY  "LOADEDFILENAME"

#define MAX_SCRIPT_HOLD 4096


typedef lua_State Lua_State;
#define Lua_ValueToNumber lua_tointeger
#define Lua_ValueToString lua_tostring
#define Lua_GetTopIndex  lua_gettop
#define Lua_PushNumber lua_pushnumber
#define Lua_PushString lua_pushstring
#define Lua_IsNumber lua_isnumber


#define __ENTER_FUNCTION
#define __LEAVE_FUNCTION



/**
*    �ű���������װ�ࡣ
*/
class LuaInterface
{
public:
    /**
    *    ���캯����
    *    �������һ�����еĽ�����ʵ������ʹ�ô�ʵ����
    *    ��������һ����ʵ����
    *    @see ~LuaWrapper()
    */
    LuaInterface(lua_State* luaVM=0);
    
    /**
    *    ����������
    *    ���ͷŽ�������ʵ����
    *    @see LuaWrapper()
    */
    ~LuaInterface()
    {
        lua_close(lua_state_);
    }
    
    void Init();
    
    /**
    *    ȡ���ڲ�������ʵ���ľ����
    */
    lua_State* luaState(){ return lua_state_; }
    lua_State* L(){ return lua_state_; }
    /**
    *    ����ڽ�������ջ�еĲ���������
    */
    int GetParamCount()
    {
        return lua_gettop(lua_state_);
    }
    /**
    *    ȡ�ýű���ĳ��ȫ�ֱ�����ֵ��
    *    @param name ȫ�ֱ����ڽű��е�����
    *    @return ȫ�ֱ�����ֵ
    *    @see SetGlobal()
    */
    template<typename R>
    R GetGlobal(const char* name)
    {
        lua_getglobal(lua_state_, name);  
        return getValue<R>();
    }
    /**
    *    ���ýű���ĳ��ȫ�ֱ�����ֵ��
    *    @param name ȫ�ֱ����ڽű��е�����
    *    @param value �����õ�ֵ
    *    @see GetGlobal()
    */
    template<typename T>
    void SetGlobal(const char* name, T value)
    {
        Push(value);
        lua_setglobal(lua_state_, name);
    }
    /**
    *    ��ȡ�ű���ĳ��ȫ�ֱ�����һ����Ա��ֵ��
    *    @param var_name ȫ�ֱ����ڽű��е�����
    *    @param field_name ��Ա������
    *    @return ��Ա��ֵ
    *    @see setGlobalVarField()
    */
    template<typename R>
    R getGlobalVarField(const char* var_name,const char* field_name)
    {
        lua_getglobal(lua_state_, var_name);
        Push(field_name);
        lua_gettable(lua_state_,-2);
        return getValue<R>();
    }
    /**
    *    ���ýű���ĳ��ȫ�ֱ�����һ����Ա��ֵ��
    *    @param var_name ȫ�ֱ����ڽű��е�����
    *    @param field_name ��Ա������
    *    @param value �����õ�ֵ
    *    @see getGlobalVarField()
    */
    template<typename T>
    void setGlobalVarField(const char* var_name,const char* field_name,T value)
    {
        lua_getglobal(lua_state_, var_name);
        Push(field_name);
        Push(value);
        lua_settable(lua_state_,-3);
        return;
    }

#if 0
    template<class T>
    void DelGlobalObject(const char* name)
    {
        lua_getglobal(lua_state_, name);
        lua_pushnil(lua_state_);
        lua_setglobal(lua_state_, name);
    }
#endif
#if 0
    template<typename T>
    void DelCObjHard(T obj_ptr)
    {
        if(obj_ptr == NULL) return;
        callObjFunc<void>(obj_ptr,"__gc");
    }
#endif

    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(û�в����汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE>
    R callObjFunc(OBJTYPE obj,const char* func)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);

        return _Call<R>(1);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(һ�������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @return ��������ֵ(����з���ֵ)
    *    @note ����ֵ���ͱ���Ϊ���¼���֮һ�����߿����Զ�ת��Ϊ��Щ����:
    *    int,double,bool,char*,void*��
    *    ���������Ҫ����һ���Զ��������ô���뷵������ָ�룬��ָ������ֵ����Ϊvoid*��Ȼ����ǿ��ת��Ϊ�Զ������͡���:
    *    @code Npc* npc0 = (Npc*)script.callObjFunc<void*>(npc_mng,"createNPC"); @endcode
    *    ����˺���û�з���ֵ������ֵ���ͱ�����Ϊ void��
    *    Ŀǰֻ֧�����һ������ֵ��
    *    �����Ҫ�����Զ��������Ϊ��������ô���봫�����ָ�룬������ֵ�������á�
    *    ��Ϊ��������Ķ�����뾭������ addWrapperToCObj() ����
    *    @see addWrapperToCObj(T cobj)
    */
    template<typename R,typename OBJTYPE,typename P1>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);

        return _Call<R>(2);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(���������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE,typename P1,typename P2>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1,P2 p2)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);
        Push(p2);

        return _Call<R>(3);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(���������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE,typename P1,typename P2,typename P3>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1,P2 p2,P3 p3)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);
        Push(p2);
        Push(p3);

        return _Call<R>(4);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(�ĸ������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE,typename P1,typename P2,typename P3,typename P4>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1,P2 p2,P3 p3,P4 p4)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);

        return _Call<R>(5);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(��������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @param p5 ����5
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE,typename P1,typename P2,typename P3,typename P4,typename P5>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);

        return _Call<R>(6);
    }
    /**
    *    ����ĳ�������ڽű��ж���ĳ�Ա����(���������汾)��
    *    @param obj ����ָ�롣������ָ�룬������ֵ��������
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @param p5 ����5
    *    @param p6 ����6
    *    @return ��������ֵ(����з���ֵ)
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename R,typename OBJTYPE,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6>
    R callObjFunc(OBJTYPE obj,const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        
        Push(obj);
        lua_pushstring(lua_state_, func);
        lua_gettable(lua_state_,-2);
        lua_insert(lua_state_,-2);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);

        return _Call<R>(7);
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(û�в����汾)��
    *    @param func ��Ա����������
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R>
    R callGlobalFunc(const char* func)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);

        return _Call<R>(0);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(һ�������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @return ��������ֵ(����з���ֵ)
    *    @note ����ֵ���ͱ���Ϊ���¼���֮һ�����߿����Զ�ת��Ϊ��Щ����:
    *    int,double,bool,char*,void*��
    *    ���������Ҫ����һ���Զ��������ô���뷵������ָ�룬��ָ������ֵ����Ϊvoid*��Ȼ����ǿ��ת��Ϊ�Զ������͡���:
    *    @code Npc* npc0 = (Npc*)script.callGlobalFunc<void*>("createNPC"); @endcode
    *    ����˺���û�з���ֵ������ֵ���ͱ�����Ϊ void��
    *    Ŀǰֻ֧�����һ������ֵ��
    *    �����Ҫ�����Զ��������Ϊ��������ô���봫�����ָ�룬������ֵ�������á�
    *    ��Ϊ��������Ķ�����뾭������ addWrapperToCObj() ����
    *    @see addWrapperToCObj(T cobj)
    */
    template<typename R,typename P1>
    R callGlobalFunc(const char* func,P1 p1)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);

        return _Call<R>(1);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(���������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R,typename P1,typename P2>
    R callGlobalFunc(const char* func,P1 p1,P2 p2)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);

        return _Call<R>(2);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(���������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R,typename P1,typename P2,typename P3>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);

        return _Call<R>(3);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(�ĸ������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R,typename P1,typename P2,typename P3,typename P4>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);

        return _Call<R>(4);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(��������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @param p5 ����5
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);

        return _Call<R>(5);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(���������汾)��
    *    @param func ��Ա����������
    *    @param p1 ����1
    *    @param p2 ����2
    *    @param p3 ����3
    *    @param p4 ����4
    *    @param p5 ����5
    *    @param p6 ����6
    *    @return ��������ֵ(����з���ֵ)
    *    @see callGlobalFunc(const char* func,P1 p1)
    */
    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);

        return _Call<R>(6);

		__LEAVE_FUNCTION

		return R();
    }
    /**
    *    ���ýű��ж����ȫ�ֺ���(�߸������汾)��
    */
    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6,typename P7>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6,P7 p7)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
		__ENTER_FUNCTION

        
        
        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);
        Push(p7);

        return _Call<R>(7);

		__LEAVE_FUNCTION

		return R();
    }

    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6,typename P7,typename P8>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6,P7 p7,P8 p8)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        //
		__ENTER_FUNCTION

        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);
        Push(p7);
        Push(p8);

        return _Call<R>(8);

		__LEAVE_FUNCTION

		return R();
    }

    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6,typename P7,typename P8,typename P9>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6,P7 p7,P8 p8,P9 p9)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        //
		__ENTER_FUNCTION

        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);
        Push(p7);
        Push(p8);
        Push(p9);

        return _Call<R>(9);

		__LEAVE_FUNCTION

		return R();
    }

    template<typename R,typename P1,typename P2,typename P3,typename P4,typename P5,typename P6,typename P7,typename P8,typename P9,typename P10>
    R callGlobalFunc(const char* func,P1 p1,P2 p2,P3 p3,P4 p4,P5 p5,P6 p6,P7 p7,P8 p8,P9 p9,P10 p10)
    {
        //LOKI_STATIC_CHECK(TypeTraits<R>::isReference==false,must_use_a_value)
        //

		__ENTER_FUNCTION

        lua_getglobal(lua_state_, func);
        Push(p1);
        Push(p2);
        Push(p3);
        Push(p4);
        Push(p5);
        Push(p6);
        Push(p7);
        Push(p8);
        Push(p9);
        Push(p10);

        return _Call<R>(10);

		__LEAVE_FUNCTION

		return R();
    }

    /**
    *    ��ӡ�������Ķ�ջ
    */
    void DumpStack()
    {
        int i;
        int top = lua_gettop(lua_state_);
        for (i = 1; i <= top; i++)    //  repeat for each level 
        {
            int t = lua_type(lua_state_, i);
            switch (t)
            {
                case LUA_TSTRING:  // strings 
                printf("script_dumpstack  %s\n", lua_tostring(lua_state_, i));
                break;
    
                case LUA_TBOOLEAN:  // booleans 
                printf("script_dumpstack  %s\n",lua_toboolean(lua_state_, i) ? "true" : "false");
                break;
    
                case LUA_TNUMBER:  // numbers 
                printf("script_dumpstack  %g\n", lua_tonumber(lua_state_, i));
                break;
    
                default:  // other values 
                printf("script_dumpstack  %s\n", lua_typename(lua_state_, t));
                break;
            }
        }
    }
    /**
    *    װ�벢ִ��ĳ���ű��ļ�
    *    @param fname �ļ���
    *    @return ��������ִ�н��
    */
    int doFile(const char* fname)
    {
        return luaL_dofile(lua_state_,fname);
    }
    /**
    *    ��ĳ��C++���ɵĶ�����һ�£�ʹ֮���Ա��ű����ʡ��˶�������ͱ������Ѿ�ӳ�䵽�ű�������͡�
    *    @param cobj ����ָ�롣������ָ�룬������ֵ��������
    *    @see callObjFunc(OBJTYPE obj,const char* func,P1 p1)
    */
    template<typename T>
    void addWrapperToCObj(T cobj)
    {
        //LOKI_STATIC_CHECK(TypeTraits<T>::isPointer,must_use_a_pointer)

        addWrapperToCObj(cobj,cobj->className());
    }

    void clearStack(){ lua_settop(lua_state_, 0); }


    
    
    void Push()
    {
        lua_pushnil(lua_state_);
    }
    void Push(const char* param)
    {
        lua_pushstring(lua_state_, param);
    }
    void Push(const string& param)
    {
        lua_pushlstring(lua_state_, param.c_str(), param.size());
    }
    void Push(string& param)
    {
        lua_pushlstring(lua_state_, param.c_str(), param.size());
    }
    void Push(short param)
    {
        lua_pushnumber(lua_state_, param);
    }
    void Push(int param)
    {
        lua_pushnumber(lua_state_, param);
    }
    void Push(unsigned int param)
    {
        lua_pushnumber(lua_state_, param);
    }
    void Push(float param)
    {
        lua_pushnumber(lua_state_, param);
    }
    void Push(double param)
    {
        lua_pushnumber(lua_state_, param);
    }
    void Push(bool param)
    {
        lua_pushboolean(lua_state_, param);
    }
    void Push(lua_CFunction  param)
    {
        lua_pushcfunction(lua_state_, param);
    }

    template<typename U>
    void Push(U param)
    {
        //LOKI_STATIC_CHECK(TypeTraits<U>::isPointer,must_use_a_pointer)
        //typedef typename TypeTraits<U>::PointeeType ParamType;

        if(!param) return;
        //������������ 
        //Cobj2LuaObjStack(param,param->className());
        WILL_NOT_COMPILE_PASS();
    }

protected:
    void Cobj2LuaObjStack(void* cobj,const char* className)
    {
    #if 0
        //perror(className);
        static const char* uBox = "tolua_ubox";
        luaL_getmetatable(lua_state_, className);
        Push(uBox);
        lua_rawget(lua_state_,-2);
        if (lua_isnil(lua_state_,-1))
        {
            perror("uBox not found!!\n");
            lua_pop(lua_state_,2);
            return;
        }
        lua_pushlightuserdata(lua_state_,cobj);
        lua_rawget(lua_state_,-2);
        if (lua_isnil(lua_state_,-1))    // û��ע����������
        {
            perror("lua has no such a obj!! \n");
            lua_pop(lua_state_,3);
            return;
        }
        lua_insert(lua_state_,-3);
        lua_pop(lua_state_,2);
    #endif

    #if 0
        void** pobj = static_cast<void**>( lua_newuserdata(lua_state_, sizeof(void*)) );
        *pobj = cobj;

        luaL_getmetatable(lua_state_, className);
        lua_setmetatable(lua_state_, -2);
    #endif

		//������������ 
        //tolua_pushusertype(lua_state_,(void*)cobj,className);
    }
    void Pop(int count = 1)
    {
        lua_pop(lua_state_,count);
    }
    void getValue(short& v,int index=-1)
    {
        v = (short)lua_tointeger(lua_state_,index);
    }
    void getValue(int& v,int index=-1)
    {
        v = (int)lua_tointeger(lua_state_,index);
    }

    void getValue(double& v,int index=-1)
    {
        v = lua_tonumber(lua_state_,index);
    }

    void getValue(char*& v,int index=-1)
    {
		//Ϊ�˷�ֹLua����nil���õ�һ����ָ�룬����
		static const char *ss = "no value";
		
		size_t len = 0;
		const char *ret = lua_tolstring(lua_state_,index,&len);
		if(0==len || 0==ret){
			v = (char*)ss;
		}
		else{
			v = (char*)ret;
		}
    }

    void getValue(string& v,int index=-1)
    {
		static const char *ss = "no value";
		
		size_t len = 0;
		const char *ret = lua_tolstring(lua_state_,index,&len);
		if(0==len || 0==ret){
			v = ss;
		}
		else{
			v.assign(ret,len);
		}
    }

    void getValue(bool& v,int index=-1)
    {
        v = (lua_toboolean(lua_state_,index) ? true : false);
    }
    void getValue(void*& v,int index=-1)
    {
        v = lua_touserdata(lua_state_,index);
    }

public:
    template<typename U>
    U getValue(int index=-1)
    {
        //LOKI_STATIC_CHECK(TypeTraits<U>::isReference==false,must_use_a_value)
        //typedef typename TypeTraits<U>::NonConstType ReturnType;

        U r;
        getValue(r,index);
        Pop();
        return r;
    }

    template<typename U>
    U getValueNoPop(int index=-1)
    {
        //LOKI_STATIC_CHECK(TypeTraits<U>::isReference==false,must_use_a_value)
        //typedef typename TypeTraits<U>::NonConstType ReturnType;

        U r;
        getValue(r,index);
        return r;
    }

protected:
    template<typename R>
    R _Call(int param_num)
    {
	__ENTER_FUNCTION
		const char* funcName=lua_tostring(lua_state_, -(param_num+1));
        if(lua_pcall(lua_state_,param_num,1,0) != 0)
        {
            char* err = getValueNoPop<char*>();
            printf( "Lua error:[%s] %s\n", funcName, err);
            Pop();
            return R();
        }

        return getValue<R>();
	__LEAVE_FUNCTION

		printf( "Lua Exception !!!!");
		return R();
    }
    

    void addWrapperToCObj(void* cobj,const char* class_name)
    {
        // ���� 
    }
    
    void ex_function(lua_State* luaVM);


protected:
    lua_State* lua_state_;
};


//#ifndef WIN32
template<>
void LuaInterface::_Call<void>(int);
//#endif


#endif
