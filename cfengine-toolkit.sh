#
# CfEngine Toolkit
#
# Collection of shell functions to manage CfEngine
#
# v 1.0 - BBR - 2011/10/21
#
#

# Variables
#
CfEngineDir=/softwares/cfengine3/sbin
CfEngineInputs=/softwares/cfconf/inputs

CfEngineAgent=${CfEngineDir}/cf-agent
CfEngineReport=${CfEngineDir}/cf-report

CfEnginePromise=${CfEngineInputs}/promises.cf
CfEnginePromiseReport=${CfEngineInputs}/promises-report.cf

CheckOutFlag=${CfEngineInputs}/CVS

CheckOutClass=CheckOut
ForceUpdateClass=ForceUpdate

UpdateITConfigClass=UpdateITConfig


# Aliases
#
alias cfeRun='${CfEngineAgent} -vKf ${CfEnginePromise}'
alias cfeRunSilent='${CfEngineAgent} -Kf ${CfEnginePromise}'

alias cfeForceRun='${CfEngineAgent} -vKf ${CfEnginePromise} -D${ForceUpdateClass}'
alias cfeForceRunSilent='${CfEngineAgent} -Kf ${CfEnginePromise} -D${ForceUpdateClass}'

alias cfeUpdateITConfig='${CfEngineAgent} -vKf ${CfEnginePromise} -D${UpdateITConfigClass}'
alias cfeSudoUpdateITConfig='sudo ${CfEngineAgent} -vKf ${CfEnginePromise} -D${UpdateITConfigClass}'

alias cfeForceRunOnCheckOut='${CfEngineAgent} -vKf ${CfEnginePromise} -D${ForceUpdateClass},${CheckOutClass}'



# Functions
#
function cfeRemoveCheckOut {
        if [ -d ${CheckOutFlag} ]
        then
                mv ${CheckOutFlag} ${CheckOutFlag}.Disable
                echo "=== CfEngine CheckOut disabled. "
        else
                echo "@@@ NoCfEngine CheckOut found."
        fi
}

function cfeShowLastSeen {
	[ -f /tmp/lastseen.txt ] && rm /tmp/lastseen.txt
	${CfEngineReport} -f ${CfEnginePromiseReport}
	cat /tmp/lastseen.txt
}
