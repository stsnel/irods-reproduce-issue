#!/bin/bash
numfiles=10
filesize_kb=10

dd if=/dev/urandom bs=${filesize_kb}k count=1 of=testfile

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
    echo "Creating test file $testfile ..."
    iput -f testfile "$testfile"
done

while true
  do num=$(ils -L | grep -cE "consumerResource.+test\.[0-9]+\.txt") 
     if [ "$num" -ge "$numfiles" ]
     then echo "All files have been replicated."
	  break
     else echo "Currently $num out of $numfiles have been replicated. Waiting for"
	  echo  "asynchronous replication to complete ..."
	  sleep 2
     fi
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
 echo "Deleting and re-creating test file $testfile ..."
 irm "$testfile"
 iput -f testfile "test.$n.txt"
done
