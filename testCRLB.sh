#!/bin/bash
RootDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/
PATH="$RootDir/bin:$PATH"
set -ex
# Phantom generation
# install -d Result.$$
estimate_crlb --funcfile data/func_expression_diffT2_1.txt --outprefix Result/CRLB_values
