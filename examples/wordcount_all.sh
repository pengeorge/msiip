#!/bin/bash
# wordcount_all.sh

queue JOB=1:7 ./qlog/wordcount.JOB.log ./wordcount.sh data/text/text.JOB.txt '>' data/text/wc_result.JOB.txt

cat data/text/wc_result.*.txt | awk '{s+=$1}END{print "Total word count is ",s}'

