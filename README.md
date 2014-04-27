https://github.com/schuyler1d/git-forward-merge

Copyright 2014 Schuyler Duveen and Ram Rachum
Adapted from Ram Rachum's git-cascade python code
   at https://github.com/cool-RR/git-cascade

Released under the MIT license (from Ram),
and the GPL 2.0 and later versions (to match with git)

This command was written in order to solve an annoyance with the built-in `git
merge`. The annoying thing about `git merge` is that if one wants to merge
branch `foo` into branch `bar`, one first needs to check out branch `bar`, and
only then merge `foo` into it. This can become a drag, especially when having
an unclean working tree.

Enter `git forward-merge`. All pushes done with it work regardless of which
branch is currently checked out and which files are in the working tree.

Push branch `foo` into `bar`:

    git forward-merge foo bar
    
Push current branch/commit into `bar`:

    git forward-merge bar

How does it work?
-----------------

`git forward-merge` creates a temporary git index file and working directory to
be used only for the merge, without interfering with the actual index file and
working directory. (Unless the merge is a fast-forward, in which case the merge
is done trivially by a local push.)


Limitation
----------

`git forward-merge` works only when the merge can be done
automatically. It doesn't work for merges that require conflict resolution. For
that, please resort to using `git merge`.

If you do attempt a merge that requires conflict resolution, `git
forward-merge` will abort the merge and leave your working directory clean,
UNLESS the branch you're merging to is the current branch, in which case it
will leave the merge in the working directory for you to resolve the conflict
and commit, just like `git merge`.

Future TODOs
* maybe have a switch so that if there is a conflict you would keep the dir
and then have another switch to say 'use this dir for the conflict resolutions'
* merge switches: -m, merge strategies?
