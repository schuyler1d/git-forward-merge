#!/bin/sh
FMCMD=$(pwd)/git-forward-merge.sh

KEEP_DIR=$1

TESTSPASS_EXITCODE=0

TESTREPO=test-fm.$$

git init $TESTREPO
cd $TESTREPO

git checkout -b first
echo -e "foo\nbar\n\nbaz" >foo
mkdir bar
echo -e "abc\ndef\n\nxyz" >bar/abc
git add foo
git add bar/abc
git commit -a -m 'first commit'

git checkout -b firstA
echo -e "foo\nbar\n\nfirstA\n\nbaXXX" >foo
echo -e "abc\nfirstA\n\nxyz" >bar/abc
git commit -a -m 'first.firstA'

git checkout first
git checkout -b firstB
echo -e "foo\nfirstB\nbar\n\nbaz" >foo
git commit -a -m 'first.firstB'

git checkout -b firstC
echo -e "foo\nfirstB\nbar\n\nbaCCCCC" >foo
git commit -a -m 'first.firstB.firstC, conflicts with firstA'


#should merge easily (with fast-forward)
echo "===TEST 1"
git checkout -b first_target first
git checkout firstA
$FMCMD firstA first_target

#should merge ok (without fast-forward)
echo "===TEST 2"
git checkout -b firstAB_target firstA
git checkout firstB
$FMCMD firstAB_target

merge_test_a=$(git cat-file blob firstAB_target:foo | grep firstA)
merge_test_b=$(git cat-file blob firstAB_target:foo | grep firstB)
if (test "$merge_test_a" != "firstA" || test "$merge_test_b" != "firstB" )
then
    echo "===FAIL: on firstAB_target, 2:non-fast-forward merge fails"
    TESTSPASS_EXITCODE=1
else
    echo "===PASS 2:non-fast-forward merge"
fi

#should conflict and fail
echo "===TEST 3"
git checkout -b firstABC_target firstA
git checkout firstB
$FMCMD firstC firstABC_target
testres=$?
if test $testres = 0
then
    echo "===FAIL: on firstABC_target, 3:conflict merge somehow passed"
else
    echo "===PASS 3:conflict merge result correct"
fi

#should conflict and since we have it checked-out use working repo
echo "===TEST 4"
git checkout -b firstABC_target2 firstA
$FMCMD firstC firstABC_target2
merge_test_c=$(grep -o firstC foo)
merge_test_d=$(grep -o HEAD foo)
merge_test_e=$(grep baCCCCC foo)
merge_test_f=$(grep baXXX foo)
if (test "$merge_test_c" != "firstC" || test "$merge_test_d" != "HEAD" \
    || test "$merge_test_e" != "baCCCCC" || test "$merge_test_f" != "baXXX" )
then
    echo "===FAIL: on firstABC_target, 3:conflict merge somehow passed"
else
    echo "===PASS 4:conflict merge in working directory result correct"
fi

cd ..

if test "$KEEP_DIR" != "keepdir"
then
    echo removing test repo: "$TESTREPO"
    rm -rf "$TESTREPO"
else
    echo KEEPING TEST REPO: "$TESTREPO"
fi

exit $TESTSPASS_EXITCODE
