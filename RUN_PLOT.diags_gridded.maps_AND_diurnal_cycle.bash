#!/bin/bash
##############################################################
# Main script to compute statistics and generate figures for the air-sea interface
#
# 	In this script, the user chooses and assigns the following criteria for collocation: experiments, dates, HPC partition
#
# 	To run this script on the command line: ./NameOfThisScript.bash
#
# CONTRIBUTORS: Katherine E. Lukens             NOAA/NWS/NCEP/EMC, CISESS at U. of Maryland
#               Guillaume Vernieres             NOAA/NWS/NCEP/EMC
#               Kayo Ide                        U. of Maryland
#               Mindo Choi                      NOAA/NWS/NCEP/EMC, SAIC
#  
# OUTPUT: 
#	- Innovation comparisons between 2 experiments
#		- Maps
#
# NOTES: 
#	1. This script runs all jobs in the background. 
#
# HISTORY:
#	2024-05-10	K.E. Lukens	Created
#
##############################################################

#set -x

#==========================================================================================
# BEGIN USER INPUT
#==========================================================================================

#----------------------------------------------
# Set date range over which to run the program
#	For computational efficiency, it is recommended to loop through one month at a time. 
#	Choose one year/month combination and an array of days.
#
# yyyy 	= year
# mm	= month
# ddarr = day array
#----------------------------------------------

	#`````````````````````````````````````
	# Start Date
yyyyS="2021"
mmS="07"
ddS="01"
hhS="00"

	#`````````````````````````````````````
	# End Date
yyyyE="2021"
mmE="07"
ddE="04"
hhE="18"

#----------------------------------------------
# Set paths to experiments
#----------------------------------------------

	# directory where this script is located
dir_home="/scratch1/NCEPDEV/da/Katherine.Lukens/NSST/tools/marineDA/"

	# paths to experiments
	# 	expt0 = control
	#	expt1 = test to compare against control
#dir_expt0="/scratch1/NCEPDEV/stmp2/Katherine.Lukens/expts/cp0.no-ocn-da/COMROOT/cp0.no-ocn-da/saved/"
#exptname0="cp0.no-ocn-da"
#dir_expt1="/scratch2/NCEPDEV/stmp1/Katherine.Lukens/expts/cp0.ocn-da.sst/COMROOT/cp0.ocn-da.sst/saved/"
#exptname1="cp0.ocn-da.sst"

exptname0="ctl_Gbranch"
#exptname1="skint_w_ctl_Gbranch"
exptname1="sstavg_w_ctl_Gbranch"
#exptname1="monitorGEOobs"
#exptname1="GEOerrors_inflated"

#exptname0="S2Smodel_ATMda"
#exptname0="S2Smodel_S2Sda_C03"
#exptname1="marine_candidate_092024"

#exptname1=${exptname0}

	# variable to display
var="sst"
#var="seaice"

	# analysis cycle hours to display
#hour=("00" "06" "12" "18")
#hour=("00" "06")
hour=("12" "18")
#hour=("18")

	# observing instruments to display
	#	"all" = all available instruments for $var are used
#obstype=("all" "abi_g16" "abi_g17" "ahi_h08" "avhrr_ma" "avhrr_mb" "viirs_n20" "viirs_npp")
obstype=("all_sats")
#obstype=("abi_g16" "abi_g17" "ahi_h08" "avhrr_ma" "avhrr_mb" "viirs_n20" "viirs_npp")
#obstype=("all_geo" "all_leo")
#obstype=("all_geo")
#obstype=("all_leo")

	# degree size of gridded data
degree=1

        # output means or sums into netcdf
meansumopt=0           #means
#meansumopt=1            #sums

#----------------------------------------------
# Diags directory

#dir_diags_netcdf=${dir_home}"output/data/diags/"
dir_diags_netcdf="/scratch1/NCEPDEV/da/Katherine.Lukens/NSST/data/expts/"
dir_expt0=${dir_diags_netcdf}${exptname0}"/"
dir_expt1=${dir_diags_netcdf}${exptname1}"/"

#----------------------------------------------
# Set HPC account, partition, and runtime limit for jobs
#	All variables are strings (use double quotes)
#----------------------------------------------

account="da-cpu"

	# Hera
#qos="batch"		# max timelimit = 8 hours | default
qos="debug"		# max timelimit = 30 minutes | highest priority | only 2 jobs can run at same time
#qos="windfall"		# max timelimit = 8 hours | lowest priority | won't affect FairShare value

partition="hera"	# default for batch, debug, windfall

timelimit="00:30:00"
#timelimit="01:00:00"
#timelimit="02:00:00"
#timelimit="04:00:00"
#timelimit="08:00:00"

ntasks=1

