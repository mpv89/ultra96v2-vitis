SRC_URI += "file://kernel.cfg"
            
SRC_URI_append = " file://fix_u96v2_pwrseq_simple.patch"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"
