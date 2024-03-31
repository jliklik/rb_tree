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
    - eg. let's call the balance function on node P, after L was visited.
        - in the case of a double rotation:                    
          Before:              After rotate right on P:     After rotate left on GP:          Recolor:

           GP(B)                    GP(B)                          L(R)                         L(B!)
          /   \                    /   \                          /    \                       /    \
        U(B)   P(R)              U(B)   L(R)                    GP(B)   P(R)               GP(R!)    P(R)
               /   \                   /   \                    / \     /  \                / \      /  \
             L(R)   R                LL    P(R)              U(B)  LL  LR   R            U(B)  LL   LR   R
            / \                            /  \
          LL   LR                        LR    R
        Balance on return from recursive call:
        - first, detect that child (L) and parent (P) are same color - violation!
        - rotate right on P -> will return pointer to L when returning from this recursive call
        - a second rotation required -> rotate left again on GP -> this again returns pointer to L
        - eg. nodes visited on the stack were GP, P, then L. We called the balance function on P, examining the child that was inserted for a conflict
            - if a double rotation is required, a pointer to L is returned... but this causes issues! Because a pointer to L is returned when
              we were balancing node P.
            - This means GP will set its right child to be L when we finish this recursive call and use pointer reinforcement... this is wrong!
    - The trick is to call balance on the GRANDPARENT instead.
        - eg. https://zarif98sjs.github.io/blog/blog/redblacktree/
    - But this means we need to check more directions when doing the balancing (grandparent has to check all grandchildren to detect conflicts)

References:
- https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
