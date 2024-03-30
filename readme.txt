Decisions to make:
- Iterative vs recursive approach
    - Recursive approach is better since we don't need to keep track of the parents
- Insertion via top-down or bottom-up
    - see https://www.geeksforgeeks.org/c-program-red-black-tree-insertion/?ref=lbp
    - Top Down:
        - fix tree as you go down, then insert (no need to do anything on the way back up)
    - Bottom Up:
        - 2 variations:
            - pointer reinforcement (fix on the way back up)
            - insert node, then fix from the bottom up again (pass in tree and inserted node into a "fixup" function), after insertion is done
    -> Choose bottom-up because I wanted to practice pointer reinforcement method of tree programming (From GTech CS1332 course)
    -> (Pointer reinforcement: returning a pointer to the node that was visited, and the node that made recursive call links itself
       to the visited node. So the tree relinks itself on the way back up from the recursive call stack.)
- Is pointer reinforcement even possible?
    - At first glance, it seems like it isn't
    - eg. let's call the balance function on node N, after L was visited.
        - in the case of a double rotation: 
                  Before:            After rotation 1:               After rotation 2:
                    P                        P                             L(R)
                  /   \                    /   \                          /    \
                C(B)   N(R)            C(B)   L(R)                      P      N(R)
                      /   \                 /   \                      / \      / \
                    L(R)   R              LL    N(R)                C(B)  LL  LR   R
                    / \                         /  \
                  LL   LR                     LR    R
        Balance on return from recursive call:
        - first, detect that child (L) and self (N) are same color - violation!
        - rotate right on N -> will return pointer to L when returning from this recursive call
        - a second rotation required -> rotate left again on P -> this again returns pointer to L
        - eg. recursive stack is P, N, L and we call the balance function on N, examining the child that was inserted for a conflict
            - if a double rotation is required, return a pointer to L??
            - then P will set right child to be L if we use pointer reinforcement... wrong!
    - The trick is to call balance on the GRANDPARENT instead.
        - eg. https://zarif98sjs.github.io/blog/blog/redblacktree/
    - But this means we need to check more directions when doing the balancing (grandparent has to check all grandchildren to detect conflicts)