#==========================================================================================
# END USER INPUT
#==========================================================================================
#==========================================================================================
#==========================================================================================
# Set up and run SLURM commands
#==========================================================================================

#----------------------------------------------
# Set working paths
#       Always end path names with a slash "/"

dir_src=${dir_home}"src/"           #location of collocation source code
echo 'SOURCE CODE DIRECTORY = '${dir_src}

#----------------------------------------------
# Create output directory (where figures go) if it doesn't already exist

dir_out=${dir_home}"/output/"

if [[ ! -d ${dir_out} ]] ; then
  mkdir -p ${dir_out}
fi

#----------------------------------------------
# Count number of items in arrays

nhour=${#hour[@]}
nobstype=${#obstype[@]}

#----------------------------------------------

echo "-- Start Date: $yyyyS $mmS $ddS"
echo "-- End Date:   $yyyyE $mmE $ddE"
dateSTART=$yyyyS$mmS$ddS$hhS
dateEND=$yyyyE$mmE$ddE$hhE

cd ${dir_home}

#----------------------------------------------
# Set name of run job script (to pass as argument to run job script)
#       This script actually runs the python code

run_python_code=run.diags_gridded.maps.job

#----------------------------------------------
# Input arguments for SLURM (sbatch) commands
#
#       Arguments (arg) to customize sbatch command

arg1=${dateSTART}
arg2=${dateEND}
arg3=${dir_out}
arg4=${exptname0}
arg5=${dir_expt0}
arg6=${exptname1}
arg7=${dir_expt1}
arg8=${var}
arg9=${degree}
arg10=${meansumopt}

#----------------------------------------------
# Set up sbatch command(s) and run through loop of computation scripts
#
#       Run command format for each job:
#               sbatch $output_logfile_name $job_name $input_directory $colloc_script $arg1 /
#               $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $partition $timelimit $run_job_script

ihour=0
while [[ $ihour -lt $nhour ]]
do
  iobs=0
  while [[ $iobs -lt $nobstype ]]
  do

    arg11=${hour[$ihour]}
    arg12=${obstype[$iobs]}

    #+++++++++++++++++++++++++++++++++
    # Diurnal Cycle in Diags
    #+++++++++++++++++++++++++++++++++

    jname=PLOT.diags_diurnal
    python_code=MAIN_PLOT.diags_gridded.diurnal_cycle.maps.py

    log=LOG_${jname}_${arg4}_${arg6}_${arg8}_deg${arg9}_${arg11}_${arg12}_${dateSTART}_${dateEND}            # log name containing output log info
    jlog=${jname}_${arg4}_${arg6}_${arg8}_deg${arg9}_${arg11}_${arg12}_${dateSTART}_${dateEND} 	      # log name for job in queue

    rm $log                                             # remove old log file

    sbatch --output=${log} --job-name=${jlog} --account=${account} --partition=${partition} --qos=${qos} --time=${timelimit} --ntasks=${ntasks} --export=INDIR=${dir_src},SCRIPT=${python_code},ARG1=${arg1},ARG2=${arg2},ARG3=${arg3},ARG4=${arg4},ARG5=${arg5},ARG6=${arg6},ARG7=${arg7},ARG8=${arg8},ARG9=${arg9},ARG10=${arg10},ARG11=${arg11},ARG12=${arg12} ${run_python_code}

    #+++++++++++++++++++++++++++++++++
    # Diags themselves
    #+++++++++++++++++++++++++++++++++

    jname=PLOT.diags
    python_code=MAIN_PLOT.diags_gridded.maps.py

    log=LOG_${jname}_${arg4}_${arg6}_${arg8}_deg${arg9}_${arg11}_${arg12}_${dateSTART}_${dateEND}            # log name containing output log info
    jlog=${jname}_${arg4}_${arg6}_${arg8}_deg${arg9}_${arg11}_${arg12}_${dateSTART}_${dateEND}           # log name for job in queue

#    rm $log                                             # remove old log file

#    sbatch --output=${log} --job-name=${jlog} --account=${account} --partition=${partition} --qos=${qos} --time=${timelimit} --ntasks=${ntasks} --export=INDIR=${dir_src},SCRIPT=${python_code},ARG1=${arg1},ARG2=${arg2},ARG3=${arg3},ARG4=${arg4},ARG5=${arg5},ARG6=${arg6},ARG7=${arg7},ARG8=${arg8},ARG9=${arg9},ARG10=${arg10},ARG11=${arg11},ARG12=${arg12} ${run_python_code}

    #+++++++++++++++++++++++++++++++++

    let iobs=iobs+1
  done
  let ihour=ihour+1
done

#----------------------------------------------
#==============================================

##############################################################
# END
##############################################################
