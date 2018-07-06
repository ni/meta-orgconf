require recipes-core/images/restore-mode-image.inc

# don't have a FACTORY_IMAGE (yet) so don't do FACTORY_IMAGE = "safemode-image" here;
# maybe in the future we'll find time to refactor the safemode-image.bb to behave like
# a normal restore-mode payload and just do FACTORY_IMAGE = "safemode-image" instead
ROOTFS_POSTPROCESS_COMMAND_remove = "install_payload;"

PACKAGE_INSTALL += "safemode-image"
