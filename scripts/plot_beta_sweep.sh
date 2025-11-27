#!/bin/bash
EXEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)" ;
export EXEDIR;
Program=$(basename ${BASH_SOURCE[0]})
CompiledMATLABProgram=${Program%.sh}
MATLABRelease=R2024b
MATLABVersNum=24.2

if [[ "$OSTYPE" == "darwin"* ]]; then
  Arch=maci64
  if [[ "$(uname -m)" == "arm64" ]]; then Arch=maca64; fi
  DefaultRuntimePath=/Applications/MATLAB/MATLAB_Runtime/${MATLABRelease}
  DefaultInstallPath=/Applications/MATLAB_${MATLABRelease}.app/
  TestFile=runtime/${Arch}/libmwmclmcrrt.${MATLABVersNum}.dylib
  Executable=${EXEDIR}/${CompiledMATLABProgram}.app/Contents/MacOS/${CompiledMATLABProgram}
else
  DefaultRuntimePath=/usr/local/MATLAB/MATLAB_Runtime/${MATLABRelease}
  DefaultInstallPath=/usr/local/MATLAB/${MATLABRelease}
  TestFile=runtime/glnxa64/libmwmclmcrrt.so.${MATLABVersNum}
  Executable=${EXEDIR}/${CompiledMATLABProgram}
fi

# If the Matlab Runtime is installed in a non-default location, define the correct path 
# on the next line and uncomment it (remove the leading "#") or define it as a system
# environment variable
#BrainSuiteMCR="/path/to/your/MCR";

if [ -z "$BrainSuiteMCR" ]; then
  if [ -e ${DefaultRuntimePath} ]; then
    BrainSuiteMCR="${DefaultRuntimePath}";
  elif [ -e ${DefaultInstallPath}/runtime ]; then
    BrainSuiteMCR="${DefaultInstallPath}";
    echo
    echo "Located Matlab installation with runtime directory ${BrainSuiteMCR}."
    echo
  else
    echo
    echo "Could not locate an installation of MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) on this system."
    echo 
    echo "Please install the MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) from MathWorks website at:"
    echo
    echo "https://www.mathworks.com/products/compiler/matlab-runtime.html"
    echo 
    echo "If you already have MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) or MATLAB ${MATLABRelease}"
    echo "installed, please edit ${Program} by uncommenting and editing"
    echo "the following line near the top of the file:"
    echo
    echo "#BrainSuiteMCR=\"/path/to/your/MCR\";"
    echo
    echo "(replace /path/to/your/MCR with the path to your MCR [or Matlab] installation)"
    echo
    exit 78
  fi
fi

if [ ! -e ${BrainSuiteMCR}/${TestFile} ]; then
  echo
  echo "Could not find a valid installation of MCR ${MATLABRelease} (${MATLABVersNum}) [or Matlab ${MATLABRelease} with Matlab Compiler] at following location:"
  echo ${BrainSuiteMCR}
  echo
  echo "Could not find following file, which must be present for a valid installation:"
  echo ${BrainSuiteMCR}/${TestFile}
  echo
  echo "Please install the Matlab MCR ${MATLABRelease} (${MATLABVersNum}) from MathWorks at:"
  echo "     https://www.mathworks.com/products/compiler/matlab-runtime.html"
  echo 
  echo "If you already have MCR ${MATLABRelease} (${MATLABVersNum}) [or Matlab ${MATLABRelease}ABRelease} with Matlab Compiler]"
  echo "installed, please edit ${Program} by uncommenting and editing"
  echo "the following line near the top of the file:"
  echo
  echo "#BrainSuiteMCR=\"/path/to/your/MCR\";"
  echo
  echo "(replace /path/to/your/MCR with the path to your MCR [or Matlab] installation)"
  echo
  echo "NOTE: THE EXACT VERSION NUMBER IS IMPORTANT. NEWER VERSIONS WILL NOT WORK."
  exit 78
fi

read -d '' usage <<EOF
${CompiledMATLABProgram}

Usage:
  ${Program} -i imgfile -b betafile -m spatialMaskfile -c spectrumInfofile -o output_prefix -t [png|eps|epsc|pdf]

