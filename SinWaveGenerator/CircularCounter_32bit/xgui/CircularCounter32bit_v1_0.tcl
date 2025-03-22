# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DIRECTION" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "END_VAL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "START_VAL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.DIRECTION { PARAM_VALUE.DIRECTION } {
	# Procedure called to update DIRECTION when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIRECTION { PARAM_VALUE.DIRECTION } {
	# Procedure called to validate DIRECTION
	return true
}

proc update_PARAM_VALUE.END_VAL { PARAM_VALUE.END_VAL } {
	# Procedure called to update END_VAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.END_VAL { PARAM_VALUE.END_VAL } {
	# Procedure called to validate END_VAL
	return true
}

proc update_PARAM_VALUE.START_VAL { PARAM_VALUE.START_VAL } {
	# Procedure called to update START_VAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.START_VAL { PARAM_VALUE.START_VAL } {
	# Procedure called to validate START_VAL
	return true
}

proc update_PARAM_VALUE.WIDTH { PARAM_VALUE.WIDTH } {
	# Procedure called to update WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WIDTH { PARAM_VALUE.WIDTH } {
	# Procedure called to validate WIDTH
	return true
}


proc update_MODELPARAM_VALUE.WIDTH { MODELPARAM_VALUE.WIDTH PARAM_VALUE.WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WIDTH}] ${MODELPARAM_VALUE.WIDTH}
}

proc update_MODELPARAM_VALUE.START_VAL { MODELPARAM_VALUE.START_VAL PARAM_VALUE.START_VAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.START_VAL}] ${MODELPARAM_VALUE.START_VAL}
}

proc update_MODELPARAM_VALUE.END_VAL { MODELPARAM_VALUE.END_VAL PARAM_VALUE.END_VAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.END_VAL}] ${MODELPARAM_VALUE.END_VAL}
}

proc update_MODELPARAM_VALUE.DIRECTION { MODELPARAM_VALUE.DIRECTION PARAM_VALUE.DIRECTION } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIRECTION}] ${MODELPARAM_VALUE.DIRECTION}
}

