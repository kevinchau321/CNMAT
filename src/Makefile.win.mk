OBJECT_LIST = o.append \
o.atomize \
o.change \
o.collect \
o.cond \
o.context \
o.compose \
o.dict \
o.difference \
o.display \
o.downcast \
o.edge~ \
o.explode \
o.expr \
o.expr.codebox \
o.flatten \
o.if \
o.intersection \
o.listenumerate \
o.mappatch \
o.message \
o.messageiterate \
o.pack \
o.pak \
o.prepend \
o.print \
o.printbytes \
o.route \
o.schedule \
o.select \
o.slip.decode \
o.slip.encode \
o.table \
o.timetag \
o.union \
o.unless \
o.validate \
o.var \
o.when

#OBJECT_LIST = o.append o.message

PATCHDIRS = help demos abstractions deprecated overview
TEXTFILES = README_ODOT.txt

VPATH = $(OBJECT_LIST)

CFILES = $(foreach f, $(OBJECT_LIST), $(f)/$(f).c)

C74SUPPORT = ../../max6-sdk/c74support
MAX_INCLUDES = $(C74SUPPORT)/max-includes
MSP_INCLUDES = $(C74SUPPORT)/msp-includes

PLATFORM = Windows

EXT = .mxe
CC = i686-w64-mingw32-gcc
#CC = gcc
#LD = i686-w64-mingw32-ld
#LD = gcc
LD = $(CC)
CFLAGS += -mno-cygwin -DWIN_VERSION -DWIN_EXT_VERSION -U__STRICT_ANSI__ -U__ANSI_SOURCE -std=c99 -O3 -DNO_TRANSLATION_SUPPORT
INCLUDES = -I$(MAX_INCLUDES) -I$(MSP_INCLUDES) -I../../libo -I../../libomax -Iinclude
LDFLAGS = -mno-cygwin -shared #-static-libgcc
#LIBS = -L"/cygdrive/c/Program Files (x86)/Microsoft Visual Studio 10.0/VC/lib" -lmsvcrt -L../../libomax -lomax -L$(MAX_INCLUDES) -lMaxAPI -L../../libo -lo 
LIBS = -L../../libomax -lomax -L$(MAX_INCLUDES) -L$(MSP_INCLUDES) -lMaxAPI -lMaxAudio -L../../libo -lo 

BUILDDIR = $(CURDIR)/build/Release
STAGINGDIR = odot-$(PLATFORM)

OBJECTS = $(addsuffix $(EXT), $(addprefix $(BUILDDIR)/, $(OBJECT_LIST)))
STAGED_OBJECTS = $(addprefix $(STAGINGDIR)/objects/, $(notdir $(OBJECTS)))
STAGED_PATCHES = $(addprefix $(STAGINGDIR)/, $(PATCHDIRS))
STAGED_TEXTFILES = $(addprefix $(STAGINGDIR)/, $(TEXTFILES))
STAGED_PRODUCTS = $(STAGED_PATCHES) $(STAGED_OBJECTS) $(STAGED_TEXTFILES)

CURRENT_VERSION_FILE = include/odot_current_version.h

ARCHIVE = odot-$(strip $(PLATFORM)).tgz

ifeq ($(strip $(CNMAT_MAX_INSTALL_DIR)),)
	LOCAL_INSTALL_PATH = ~/odot
else
	LOCAL_INSTALL_PATH = $(CNMAT_MAX_INSTALL_DIR)/odot
endif

INSTALLED_PRODUCTS = $(addprefix $(LOCAL_INSTALL_PATH)/, $(PATCHDIRS) $(TEXTFILES) objects)
DIRS = $(BUILDDIR) $(STAGINGDIR) $(LOCAL_INSTALL_PATH)

SERVER = cnmat.berkeley.edu
SERVER_PATH = /home/www-data/berkeley.edu-cnmat.www/maxdl/files/odot

##################################################
## Windows specific
##################################################
all: $(BUILDDIR)/commonsyms.o $(OBJECTS)

