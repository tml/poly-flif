# CXXFLAGS := $(shell pkg-config --cflags zlib libpng)
# LDFLAGS := $(shell pkg-config --libs zlib libpng)

CXX=em++

EM_SCRIPT_OPTIONS=-s EXPORTED_FUNCTIONS='["_mainy"]' -s TOTAL_MEMORY=100000000 --js-library flif-library.js

# optimisation options
EM_SCRIPT_OPTIONS+= -s NO_FILESYSTEM=1 -s NO_BROWSER=1
EM_SCRIPT_OPTIONS+= -s NODE_STDOUT_FLUSH_WORKAROUND=0 -s INVOKE_RUN=0
EM_SCRIPT_OPTIONS+= -s ASSERTIONS=0
EM_SCRIPT_OPTIONS+= --closure 1
EM_SCRIPT_OPTIONS+=-s ASM_JS=2

#EM_SCRIPT_OPTIONS+=-s MODULARIZE=1
EM_SCRIPT_OPTIONS+=-s AGGRESSIVE_VARIABLE_ELIMINATION=1
EM_SCRIPT_OPTIONS+=-s RUNNING_JS_OPTS=1
EM_SCRIPT_OPTIONS+=-s DISABLE_EXCEPTION_CATCHING=1
EM_SCRIPT_OPTIONS+=-s NO_EXIT_RUNTIME=1
EM_SCRIPT_OPTIONS+= -s USE_SDL=0
EM_SCRIPT_OPTIONS+=--memory-init-file 0

CXXFLAGS += ${EM_SCRIPT_OPTIONS}

em-out/flif.html: maniac/*.h maniac/*.cpp image/*.h image/*.cpp transform/*.h transform/*.cpp flif-em.cpp flif-enc.cpp flif-dec.cpp common.cpp flif-enc.h flif-dec.h common.h flif_config.h fileio.h bufferio.h io.h io.cpp Makefile flif-library.js
	${CXX} -std=gnu++11 $(CXXFLAGS) $(LDFLAGS) -DNDEBUG -Oz -g0 -Wall maniac/chance.cpp image/color_range.cpp transform/factory.cpp flif-em.cpp common.cpp flif-dec.cpp io.cpp -o em-out/flif.html

# for running interface-test
export LD_LIBRARY_PATH=$(shell pwd):$LD_LIBRARY_PATH

FILES_H := maniac/*.h maniac/*.cpp image/*.h transform/*.h flif-enc.h flif-dec.h common.h flif_config.h fileio.h io.h io.cpp config.h
FILES_CPP := maniac/chance.cpp image/crc32k.cpp image/image.cpp image/image-png.cpp image/image-pnm.cpp image/image-pam.cpp image/image-rggb.cpp image/color_range.cpp transform/factory.cpp common.cpp flif-enc.cpp flif-dec.cpp io.cpp

flif: $(FILES_H) $(FILES_CPP) flif.cpp
	$(CXX) -std=gnu++11 $(CXXFLAGS) -DNDEBUG -O3 -g0 -Wall $(FILES_CPP) flif.cpp -o flif $(LDFLAGS)

flif.prof: $(FILES_H) $(FILES_CPP) flif.cpp
	$(CXX) -std=gnu++11 $(CXXFLAGS) -DNDEBUG -O3 -g0 -pg -Wall $(FILES_CPP) flif.cpp -o flif.prof $(LDFLAGS)

flif.dbg: $(FILES_H) $(FILES_CPP) flif.cpp
	$(CXX) -std=gnu++11 $(CXXFLAGS) -O0 -ggdb3 -Wall $(FILES_CPP) flif.cpp -o flif.dbg $(LDFLAGS)

libflif.so: $(FILES_H) $(FILES_CPP) flif.h flif-interface-private.h flif-interface.cpp
	$(CXX) -std=gnu++11 $(CXXFLAGS) -DNDEBUG -O3 -g0 -Wall -shared -fPIC $(FILES_CPP) flif-interface.cpp -o libflif.so $(LDFLAGS)

libflifd.so: $(FILES_H) $(FILES_CPP) flif.h flif-interface-private.h flif-interface.cpp
	$(CXX) -std=gnu++11 $(CXXFLAGS) -O0 -ggdb3 -Wall -shared -fPIC $(FILES_CPP) flif-interface.cpp -o libflifd.so $(LDFLAGS)

viewflif: libflif.so flif.h tools/viewer.c
	gcc -O2 -ggdb3 $(shell sdl2-config --cflags) $(shell sdl2-config --libs) -Wall -I. tools/viewer.c -o viewflif -L. -lflif

all: flif libflif.so viewflif

test-interface: libflifd.so flif.h tools/test.c
	gcc -O0 -ggdb3 -Wall -I. tools/test.c -o test-interface -L. -lflifd


test: flif test-interface
	mkdir -p testFiles
	./test-interface
	./tools/test-roundtrip.sh tools/2_webp_ll.png testFiles/2_webp_ll.flif testFiles/decoded_2_webp_ll.png
	./tools/test-roundtrip.sh tools/kodim01.png testFiles/kodim01.flif testFiles/decoded_kodim01.png

