include $(SUBDIR)../config.mak

NAME = ffmpeg

HEADERS = ffmpeg.h

ifdef HAVE_PTHREADS
CFLAGS += -DE4C_THREADSAFE
ifndef HAVE_PTHREAD_CANCEL
CFLAGS += -DMISSING_PTHREAD_CANCEL
endif
endif

CFLAGS += -DE4C_NOKEYWORDS

#LDLIBFLAGS = \
#	-Llibavcodec -Llibavfilter -Llibavformat -Llibswresample \
#	-lavcodec -lavfilter -lavformat -lswresample

OBJS                   += ffmpeg.o ffmpeg_opt.o ffmpeg_filter.o e4c.o cmdutils.o exceptions.o
OBJS-$(HAVE_VDPAU_X11) += ffmpeg_vdpau.o
OBJS-$(HAVE_DXVA2_LIB) += ffmpeg_dxva2.o
OBJS-$(CONFIG_OPENCL) += cmdutils_opencl.o
ifndef CONFIG_VIDEOTOOLBOX
OBJS-$(CONFIG_VDA)     += ffmpeg_videotoolbox.o
endif
OBJS-$(CONFIG_VIDEOTOOLBOX) += ffmpeg_videotoolbox.o
OBJS-$(CONFIG_LIBMFX)  += ffmpeg_qsv.o
