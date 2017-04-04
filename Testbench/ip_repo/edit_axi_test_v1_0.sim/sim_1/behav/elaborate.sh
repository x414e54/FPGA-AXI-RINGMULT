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
ExecStep $xv_path/bin/xelab -wto 7c673c480fb14c6b86aa198bd7bd0ddf -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot axi_test_tb_behav xil_defaultlib.axi_test_tb -log elaborate.log
