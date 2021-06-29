#!/usr/bin/env bash

#easy way to update all of your repos in one dir. Just incase you are like me
# and need to do this every morning

#change this to your git directory
gitbase=/home/jeremy/github/

# change this to the name of the remote repo for forks
upstream_name='upstream'

# array of branches to try, in order
branch_names=("master", "main")

#get the pwd to return to after we are done refreshing
curdir=`pwd`

# TODO: support main as branch (due to gh changes)

##########################################################################################
USAGE_LINE="Usage: pull-all-git-repos.sh [-h] [-n]\n\n"

control_c()
# run if user hits control-c
{
    printf "\nCleaning up and exiting due to interupt.\n\n"
    cd $gitbase
    exit
}

usage_help() {
	printf "$USAGE_LINE"
	printf "By default this will pull all repos in a directory and attempt to pull \n"
	printf "upstream repos on clean forks that have master checked out locally. If \n"
	printf "updating a fork from the upstream master branch succeeds then the changes \n"
	printf "will be pushed to your fork.\n"
	printf "Options: \n"
	printf "  -n - don't pull repo for forks, just pull checked out branch from the fork\n"
	printf "\n\n"
	exit 1
}



do_not_process_forks=''

while getopts ":hn" opt; do
  case ${opt} in
    h ) usage_help
	    ;;
    n ) do_not_process_forks='true'
	    ;;
    \? ) printf "$USAGE_LINE"
         exit 1
      ;;
  esac
done


# function to detect if this is a fork , clean, and on master branch. if so, pull upstream
is_repo_a_fork() {
	# return 0 after pulling, 1 all other cases
	if [[ $do_not_process_forks ]]; then
		return 1
	fi
	

	upstream_exists=''
	if [[ `git config --get remote.$upstream_name.url` ]]; then
		upstream_exists=true
	else
		return 1
	fi
	
	main_branch_name=''
	for name in "${branch_names[@]}"
    do
      if [[ $(git rev-parse --abbrev-ref HEAD) == "$name" ]]; then
          main_branch_name=$name
      fi
    done
	
	clean_branch=''
	# this does not care about untracked files
	if [[ `git diff --stat` == '' ]]; then
		clean_branch=true
	fi
	
	if [[ $upstream_exists && $main_branch_name && ! $clean_branch ]]; then
		printf "Not pulling upstream as this branch is dirty\n"
		return 1
	fi 
	
	if [[ $upstream_exists && $main_branch_name && $clean_branch ]]; then
		# on master and there is an upstream. pull it
		git pull $upstream_name $main_branch_name
		# also push to fork master
		git push
		return 0
	else
		printf "Not pulling upstream as this is a fork but not on one of the branches: "
		printf "%s " "${branch_names[@]}"
		printf "\n"
		return 1
	fi
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

if [[ $do_not_process_forks ]]; then 
	echo "Not processing forks per user request"
fi

#cd to the git base dir, cd into each sub dir, and do a git pull
cd $gitbase
for repo in */
do

    printf "\nUpdating $repo\n"
    cd $repo
    # treat forks differently
    is_repo_a_fork
    if [[ $? != 0 ]]; then
	    git pull
	fi
    cd $gitbase
    printf "\n"
    
done

#return to our original path
cd $curdir
