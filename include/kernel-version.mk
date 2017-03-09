# Use the default kernel version if the Makefile doesn't override it

LINUX_RELEASE?=1

LINUX_VERSION-3.18 = .20
LINUX_VERSION-4.0 = .9
LINUX_VERSION-4.1 = .25
LINUX_VERSION-4.3 = -rc5

LINUX_KERNEL_MD5SUM-3.18.20 = 952c9159acdf4efbc96e08a27109d994
LINUX_KERNEL_MD5SUM-4.0.9 = 40fc5f6e2d718e539b45e6601c71985b
LINUX_KERNEL_MD5SUM-4.1.10 = 16953359a8c245d478294af65fd756a8
LINUX_KERNEL_MD5SUM-4.3-rc5 = 3f8f158a3a06c97464d891d84e5e45f3

ifdef KERNEL_PATCHVER
  LINUX_VERSION:=$(KERNEL_PATCHVER)$(strip $(LINUX_VERSION-$(KERNEL_PATCHVER)))
endif

split_version=$(subst ., ,$(1))
merge_version=$(subst $(space),.,$(1))
KERNEL_BASE=$(firstword $(subst -, ,$(LINUX_VERSION)))
KERNEL=$(call merge_version,$(wordlist 1,2,$(call split_version,$(KERNEL_BASE))))
KERNEL_PATCHVER ?= $(KERNEL)

# disable the md5sum check for unknown kernel versions
LINUX_KERNEL_MD5SUM:=$(LINUX_KERNEL_MD5SUM-$(strip $(LINUX_VERSION)))
LINUX_KERNEL_MD5SUM?=x
