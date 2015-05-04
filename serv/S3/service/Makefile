# Project: service
# Makefile created by Dev-C++ 5.9.2

CPP      = g++
CC       = g++
WINDRES  = windres.exe
OBJ      = main.o ../Common/alog.o ../Common/bson.o ../Common/kfifo.o ../Common/lfs.o ../Common/link.o ../Common/luaconf.o ../Common/omt.o ../Common/polarssl/padlock.o ../Common/polarssl/aes.o ../Common/polarssl/aesni.o ../Common/GXContext.o LuaInterface.o message_dispatch.o ../Common/GXCfunction.o ../Common/ae/ae.o ../Common/hiredis/async.o ../Common/hiredis/dict.o ../Common/hiredis/hiredis.o ../Common/hiredis/net.o ../Common/hiredis/sds.o CBox/CBox.o CBox/CBoxPool.o CBox/IOLine.o cfunction.o ../Common/polarssl/md5.o ../Common/pbc/alloc.o ../Common/pbc/array.o ../Common/pbc/bootstrap.o ../Common/pbc/context.o ../Common/pbc/decode.o ../Common/pbc/map.o ../Common/pbc/pattern.o ../Common/pbc/proto.o ../Common/pbc/register.o ../Common/pbc/rmessage.o ../Common/pbc/stringpool.o ../Common/pbc/varint.o ../Common/pbc/wmessage.o
LINKOBJ  = $(OBJ)
LIBS     = -rdynamic -L../../lib/x64 -L../../lib -L/usr/local/lib  -lluajit  -lm -lpthread -ldl
INCS     =  -I"../Common" -I../../include/tolua++ -I/usr/local/include
CXXINCS  = $(INCS)
BIN      = service
CXXFLAGS = $(CXXINCS) -g -fexceptions -fnon-call-exceptions -fomit-frame-pointer -fstack-check -fpermissive -O2
CFLAGS   = $(INCS) -g -fexceptions -fnon-call-exceptions -fomit-frame-pointer -fstack-check -fpermissive -O2
RM       = rm -f

.PHONY: all all-before all-after clean clean-custom

all: all-before $(BIN) all-after

clean: clean-custom
	${RM} $(OBJ) $(BIN)

$(BIN): $(OBJ)
	$(CPP) $(LINKOBJ) -o $(BIN) $(LIBS)

main.o: main.cpp
	$(CPP) -c main.cpp -o main.o $(CXXFLAGS)

../Common/alog.o: ../Common/alog.cpp
	$(CPP) -c ../Common/alog.cpp -o ../Common/alog.o $(CXXFLAGS)

../Common/bson.o: ../Common/bson.c
	$(CPP) -c ../Common/bson.c -o ../Common/bson.o $(CXXFLAGS)

../Common/kfifo.o: ../Common/kfifo.cpp
	$(CPP) -c ../Common/kfifo.cpp -o ../Common/kfifo.o $(CXXFLAGS)

../Common/lfs.o: ../Common/lfs.cpp
	$(CPP) -c ../Common/lfs.cpp -o ../Common/lfs.o $(CXXFLAGS)

../Common/link.o: ../Common/link.cpp
	$(CPP) -c ../Common/link.cpp -o ../Common/link.o $(CXXFLAGS)

../Common/luaconf.o: ../Common/luaconf.c
	$(CPP) -c ../Common/luaconf.c -o ../Common/luaconf.o $(CXXFLAGS)

../Common/omt.o: ../Common/omt.c
	$(CPP) -c ../Common/omt.c -o ../Common/omt.o $(CXXFLAGS)

../Common/polarssl/padlock.o: ../Common/polarssl/padlock.c
	$(CPP) -c ../Common/polarssl/padlock.c -o ../Common/polarssl/padlock.o $(CXXFLAGS)

../Common/polarssl/aes.o: ../Common/polarssl/aes.c
	$(CPP) -c ../Common/polarssl/aes.c -o ../Common/polarssl/aes.o $(CXXFLAGS)

../Common/GXContext.o: ../Common/GXContext.cpp
	$(CPP) -c ../Common/GXContext.cpp -o ../Common/GXContext.o $(CXXFLAGS)

LuaInterface.o: LuaInterface.cpp
	$(CPP) -c LuaInterface.cpp -o LuaInterface.o $(CXXFLAGS)

message_dispatch.o: message_dispatch.cpp
	$(CPP) -c message_dispatch.cpp -o message_dispatch.o $(CXXFLAGS)

../Common/GXCfunction.o: ../Common/GXCfunction.cpp
	$(CPP) -c ../Common/GXCfunction.cpp -o ../Common/GXCfunction.o $(CXXFLAGS)

