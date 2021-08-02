workspace="%dest%"
if %oci_tao%
then
    ace_tao_dir_name=ocitao
else
    ace_tao_dir_name=ACE_TAO
fi
export ACE_ROOT=${workspace}/${ace_tao_dir_name}/ACE
export TAO_ROOT=${workspace}/${ace_tao_dir_name}/TAO
export MPC_ROOT="%mpc%"

export LD_LIBRARY_PATH=$ACE_ROOT/lib:${LD_LIBRARY_PATH}
export PATH=:$ACE_ROOT/bin:${PATH}
