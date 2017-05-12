#!/bin/bash -f
xv_path="/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xsim axi_test_tb_behav -key {Behavioral:sim_1:Functional:axi_test_tb} -tclbatch axi_test_tb.tcl -log simulate.log
