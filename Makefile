RPATH = /usr/local/gpstall/lib/
LFLAGS = -Wl,-rpath=$(RPATH)

UNAME := $(shell if [ -f "/etc/redhat-release" ]; then echo "CentOS"; else echo "Ubuntu"; fi)

ifeq ($(UNAME), CentOS)
OSVERSION := $(shell cat /etc/redhat-release | cut -d "." -f 1 | awk '{print $$NF}')
endif

ifeq ($(UNAME), Ubuntu)
  $(shell mkdir -p $(CURDIR)/lib/ubuntu)
  SO_PATH = $(CURDIR)/lib/ubuntu
else ifeq ($(OSVERSION), 5)
  $(shell mkdir -p $(CURDIR)/lib/5.4)
  SO_PATH = $(CURDIR)/lib/5.4
else
  $(shell mkdir -p $(CURDIR)/lib/6.2)
  SO_PATH = $(CURDIR)/lib/6.2
endif

CXX = g++

ifeq ($(__REL), 1)
#CXXFLAGS = -Wall -W -DDEBUG -g -O0 -D__XDEBUG__ -fPIC -Wno-unused-function -std=c++11
	CXXFLAGS = -O2 -g -pipe -fPIC -W -DNDEBUG -Wwrite-strings -Wpointer-arith -Wreorder -Wswitch -Wsign-promo -Wredundant-decls -Wformat -Wall -Wno-unused-parameter -D_GNU_SOURCE -D__STDC_FORMAT_MACROS -std=c++11 -gdwarf-2 -Wno-redundant-decls
else
	CXXFLAGS = -O0 -g -gstabs+ -pg -pipe -fPIC -W -D__XDEBUG__ -DDEBUG -Wwrite-strings -Wpointer-arith -Wreorder -Wswitch -Wsign-promo -Wredundant-decls -Wformat -Wall -Wno-unused-parameter -D_GNU_SOURCE -D__STDC_FORMAT_MACROS -std=c++11 -Wno-redundant-decls
endif

SRC_PATH = ./src/
THIRD_PATH = ./third
SCRIPT_PATH = ./script
OUTPUT = ./output


SRC = $(wildcard $(SRC_PATH)/*.cc)
OBJS = $(patsubst %.cc,%.o,$(SRC))

BIN = gpstall 


INCLUDE_PATH = -I./include/ \
							 -I$(THIRD_PATH)/glog/src/ \
							 -I$(THIRD_PATH)/slash/output/include/ \
							 -I$(THIRD_PATH)/pink/output/ \
							 -I$(THIRD_PATH)/pink/output/include


LIB_PATH = -L./ \
		   -L$(THIRD_PATH)/slash/output/lib/ \
		   -L$(THIRD_PATH)/pink/output/lib/ \
		   -L$(THIRD_PATH)/glog/.libs/


LIBS = -lpthread \
	   -lglog \
	   -lslash \
		 -lpink

GLOG = $(THIRD_PATH)/glog/.libs/libglog.so.0
PINK = $(THIRD_PATH)/pink/output/lib/libpink.a
SLASH = $(THIRD_PATH)/slash/output/lib/libslash.a

.PHONY: all clean


all: $(BIN)
	@echo "OBJS: $(OBJS)"
	rm -rf $(OUTPUT)
	mkdir $(OUTPUT)
	mkdir $(OUTPUT)/bin
	cp -r ./conf $(OUTPUT)
	mkdir $(OUTPUT)/lib
	cp -r $(SO_PATH)/*  $(OUTPUT)/lib
	mv $(BIN) $(OUTPUT)/bin/
	cp $(SCRIPT_PATH)/load.sh $(OUTPUT)/bin/
	cp $(SCRIPT_PATH)/gpload.yaml.ori $(OUTPUT)/bin/
	cp $(SCRIPT_PATH)/gpload.py $(OUTPUT)/bin/
	#cp $(SCRIPT_PATH)/* $(OUTPUT)/bin/
	#mkdir $(OUTPUT)/tools
	@echo "Success, go, go, go..."


$(BIN): $(GLOG) $(PINK) $(SLASH) $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(INCLUDE_PATH) $(LIB_PATH) $(LFLAGS) $(LIBS) 

$(OBJS): %.o : %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDE_PATH) -c $< -o $@  

$(SLASH):
	make -C $(THIRD_PATH)/slash/

$(PINK):
	make -C $(THIRD_PATH)/pink/

$(GLOG):
	#if [ -d $(THIRD_PATH)/glog/.libs ]; then 
	if [ ! -f $(GLOG) ]; then \
		cd $(THIRD_PATH)/glog; \
		autoreconf -ivf; ./configure; make; echo '*' > $(CURDIR)/third/glog/.gitignore; cp $(CURDIR)/third/glog/.libs/libglog.so.0 $(SO_PATH); \
	fi; 
	
clean: 
	#rm -rf lib/
	rm -rf $(SRC_PATH)/*.o
	rm -rf $(OUTPUT)