where
  imgfile            image file
  spectmask_file     spectral mask file
  spectrumInfofile   config (.ini) file
  output_prefix      prefix to be used for output composite figures
  png|eps|epsc|pdf   specifies the output type for the figures (can be used multiple times)

Example:

  ${Program} -i imgfile.mat -b betafile.mat -m spatialMaskfile.mat -c spectrumInfofile.ini -o output_prefix -t png

note: all arguments are required!

EOF

# Parse inputs
if [ $# -lt 1 ]; then
  echo
  echo "$usage"
  echo
  exit
fi

imgfile=""
betafile=""
spectmask=""
configfile=""
output_prefix=""
output_types=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo
      echo "$usage"
      echo
      shift # past argument
      exit 0
      ;;
    -i|--imgfile)
      imgfile="$2"
      shift; shift;
      ;;
    -b|--betafile)
      betafile="$2"
      shift; shift;
      ;;
    -s|--spect_infofile)
      spectrum_info_file="$2"
      shift; shift;
      ;;
    -m|--spatmaskfile)
      spatmaskfile="$2"
      shift; shift;
      ;;
    -c|--configfile)
      configfile="$2"
      shift; shift;
      ;;
    -o|--outprefix)
      output_prefix="$2"
      shift; shift;
      ;;
    -t|--file_types)
      shift
      arg=$1
      while [[ ! ${arg:0:1} == "-" ]]; do
        output_types="$output_types $1"
        shift
        arg=$1
        if (($#<1)); then break; fi
      done
      ;;      
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      echo "Unrecognized parameter $1"
      exit 1
      ;;
  esac
done

ArgsOK=1
errs=""

if [ "x$imgfile" = "x" ]; then
  errs="${errs}\nNo input spectral file provided -- -i option is required!"
  ArgsOK=0
else
  if [ ! -f "$imgfile" ]; then
    errs="${errs}\nInput spectral file $imgfile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$betafile" = "x" ]; then
  errs="${errs}\nNo beta file provided -- -b option is required!"
  ArgsOK=0
else
  if [ ! -f "$betafile" ]; then
    errs="${errs}\nBeta file $betafile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$spectmask" = "x" ]; then
  errs="${errs}\nNo spectral mask file provided -- -m option is required!"
  ArgsOK=0
else
  if [ ! -f "$spectmask" ]; then
    errs="${errs}\nSpectral mask file $spectmask does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$configfile" = "x" ]; then
  errs="${errs}\nNo config file provided -- -c option is required!"
  ArgsOK=0
else
  if [ ! -f "$configfile" ]; then
    errs="${errs}\nColor file $configfile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$output_prefix" = "x" ]; then
  errs="${errs}\nNo output prefix provided -- -o option is required!"
  ArgsOK=0
fi
if [ "x$output_types" = "x" ]; then
  errs="${errs}\nNo output image types provided -- -t option is required!"
  ArgsOK=0
fi

# if (($ArgsOK==0)); then
#   echo
#   echo "$usage"
#   echo
#   printf "Error:$errs\n\n"
#   exit 1
# fi


# Set up path for MCR applications.
if [[ "$OSTYPE" == "darwin"* ]]; then
  DYLD_LIBRARY_PATH=.:${BrainSuiteMCR}/runtime/${Arch} ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${BrainSuiteMCR}/bin/${Arch} ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${BrainSuiteMCR}/sys/os/${Arch};
  export DYLD_LIBRARY_PATH;
else
  LD_LIBRARY_PATH=.:${BrainSuiteMCR}/runtime/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${BrainSuiteMCR}/bin/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${BrainSuiteMCR}/sys/os/glnxa64;
  MCRJRE=${BrainSuiteMCR}/sys/java/jre/glnxa64/jre/lib/amd64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
  XAPPLRESDIR=${BrainSuiteMCR}/X11/app-defaults ;
  export LD_LIBRARY_PATH;
  export XAPPLRESDIR;
fi

"${Executable}" imgfile "${imgfile}" \
    betafile "${betafile}" \
    spect_infofile "${spectrum_info_file}" \
    outprefix "${output_prefix}" \
    configfile "${configfile}" spatmaskfile \
    "${spatmaskfile}" file_types ${output_types}

exit
