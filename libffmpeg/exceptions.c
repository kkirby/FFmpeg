#include "exceptions.h"

const e4c_exception_type ExitedNormally = {
	"ExitedNormally",
	"FFmpeg exited normally.",
	&RuntimeException
};
const e4c_exception_type ExitedAbnormally = {
	"ExitedAbnormally",
	"FFmpeg exited abnormally.",
	&RuntimeException
};
