CFLAGS=-f elf32
LDFLAGS=-shared -m elf_i386 --dynamic-linker=/lib/ld-linux.so.2 -z notext
LUA_SHARED=lua_shared_srv.so
SOURCE=source/

ifeq (,$(wildcard ./$(LUA_SHARED)))
    $(error lua_shared_srv.so not found!)
endif

all: crc32 hello

crc32: crc32.o
	ld $(LDFLAGS) $(SOURCE)crc32.o $(LUA_SHARED) -o gmsv_crc32_linux.dll
	#cp gmsv_crc32_linux.dll ~/Steam/steamapps/common/GarrysModDS/garrysmod/lua/bin/gmsv_crc32_linux.dll

crc32.o:
	nasm $(CFLAGS) $(SOURCE)crc32.asm	

hello: hello.o
	ld $(LDFLAGS) $(SOURCE)hello.o $(LUA_SHARED) -o gmsv_hello_linux.dll
	#cp gmsv_hello_linux.dll ~/Steam/steamapps/common/GarrysModDS/garrysmod/lua/bin/gmsv_hello_linux.dll

hello.o:
	nasm $(CFLAGS) $(SOURCE)hello.asm	

clean:
	rm -rf $(SOURCE)*.o *.dll