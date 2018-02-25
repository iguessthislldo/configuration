function _testd {
    mkdir /tmp/$1
    cd /tmp/$1
}
alias testd="_testd $(uuidgen)"
