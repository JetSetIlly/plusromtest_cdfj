###############################################################################
# File: Makefile
# Description: CDFJ Test Makefile
# (C) Copyright 2017 - Chris Walton, Fred Quimby, Darrell Spice Jr
###############################################################################

PROJECT=collect3
DASM_TO_C=defines_from_dasm_for_c.h

# If desired, the following color values can be changed.   
# 30=black  31=red      32=green    33=yellow
# 34=blue   35=purple   36=cyan     37=white
INFO_COLOR='\033[1;34m'     #default 34=blue
OPTION_COLOR='\033[0;32m'   #default 32=green
PROMPT_COLOR='\033[0;37m'   #default 37=white
ERROR_COLOR='\033[0;31m'    #defualt 31=red

# do not change this
DEFAULT_COLOR='\033[0m'

# Tool names
#TOOLCHAIN=arm-elf
TOOLCHAIN=arm-none-eabi
# TOOLCHAIN=arm-eabi
CC=$(TOOLCHAIN)-gcc
AS=$(TOOLCHAIN)-as
LD=$(TOOLCHAIN)-ld
OBJCOPY=$(TOOLCHAIN)-objcopy
SIZE=$(TOOLCHAIN)-size

# Dirs
BASE = main
SRC = $(BASE)/custom
BIN = $(BASE)/bin

# C Compiler flags
OPTIMIZATION = -Os 
CFLAGS = -mcpu=arm7tdmi -march=armv4t -mthumb # -mthumb-interwork
CFLAGS += -Wall -ffunction-sections # -save-temps #-mlong-calls 
CFLAGS += $(OPTIMIZATION) $(INCLUDES)
CFLAGS += -Wl,--build-id=none

# Search path
VPATH += $(BASE):$(SRC)

# Default target
default: armcode

armcode_defines:
	@echo -e $(INFO_COLOR)
	@echo "Step 1/3 - Create $(DASM_TO_C)"  
	@echo -e $(OPTION_COLOR)
	dasm $(PROJECT).asm -f3 -v0 -s$(PROJECT).sym -l$(PROJECT).lst -o$(PROJECT).bin
    # > creates/overwrites file
    # >> appends to existing file, creates file if nonexistant
	@echo "// Do not change this file. It is auto-generated during the make process" > main/$(DASM_TO_C)
	awk '$$0 ~ /^_/ {printf "#define %-25s 0x%s\n", $$1, $$2}' $(PROJECT).sym >> main/$(DASM_TO_C)
	
	@echo -e $(INFO_COLOR)
	@echo "Step 2/3 - Create ARM BIN"
	@echo -e $(OPTION_COLOR)
	
armcode_atari:
	dasm $(PROJECT).asm -f3 -v0 -s$(PROJECT).sym -l$(PROJECT).lst -o$(PROJECT).bin

armcode_list:
	@echo -e $(INFO_COLOR)
	@echo "Step 3/3 - Create BIN"
	@echo -e $(OPTION_COLOR)
	dasm $(PROJECT).asm -f3 -o$(PROJECT).bin -l$(PROJECT).lst -s$(PROJECT).sym
	@echo -e $(DEFAULT_COLOR)
	
armcode: armcode_defines armcode_arm armcode_list

flash:
	lpc21isp -bin -wipe -verify -control -controlswap $(PROJECT).bin /dev/ttyUSB0 38400 10000

############################# CUSTOM C ##############################

CUSTOMNAME = armcode
CUSTOMELF = $(BIN)/$(CUSTOMNAME).elf
CUSTOMBIN = $(BIN)/$(CUSTOMNAME).bin
CUSTOMMAP = $(BIN)/$(CUSTOMNAME).map
CUSTOMLST = $(BIN)/$(CUSTOMNAME).lst
CUSTOMLINK = $(SRC)/custom.boot.lds
CUSTOMOBJS = custom.o main.o
CUSTOMTARGETS = $(CUSTOMELF) $(CUSTOMBIN)

main.o : $(DASM_TO_C) #defines.h

armcode_arm: $(CUSTOMTARGETS)
	@ls -l $(CUSTOMBIN)

$(CUSTOMELF): $(CUSTOMOBJS) Makefile
	$(CC) $(CFLAGS) -o $(CUSTOMELF) $(CUSTOMOBJS) -T $(CUSTOMLINK) -nostartfiles -Wl,-Map=$(CUSTOMMAP),--gc-sections 
$(CUSTOMBIN): $(CUSTOMELF)
	$(OBJCOPY) -O binary -S $(CUSTOMELF) $(CUSTOMBIN)
	$(SIZE) $(CUSTOMOBJS) $(CUSTOMELF)

############################# CLEAN PROJECT ###################################

clean:
	rm -f *.o *.i *.s $(BIN)/*.* $(PROJECT).bin $(PROJECT).lst $(PROJECT).sym

