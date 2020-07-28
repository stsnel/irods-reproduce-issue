#!/bin/bash
numfiles=1
filesize_kb=10

dd if=/dev/urandom bs=${filesize_kb}k count=1 of=testfile

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
    echo "Creating test file $testfile ..."
    iput -f testfile "$testfile"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
    echo "Replicating test file $testfile to consumer ..."
    irepl -R consumerResource "/testZone/home/rods/$testfile"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
 echo "Deleting test file $testfile ..."
 irm "test.$n.txt"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
    echo "Replicating trash copy of test file $testfile to consumer ..."
    irepl -R consumerResource "/testZone/trash/home/rods/$testfile"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
 echo "Creating hard links in iCAT database for file $testfile ..."
 sudo -u postgres psql -d ICAT -c "update r_data_main set coll_id = 10011 where data_repl_num = 1 and data_name = '$testfile';"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
 echo "Re-creating test file $testfile ..."
 iput -f testfile "test.$n.txt"
done

for n in $(seq $numfiles)
 do testfile="test.$n.txt"
 echo "Deleting test file $testfile ..."
 irm "$testfile"
done
