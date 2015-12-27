MAIN_MAKEFILE=1
include config.mak

vpath %.c    $(SRC_PATH)
vpath %.cpp  $(SRC_PATH)
vpath %.h    $(SRC_PATH)
vpath %.m    $(SRC_PATH)
vpath %.S    $(SRC_PATH)
vpath %.asm  $(SRC_PATH)
vpath %.rc   $(SRC_PATH)
vpath %.v    $(SRC_PATH)
vpath %.texi $(SRC_PATH)
vpath %/fate_config.sh.template $(SRC_PATH)

TESTTOOLS   = audiogen videogen rotozoom tiny_psnr tiny_ssim base64
HOSTPROGS  := $(TESTTOOLS:%=tests/%) doc/print_options
TOOLS       = qt-faststart trasher uncoded_frame
TOOLS-$(CONFIG_ZLIB) += cws2fws

# $(FFLIBS-yes) needs to be in linking order
FFLIBS-$(CONFIG_AVDEVICE)   += avdevice
FFLIBS-$(CONFIG_AVFILTER)   += avfilter
FFLIBS-$(CONFIG_AVFORMAT)   += avformat
FFLIBS-$(CONFIG_AVCODEC)    += avcodec
FFLIBS-$(CONFIG_AVRESAMPLE) += avresample
FFLIBS-$(CONFIG_POSTPROC)   += postproc
FFLIBS-$(CONFIG_SWRESAMPLE) += swresample
FFLIBS-$(CONFIG_SWSCALE)    += swscale
FFLIBS-$(CONFIG_FFMPEG)    += ffmpeg

FFLIBS := avutil

DATA_FILES := $(wildcard $(SRC_PATH)/presets/*.ffpreset) $(SRC_PATH)/doc/ffprobe.xsd
EXAMPLES_FILES := $(wildcard $(SRC_PATH)/doc/examples/*.c) $(SRC_PATH)/doc/examples/Makefile $(SRC_PATH)/doc/examples/README

SKIPHEADERS = cmdutils_common_opts.h compat/w32pthreads.h

include $(SRC_PATH)/common.mak

FF_EXTRALIBS := $(FFEXTRALIBS)
FF_DEP_LIBS  := $(DEP_LIBS)
FF_STATIC_DEP_LIBS := $(STATIC_DEP_LIBS)

$(TOOLS): %$(EXESUF): %.o $(EXEOBJS)
	$(LD) $(LDFLAGS) $(LDEXEFLAGS) $(LD_O) $^ $(ELIBS)

tools/cws2fws$(EXESUF): ELIBS = $(ZLIB)
tools/uncoded_frame$(EXESUF): $(FF_DEP_LIBS)
tools/uncoded_frame$(EXESUF): ELIBS = $(FF_EXTRALIBS)

config.h: .config
.config: $(wildcard $(FFLIBS:%=$(SRC_PATH)/lib%/all*.c))
	@-tput bold 2>/dev/null
	@-printf '\nWARNING: $(?F) newer than config.h, rerun configure\n\n'
	@-tput sgr0 2>/dev/null

SUBDIR_VARS := CLEANFILES EXAMPLES FFLIBS HOSTPROGS TESTPROGS TOOLS      \
               HEADERS ARCH_HEADERS BUILT_HEADERS SKIPHEADERS            \
               ARMV5TE-OBJS ARMV6-OBJS ARMV8-OBJS VFP-OBJS NEON-OBJS     \
               ALTIVEC-OBJS MMX-OBJS YASM-OBJS                           \
               MIPSFPU-OBJS MIPSDSPR2-OBJS MIPSDSPR1-OBJS MSA-OBJS       \
               MMI-OBJS OBJS SLIBOBJS HOSTOBJS TESTOBJS

define RESET
$(1) :=
$(1)-yes :=
endef

define DOSUBDIR
$(foreach V,$(SUBDIR_VARS),$(eval $(call RESET,$(V))))
SUBDIR := $(1)/
include $(SRC_PATH)/$(1)/Makefile
-include $(SRC_PATH)/$(1)/$(ARCH)/Makefile
-include $(SRC_PATH)/$(1)/$(INTRINSICS)/Makefile
include $(SRC_PATH)/library.mak
endef

$(foreach D,$(FFLIBS),$(eval $(call DOSUBDIR,lib$(D))))

include $(SRC_PATH)/doc/Makefile

ffprobe.o cmdutils.o libavcodec/utils.o libavformat/utils.o libavdevice/avdevice.o libavfilter/avfilter.o libavutil/utils.o libpostproc/postprocess.o libswresample/swresample.o libswscale/utils.o : libavutil/ffversion.h

OBJDIRS += tools

-include $(wildcard tools/*.d)

VERSION_SH  = $(SRC_PATH)/version.sh
GIT_LOG     = $(SRC_PATH)/.git/logs/HEAD

.version: $(wildcard $(GIT_LOG)) $(VERSION_SH) config.mak
.version: M=@

libavutil/ffversion.h .version:
	$(M)$(VERSION_SH) $(SRC_PATH) libavutil/ffversion.h $(EXTRA_VERSION)
	$(Q)touch .version

# force version.sh to run whenever version might have changed
-include .version

install: install-libs install-headers

install-libs: install-libs-yes

install-progs-yes:
install-progs-$(CONFIG_SHARED): install-libs

install-progs: install-progs-yes $(AVPROGS)
	$(Q)mkdir -p "$(BINDIR)"
	$(INSTALL) -c -m 755 $(INSTPROGS) "$(BINDIR)"

install-data: $(DATA_FILES) $(EXAMPLES_FILES)
	$(Q)mkdir -p "$(DATADIR)/examples"
	$(INSTALL) -m 644 $(DATA_FILES) "$(DATADIR)"
	$(INSTALL) -m 644 $(EXAMPLES_FILES) "$(DATADIR)/examples"

uninstall: uninstall-libs uninstall-headers uninstall-progs uninstall-data

uninstall-progs:
	$(RM) $(addprefix "$(BINDIR)/", $(ALLAVPROGS))

uninstall-data:
	$(RM) -r "$(DATADIR)"

clean::
	$(RM) $(ALLAVPROGS) $(ALLAVPROGS_G)
	$(RM) $(CLEANSUFFIXES)
	$(RM) $(CLEANSUFFIXES:%=tools/%)
	$(RM) -r coverage-html
	$(RM) -rf coverage.info lcov

distclean::
	$(RM) $(DISTCLEANSUFFIXES)
	$(RM) config.* .config libavutil/avconfig.h .version avversion.h version.h libavutil/ffversion.h libavcodec/codec_names.h

config:
	$(SRC_PATH)/configure $(value FFMPEG_CONFIGURATION)

check: all alltools examples testprogs fate

include $(SRC_PATH)/tests/Makefile

$(sort $(OBJDIRS)):
	$(Q)mkdir -p $@

# Dummy rule to stop make trying to rebuild removed or renamed headers
%.h:
	@:

# Disable suffix rules.  Most of the builtin rules are suffix rules,
# so this saves some time on slow systems.
.SUFFIXES:

.PHONY: all all-yes alltools check *clean config install*
.PHONY: testprogs uninstall*