../Common/ae/ae.o: ../Common/ae/ae.c
	$(CPP) -c ../Common/ae/ae.c -o ../Common/ae/ae.o $(CXXFLAGS)

../Common/hiredis/async.o: ../Common/hiredis/async.c
	$(CPP) -c ../Common/hiredis/async.c -o ../Common/hiredis/async.o $(CXXFLAGS)

../Common/hiredis/dict.o: ../Common/hiredis/dict.c
	$(CPP) -c ../Common/hiredis/dict.c -o ../Common/hiredis/dict.o $(CXXFLAGS)

../Common/hiredis/hiredis.o: ../Common/hiredis/hiredis.c
	$(CPP) -c ../Common/hiredis/hiredis.c -o ../Common/hiredis/hiredis.o $(CXXFLAGS)

../Common/hiredis/net.o: ../Common/hiredis/net.c
	$(CPP) -c ../Common/hiredis/net.c -o ../Common/hiredis/net.o $(CXXFLAGS)

../Common/hiredis/sds.o: ../Common/hiredis/sds.c
	$(CPP) -c ../Common/hiredis/sds.c -o ../Common/hiredis/sds.o $(CXXFLAGS)

CBox/CBox.o: CBox/CBox.cpp
	$(CPP) -c CBox/CBox.cpp -o CBox/CBox.o $(CXXFLAGS)

CBox/CBoxPool.o: CBox/CBoxPool.cpp
	$(CPP) -c CBox/CBoxPool.cpp -o CBox/CBoxPool.o $(CXXFLAGS)

CBox/IOLine.o: CBox/IOLine.cpp
	$(CPP) -c CBox/IOLine.cpp -o CBox/IOLine.o $(CXXFLAGS)

cfunction.o: cfunction.cpp
	$(CPP) -c cfunction.cpp -o cfunction.o $(CXXFLAGS)

../Common/polarssl/md5.o: ../Common/polarssl/md5.c
	$(CPP) -c ../Common/polarssl/md5.c -o ../Common/polarssl/md5.o $(CXXFLAGS)

../Common/pbc/alloc.o: ../Common/pbc/alloc.c
	$(CPP) -c ../Common/pbc/alloc.c -o ../Common/pbc/alloc.o $(CXXFLAGS)

../Common/pbc/array.o: ../Common/pbc/array.c
	$(CPP) -c ../Common/pbc/array.c -o ../Common/pbc/array.o $(CXXFLAGS)

../Common/pbc/bootstrap.o: ../Common/pbc/bootstrap.c
	$(CPP) -c ../Common/pbc/bootstrap.c -o ../Common/pbc/bootstrap.o $(CXXFLAGS)

../Common/pbc/context.o: ../Common/pbc/context.c
	$(CPP) -c ../Common/pbc/context.c -o ../Common/pbc/context.o $(CXXFLAGS)

../Common/pbc/decode.o: ../Common/pbc/decode.c
	$(CPP) -c ../Common/pbc/decode.c -o ../Common/pbc/decode.o $(CXXFLAGS)

../Common/pbc/map.o: ../Common/pbc/map.c
	$(CPP) -c ../Common/pbc/map.c -o ../Common/pbc/map.o $(CXXFLAGS)

../Common/pbc/pattern.o: ../Common/pbc/pattern.c
	$(CPP) -c ../Common/pbc/pattern.c -o ../Common/pbc/pattern.o $(CXXFLAGS)

../Common/pbc/proto.o: ../Common/pbc/proto.c
	$(CPP) -c ../Common/pbc/proto.c -o ../Common/pbc/proto.o $(CXXFLAGS)

../Common/pbc/register.o: ../Common/pbc/register.c
	$(CPP) -c ../Common/pbc/register.c -o ../Common/pbc/register.o $(CXXFLAGS)

../Common/pbc/rmessage.o: ../Common/pbc/rmessage.c
	$(CPP) -c ../Common/pbc/rmessage.c -o ../Common/pbc/rmessage.o $(CXXFLAGS)

../Common/pbc/stringpool.o: ../Common/pbc/stringpool.c
	$(CPP) -c ../Common/pbc/stringpool.c -o ../Common/pbc/stringpool.o $(CXXFLAGS)

../Common/pbc/varint.o: ../Common/pbc/varint.c
	$(CPP) -c ../Common/pbc/varint.c -o ../Common/pbc/varint.o $(CXXFLAGS)

../Common/pbc/wmessage.o: ../Common/pbc/wmessage.c
	$(CPP) -c ../Common/pbc/wmessage.c -o ../Common/pbc/wmessage.o $(CXXFLAGS)
