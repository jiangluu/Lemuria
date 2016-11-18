//-----------------------------------------------------------------------------
// 文件名 : LuaInterface.h
// 模块    :    Script
// 功能     :    脚本系统提供给外界使用的Lua的接口
// 修改历史:
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
*    脚本解释器封装类。
*/
class LuaInterface
{
public:
    /**
    *    构造函数。
    *    如果传入一个已有的解释器实例，则使用此实例。
    *    否则生成一个新实例。
    *    @see ~LuaWrapper()
    */
    LuaInterface(lua_State* luaVM=0);
    
    /**
    *    析构函数。
    *    会释放解释器的实例。
    *    @see LuaWrapper()
    */
    ~LuaInterface()
    {
        lua_close(lua_state_);
    }
    
    void Init();
    
    /**
    *    取得内部解释器实例的句柄。
    */
    lua_State* luaState(){ return lua_state_; }
    lua_State* L(){ return lua_state_; }
    /**
    *    获得在解释器堆栈中的参数个数。
    */
    int GetParamCount()
    {
        return lua_gettop(lua_state_);
    }
    /**
    *    取得脚本中某个全局变量的值。
    *    @param name 全局变量在脚本中的名字
    *    @return 全局变量的值
    *    @see SetGlobal()
    */
    template<typename R>
    R GetGlobal(const char* name)
    {
        lua_getglobal(lua_state_, name);  
        return getValue<R>();
    }
    /**
    *    设置脚本中某个全局变量的值。
    *    @param name 全局变量在脚本中的名字
    *    @param value 欲设置的值
    *    @see GetGlobal()
    */
    template<typename T>
    void SetGlobal(const char* name, T value)
    {
        Push(value);
        lua_setglobal(lua_state_, name);
    }
    /**
    *    获取脚本中某个全局变量的一个成员的值。
    *    @param var_name 全局变量在脚本中的名字
    *    @param field_name 成员的名字
    *    @return 成员的值
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
    *    设置脚本中某个全局变量的一个成员的值。
    *    @param var_name 全局变量在脚本中的名字
    *    @param field_name 成员的名字
    *    @param value 欲设置的值
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
    *    调用某个对象在脚本中定义的成员函数(没有参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @return 函数返回值(如果有返回值)
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
    *    调用某个对象在脚本中定义的成员函数(一个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @return 函数返回值(如果有返回值)
    *    @note 返回值类型必须为以下几种之一，或者可以自动转化为这些类型:
    *    int,double,bool,char*,void*。
    *    如果函数需要返回一个自定义对象，那么必须返回它的指针，并指定返回值类型为void*，然后再强制转换为自定义类型。如:
    *    @code Npc* npc0 = (Npc*)script.callObjFunc<void*>(npc_mng,"createNPC"); @endcode
    *    如果此函数没有返回值，返回值类型必须设为 void。
    *    目前只支持最多一个返回值。
    *    如果需要传入自定义对象作为参数，那么必须传入对象指针，而不是值或者引用。
    *    作为参数传入的对象必须经过函数 addWrapperToCObj() 处理。
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
    *    调用某个对象在脚本中定义的成员函数(二个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @return 函数返回值(如果有返回值)
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
    *    调用某个对象在脚本中定义的成员函数(三个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @return 函数返回值(如果有返回值)
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
    *    调用某个对象在脚本中定义的成员函数(四个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @return 函数返回值(如果有返回值)
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
    *    调用某个对象在脚本中定义的成员函数(五个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @param p5 参数5
    *    @return 函数返回值(如果有返回值)
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
    *    调用某个对象在脚本中定义的成员函数(六个参数版本)。
    *    @param obj 对象指针。必须是指针，而不是值或者引用
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @param p5 参数5
    *    @param p6 参数6
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(没有参数版本)。
    *    @param func 成员函数的名字
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(一个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @return 函数返回值(如果有返回值)
    *    @note 返回值类型必须为以下几种之一，或者可以自动转化为这些类型:
    *    int,double,bool,char*,void*。
    *    如果函数需要返回一个自定义对象，那么必须返回它的指针，并指定返回值类型为void*，然后再强制转换为自定义类型。如:
    *    @code Npc* npc0 = (Npc*)script.callGlobalFunc<void*>("createNPC"); @endcode
    *    如果此函数没有返回值，返回值类型必须设为 void。
    *    目前只支持最多一个返回值。
    *    如果需要传入自定义对象作为参数，那么必须传入对象指针，而不是值或者引用。
    *    作为参数传入的对象必须经过函数 addWrapperToCObj() 处理。
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
    *    调用脚本中定义的全局函数(二个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(三个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(四个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(五个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @param p5 参数5
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(六个参数版本)。
    *    @param func 成员函数的名字
    *    @param p1 参数1
    *    @param p2 参数2
    *    @param p3 参数3
    *    @param p4 参数4
    *    @param p5 参数5
    *    @param p6 参数6
    *    @return 函数返回值(如果有返回值)
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
    *    调用脚本中定义的全局函数(七个参数版本)。
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
    *    打印解释器的堆栈
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
    *    装入并执行某个脚本文件
    *    @param fname 文件名
    *    @return 解释器的执行结果
    */
    int doFile(const char* fname)
    {
        return luaL_dofile(lua_state_,fname);
    }
    /**
    *    把某个C++生成的对象处理一下，使之可以被脚本访问。此对象的类型必须是已经映射到脚本里的类型。
    *    @param cobj 对象指针。必须是指针，而不是值或者引用
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
        //废弃这种做法 
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
        if (lua_isnil(lua_state_,-1))    // 没有注册过这个对象
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

		//废弃这种做法 
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
		//为了防止Lua返回nil而得到一个空指针，如下
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
        // 废弃 
    }
    
    void ex_function(lua_State* luaVM);


protected:
    lua_State* lua_state_;
};


//#ifndef WIN32
template<>
void LuaInterface::_Call<void>(int);
//#endif



#ifdef WIN32
#define CF_EXPORT  __declspec(dllexport)
#else
#define CF_EXPORT
#endif

extern "C"{

CF_EXPORT int c_luaopen_lfs(lua_State *L);

CF_EXPORT int c_luaopen_bson(lua_State *L);

CF_EXPORT int c_luaopen_atablepointer(lua_State *L);

CF_EXPORT int c_lua_ex_function(lua_State *L);

CF_EXPORT lua_State* c_lua_new_vm();

}


#endif