$(BUILDDIR)/commonsyms.o: $(BUILDDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/commonsyms.o $(MAX_INCLUDES)/common/commonsyms.c

$(BUILDDIR)/pqops.o: $(BUILDDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -Io.schedule -c -o $(BUILDDIR)/pqops.o o.schedule/pqops.c

$(BUILDDIR)/%.mxe: %.c $(BUILDDIR) $(BUILDDIR)/commonsyms.o $(BUILDDIR)/pqops.o $(CURRENT_VERSION_FILE)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/$*.o $<
	$(LD) $(LDFLAGS) -o $(BUILDDIR)/$*.mxe $(BUILDDIR)/$*.o $(BUILDDIR)/commonsyms.o $(BUILDDIR)/pqops.o $(LIBS)

# $(BUILDDIR)/o.append.mxe: o.append.c $(BUILDDIR) $(BUILDDIR)/commonsyms.o $(CURRENT_VERSION_FILE)
# 	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/o.append.o $<
# 	$(LD) $(LDFLAGS) -o $(BUILDDIR)/o.append.mxe $(BUILDDIR)/o.append.o $(BUILDDIR)/commonsyms.o $(LIBS) 

# $(BUILDDIR)/o.message.mxe: o.message.c $(BUILDDIR) $(BUILDDIR)/commonsyms.o $(CURRENT_VERSION_FILE)
# 	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/o.message.o $<
# 	$(LD) $(LDFLAGS) -o $(BUILDDIR)/o.message.mxe $(BUILDDIR)/o.message.o $(BUILDDIR)/commonsyms.o $(LIBS) 

##################################################
## platform agnostic targets
##################################################

# executed to statisfy the $(STAGED_OBJECTS) dependancy
$(STAGINGDIR)/objects/%$(EXT): $(OBJECTS) $(STAGINGDIR) $(STAGINGDIR)/objects
	cp -r $(BUILDDIR)/$*$(EXT) $(STAGINGDIR)/objects

# executed to statisfy the $(STAGED_PATCHES) and $(STAGED_TEXTFILES) dependancies
$(STAGINGDIR)/%: $(STAGINGDIR)
	rsync -avq --exclude=*/.* $* $(STAGINGDIR)

.PHONY: install
install: $(DIRS) $(OBJECTS) $(STAGED_PRODUCTS) $(INSTALLED_PRODUCTS)

# executed to satisfy the $(INSTALLED_PRODUCTS) dependancy
$(LOCAL_INSTALL_PATH)/%: $(LOCAL_INSTALL_DIR)
	cp -r $(STAGINGDIR)/$* $(LOCAL_INSTALL_PATH)

.PHONY: release
release: $(DIRS) $(OBJECTS) $(ARCHIVE)
	scp $(ARCHIVE) $(SERVER):$(SERVER_PATH)/$(ARCHIVE)

$(ARCHIVE): $(STAGED_PRODUCTS)
	tar zvcf $(ARCHIVE) $(STAGINGDIR)

.PHONY: clean
clean: 
	rm -rf build
	rm -rf $(STAGINGDIR)
	rm -rf $(ARCHIVE)
	rm -rf $(LOCAL_INSTALL_PATH)
	rm -f $(CURRENT_VERSION_FILE)

##################################################
## create directories
##################################################
$(BUILDDIR):
	[ -d $(BUILDDIR) ] || mkdir -p $(BUILDDIR)

$(STAGINGDIR):
	[ -d $(STAGINGDIR) ] || mkdir -p $(STAGINGDIR)

$(STAGINGDIR)/objects: $(STAGINGDIR)
	[ -d $(STAGINGDIR)/objects ] || mkdir -p $(STAGINGDIR)/objects

$(LOCAL_INSTALL_PATH):
	[ -d $(LOCAL_INSTALL_PATH) ] || mkdir -p $(LOCAL_INSTALL_PATH)

$(INSTALLDIR)/objects: $(INSTALLDIR) $(RELEASEDIR)
	cp -r $(RELEASEDIR)/* $(INSTALLDIR)

$(CURRENT_VERSION_FILE):
	echo "#define ODOT_VERSION \""`git describe --tags --long`"\"" > $(CURRENT_VERSION_FILE)
	echo "#define ODOT_COMPILE_DATE \""`date`"\""  >> $(CURRENT_VERSION_FILE)
