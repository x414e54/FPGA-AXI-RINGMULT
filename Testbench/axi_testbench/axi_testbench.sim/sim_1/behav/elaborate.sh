#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2016.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 20066dddc2f34fff994a30bba82af72d -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot tb_crt_behav xil_defaultlib.tb_crt -log elaborate.log
