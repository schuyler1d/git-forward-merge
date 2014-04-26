#!/bin/sh

# Copyright 2014 Schuyler Duveen and Ram Rachum
# Adapted from Ram Rachum's git-cascade python code

# This command was written in order to solve an annoyance with the built-in `git
# merge`. The annoying thing about `git merge` is that if one wants to merge
# branch `foo` into branch `bar`, one first needs to check out branch `bar`, and
# only then merge `foo` into it. This can become a drag, especially when having
# an unclean working tree.

# Enter `git forward-merge`. All pushes done with it work regardless of which
# branch is currently checked out and which files are in the working tree.

dashless=$(basename "$0" | sed -e 's/-/ /')
USAGE="list [<options>]
    or: $dashless <source_branch> <destination_branch>
    or: $dashless <destination_branch>"

# Push branch `foo` into `bar`:

#     git forward-merge foo bar
    
# Push current branch/commit into `bar`:

#     git forward-merge bar

# How does it work?
# -----------------

# `git forward-merge` creates a temporary git index file and working directory to
# be used only for the merge, without interfering with the actual index file and
# working directory. (Unless the merge is a fast-forward, in which case the merge
# is done trivially by a local push.)


# Limitation
# ----------

# `git forward-merge` works only when the merge can be done
# automatically. It doesn't work for merges that require conflict resolution. For
# that, please resort to using `git merge`.

# If you do attempt a merge that requires conflict resolution, `git
# forward-merge` will abort the merge and leave your working directory clean,
# UNLESS the branch you're merging to is the current branch, in which case it
# will leave the merge in the working directory for you to resolve the conflict
# and commit, just like `git merge`.

# Future TODOs
# maybe have a switch so that if there is a conflict you would keep the dir
# and then have another switch to say 'use this dir for the conflict resolutions'

. $(git --exec-path)/git-sh-setup

currentbranch=$(git rev-parse --abbrev-ref HEAD)

if test "$#" = "1"
then
    source="HEAD"
    destination="$1"
    #the nice name of HEAD for the merge comment
    source_nice="$currentbranch"
elif test "$#" = "2"
then
    source="$1"
    destination="$2"
    source_nice="$source"
else
    exit 1
fi

if test "$destination" = "$currentbranch"
then
    git merge $source
else
    firstcommit=$(git merge-base "$source" "$source")
    secondcommit=$(git merge-base "$destination" "$destination")
    basecommit=$(git merge-base "$source" "$destination")
    if test "$secondcommit" = "$basecommit"
    then
        git push . "$source":"$destination"
    elif test "$firstcommit" != "$basecommit"
    then
        tmp_work_tree="$GIT_DIR/workdir.git-forward-merge.$$"
        tmp_index_file="$GIT_DIR/index.git-forward-merge.$$"
        rm -rf "$tmp_work_tree"
        mkdir "$tmp_work_tree"

        #so $(git rev-parse --is-inside-work-tree) = true
        cd "$tmp_work_tree"

        merge_base=$(git merge-base "$destination" "$source")

        ORIG_GIT_WORK_TREE="$GIT_WORK_TREE"
        ORIG_GIT_INDEX_FILE="$GIT_INDEX_FILE"

        GIT_INDEX_FILE="$tmp_index_file"
        GIT_WORK_TREE="$tmp_work_tree"
        export GIT_INDEX_FILE GIT_WORK_TREE

        echo $merge_base
        echo $GIT_WORK_TREE
        echo $GIT_DIR

        git read-tree -im "$merge_base" "$destination" "$source"

        echo git read-tree -im "$merge_base" "$destination" "$source"
        echo after read-tree
        echo $(git rev-parse --is-bare-repository)
        git merge-index echo -a

        git merge-index git-merge-one-file -a
        write_tree=$(git write-tree)

        commit=$(git commit-tree "$write_tree" \
            -p "$destination" -p "$source" -m "Merge $source_nice into $destination")
        echo $commit
        git update-ref -m "Merge $source_nice into $destination" "refs/heads/$destination" "$commit"

        #restore environment
        unset GIT_WORK_TREE GIT_INDEX_FILE
        test -z "$ORIG_GIT_WORK_TREE" || {
            GIT_WORK_TREE="$ORIG_GIT_WORK_TREE" &&
            export GIT_WORK_TREE
        }
        test -z "$ORIG_GIT_INDEX_FILE" || {
            GIT_INDEX_FILE="$ORIG_GIT_INDEX_FILE" &&
            export GIT_INDEX_FILE
        }

        rm "$tmp_index_file"
        rm -rf "$tmp_work_tree"
    else
        echo "$destination is already ahead of $source, no need to merge."
    fi
fi