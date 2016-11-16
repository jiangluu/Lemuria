# Project: gate
# Makefile created by Dev-C++ 5.9.2

CPP      = g++
CC       = g++
WINDRES  = windres.exe
OBJ      = main.o ../Common/alog.o ../Common/bson.o ../Common/kfifo.o ../Common/lfs.o ../Common/link.o  ../Common/omt.o ../Common/polarssl/padlock.o ../Common/polarssl/aes.o ../Common/polarssl/aesni.o ../Common/GXContext.o LuaInterface.o message_dispatch.o ../Common/GXCfunction.o
LINKOBJ  = $(OBJ)
LIBS     = -rdynamic -L../../lib/x64 -L../../lib -L/usr/local/lib  -lluajit  -lm -lpthread -ldl
INCS     =  -I"../Common" -I../../include/luajit -I/usr/local/include -I.
CXXINCS  = $(INCS)
BIN      = gate
CXXFLAGS = $(CXXINCS) -g -fexceptions -fnon-call-exceptions -fomit-frame-pointer -fstack-check -fpermissive -O2 -DENABLE_ENCRYPT
CFLAGS   = $(INCS) -g -fexceptions -fnon-call-exceptions -fomit-frame-pointer -fstack-check -fpermissive -O2 -DENABLE_ENCRYPT
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
