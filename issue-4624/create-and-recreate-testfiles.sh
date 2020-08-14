#!/bin/bash
numfiles=1
filesize_kb=10
testfile_prefix="test"

for n in $(seq $numfiles)
 do testfile="${testfile_prefix}.$n.txt"
    echo "Creating and uploading file $testfile ..."
    dd if=/dev/urandom bs=${filesize_kb}k count=1 of=${testfile_prefix}.$n.txt
    iput -f "$testfile"
done

for n in $(seq $numfiles)
do  testfile="${testfile_prefix}.$n.txt"
    echo "Replicating test file $testfile to consumer ..."
    irepl -R consumerResource "/testZone/home/rods/$testfile"
done

for n in $(seq $numfiles)
 do testfile="${testfile_prefix}.$n.txt"
 echo "Deleting test file $testfile ..."
 irm "$testfile"
done

for n in $(seq $numfiles)
 do testfile="${testfile_prefix}.$n.txt"
 echo "Creating hard links in iCAT database for file $testfile ..."
 sudo -u postgres psql -d ICAT -c "update r_data_main set coll_id = 10011 where data_repl_num = 1 and data_name = '$testfile';"
done

for n in $(seq $numfiles)
 do testfile="${testfile_prefix}.$n.txt"
 echo "Re-creating test file $testfile ..."
 iput -f testfile "test.$n.txt"
done

for n in $(seq $numfiles)
 do testfile="${testfile_prefix}.$n.txt"
 echo "Deleting test file $testfile ..."
 irm "$testfile"
done
