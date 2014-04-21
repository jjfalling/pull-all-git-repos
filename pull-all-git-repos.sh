#!/usr/bin/env bash
#easy way to update all of your repos in one dir. Just incase you are like me
# and need to do this every morning

#change this to your git directory
gitbase=/Users/jeremy/github/

#get the pwd to return to after we are done refreshing
curdir=`pwd`

control_c()
# run if user hits control-c
{
    printf "\nCleaning up and exiting due to interupt.\n\n"
    cd $gitbase
    exit
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

#cd to the git base dir, cd into each sub dir, and do a git pull
cd $gitbase
for repo in */
do

    printf "\nUpdating $repo\n"
    cd $repo
    git pull
    cd $gitbase
    printf "\n"
    
done

#return to our original path
cd $curdir
