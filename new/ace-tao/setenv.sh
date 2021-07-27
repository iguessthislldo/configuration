workspace="%dest%"
export ACE_ROOT=${workspace}/ACE_TAO/ACE
export TAO_ROOT=${workspace}/ACE_TAO/TAO
export MPC_ROOT="%mpc%"

export LD_LIBRARY_PATH=$ACE_ROOT/lib:${LD_LIBRARY_PATH}
export PATH=:$ACE_ROOT/bin:${PATH}
