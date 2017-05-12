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
echo "xvhdl -m64 --relax -prj axi_test_tb_vhdl.prj"
ExecStep $xv_path/bin/xvhdl -m64 --relax -prj axi_test_tb_vhdl.prj 2>&1 | tee -a compile.log
