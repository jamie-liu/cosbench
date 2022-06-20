#! /bin/bash

function build_conf_xml()
{
    local bname=$1
    cp $xmlTmpFile $xmlRunFile
    cmd="sed -i 's/accesskeyValue/"$accesskey"/g' "$xmlRunFile
    eval $cmd
    cmd="sed -i 's/secretkeyValue/"$secretkey"/g' "$xmlRunFile
    eval $cmd
    cmd="sed -i 's/endpointValue/"$endpoint"/g' "$xmlRunFile
    eval $cmd

    cmd="sed -i 's/workersValue/"$workers"/g' "$xmlRunFile
    eval $cmd
    cmd="sed -i 's/runtimeValue/"$runtime"/g' "$xmlRunFile
    eval $cmd
    cmd="sed -i 's/bucketName/"$bname"/g' "$xmlRunFile
    eval $cmd
    cmd="sed -i 's/bucketObjectNum/"$bucketObjectNum"/g' "$xmlRunFile
    eval $cmd
}

function cosbench_run()
{
    local c=0
    while [ $c -lt $loopCnt ] ; do
        c=`expr $c + 1`
        build_conf_xml $bucketName$c
        bash cli.sh submit $xmlRunFile
        # wait until cosbench complete
        while [ 1 ] ; do
            ret=`sh cli.sh info | grep 'active workloads' | awk '{print $2}'`
            if [[ $ret == 0 ]]; then
                break
            fi
            sleep 10
        done

        # wait for a while to start next loop
        sleep 120
    done
}

function cosbench_write()
{
    xmlTmpFile="conf/s3-config-write-tmp.xml"
    cosbench_run
}

function cosbench_read()
{
    xmlTmpFile="conf/s3-config-read-tmp.xml"
    cosbench_run
}

function cosbench_cleanup()
{
    xmlTmpFile="conf/s3-config-cleanup-tmp.xml"
    cosbench_run
}

function do_main()
{
    if [[ $operation == "write" ]]; then
        cosbench_write
    elif [[ $operation == "read" ]]; then
        cosbench_read
    elif [[ $operation == "cleanup" ]]; then
        cosbench_cleanup
    else
        usage $script_name
    fi
}

function usage()
{
    echo "usage: $1 write <bucketName> <bucketObjectNum> <loopCnt>"
    echo "       $1 read <bucketName> <bucketObjectNum> <loopCnt>"
    echo "       $1 cleanup <bucketName> <bucketObjectNum> <loopCnt>"
    exit 1
}

## Main entrance
script_name=$0
if [[ $# != 4 ]]; then
    usage $script_name
fi

operation=$1
bucketName=$2
bucketObjectNum=$3
loopCnt=$4

xmlTmpFile=""
xmlRunFile="conf/s3-config-run.xml"

accesskey="7J82YY2ODPQ22337N392"
secretkey="IgRmuo11OrxRlWa7TEicHSbbUFNYP2MDwZ8St2PS"
endpoint="http:\/\/10.209.242.72:10080"

workers=100
runtime=300

do_main

