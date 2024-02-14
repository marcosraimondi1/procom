# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMAGE_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "KERNEL_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NB_COEFF" -parent ${Page_0}
  ipgui::add_param $IPINST -name "NB_PIXEL" -parent ${Page_0}


}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to update IMAGE_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to validate IMAGE_HEIGHT
	return true
}

proc update_PARAM_VALUE.KERNEL_WIDTH { PARAM_VALUE.KERNEL_WIDTH } {
	# Procedure called to update KERNEL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.KERNEL_WIDTH { PARAM_VALUE.KERNEL_WIDTH } {
	# Procedure called to validate KERNEL_WIDTH
	return true
}

proc update_PARAM_VALUE.NB_COEFF { PARAM_VALUE.NB_COEFF } {
	# Procedure called to update NB_COEFF when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NB_COEFF { PARAM_VALUE.NB_COEFF } {
	# Procedure called to validate NB_COEFF
	return true
}

proc update_PARAM_VALUE.NB_PIXEL { PARAM_VALUE.NB_PIXEL } {
	# Procedure called to update NB_PIXEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NB_PIXEL { PARAM_VALUE.NB_PIXEL } {
	# Procedure called to validate NB_PIXEL
	return true
}


proc update_MODELPARAM_VALUE.IMAGE_HEIGHT { MODELPARAM_VALUE.IMAGE_HEIGHT PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMAGE_HEIGHT}] ${MODELPARAM_VALUE.IMAGE_HEIGHT}
}

proc update_MODELPARAM_VALUE.KERNEL_WIDTH { MODELPARAM_VALUE.KERNEL_WIDTH PARAM_VALUE.KERNEL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.KERNEL_WIDTH}] ${MODELPARAM_VALUE.KERNEL_WIDTH}
}

proc update_MODELPARAM_VALUE.NB_PIXEL { MODELPARAM_VALUE.NB_PIXEL PARAM_VALUE.NB_PIXEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NB_PIXEL}] ${MODELPARAM_VALUE.NB_PIXEL}
}

proc update_MODELPARAM_VALUE.NB_COEFF { MODELPARAM_VALUE.NB_COEFF PARAM_VALUE.NB_COEFF } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NB_COEFF}] ${MODELPARAM_VALUE.NB_COEFF}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

