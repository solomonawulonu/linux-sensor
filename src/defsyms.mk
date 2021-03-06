#
# Copyright (C) 2011 Battelle Memorial Institute
# Copyright (C) 2016 Google Inc.
#
# Licensed under the GNU General Public License Version 2.
# See LICENSE for the full text of the license.
# See DISCLAIMER for additional disclaimers.
# 
# Author: Brandon Carpenter
#

defsyms-names := $(foreach N,$(basename $(obj-m) $(obj-c)),$(if $(filter file,$(origin $N-defsyms)),$N))

ifneq ($(defsyms-names),)

# Should check if defsyms are in Module.symvers before getting an address.
# It would be nice to use modpost.
# SYMVERS ?= $(or $(realpath $(CURDIR)/Module.symvers), $(src)/Module.symvers)

SYSMAP ?= $(or $(realpath $(CURDIR)/System.map), \
	$(realpath /boot/System.map-$(KERNELRELEASE)), \
	$(realpath /lib/modules/$(KERNELRELEASE)/build/System.map), \
	$(realpath $(src)/System.map))
SYSMAP := $(SYSMAP)

# Hack to replace space character in cmd_defsyms
SP :=
SP +=

quiet_cmd_defsyms = DEFSYMS $@
cmd_defsyms = SYMBOLS="$(subst $(SP),|,$(strip $($*-defsyms) $(foreach N,$(patsubst %.o,%-defsyms,$($*-y)),$(value $N))))" && [ -n "$$SYMBOLS" ] && awk '$$3 ~ /^('"$$SYMBOLS"')(.[a-z]+.[0-9]+)?$$/ {gsub(".[a-z]+.[0-9]+$$", "", $$3); print $$3 " = 0x" $$1 ";"}' $(SYSMAP) > $@ || echo "$$SYMBOLS" > $@
quiet_cmd_md5 = MD5SUM  $3
cmd_md5 = md5sum $2 > $3
quiet_cmd_symvers = SYMVERS $@
cmd_symvers = sed -r 's/^\s*(\w+)\s*=\s*0x\S*(\S{8})\s*;\s*$$/0x\2\t\1\tvmlinux/;t;d' $(defsyms-lds) > $@

defsyms-roots := $(addprefix $(obj)/,$(defsyms-names))
defsyms-obj := $(addsuffix .o,$(defsyms-roots))
defsyms-m := $(addsuffix .ko,$(defsyms-roots))
defsyms-lds := $(addsuffix .defsyms,$(defsyms-roots))
clean-files += $(defsyms-m) $(defsyms-lds) .System.map.md5 defsyms.symvers

ifeq ($(SYSMAP),)
$(obj)/.System.map.md5: FORCE
	$(error System.map not found.  Try setting the SYSMAP variable to the full path of System.map.  If needed, a System.map file can be generated using nm (e.g. nm /lib/modules/`uname -r`/build/vmlinux > System.map))
else
$(obj)/.System.map.md5: $(shell [ -f $(obj)/.System.map.md5 ] && md5sum $(SYSMAP) | cmp $(obj)/.System.map.md5 -s - || echo FORCE)
	$(call cmd,md5,$(SYSMAP),$@)
endif

$(defsyms-obj): $(obj)/defsyms.symvers

$(obj)/defsyms.symvers: $(defsyms-lds)
	$(call cmd,symvers)

KBUILD_EXTRA_SYMBOLS += $(obj)/defsyms.symvers
LDFLAGS_MODULE += $(DEFSYMS_LDFLAGS_$(notdir $@))

$(foreach N,$(defsyms-names),$(eval DEFSYMS_LDFLAGS_$(N).ko = -T $(obj)/$(N).defsyms))

$(defsyms-lds): $(obj)/%.defsyms: $(obj)/.System.map.md5
	$(call cmd,defsyms)

endif
