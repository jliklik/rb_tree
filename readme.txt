Insertion:
- BIG IDEA: check color of uncle
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

Deletion:
- BIG IDEA: check color of sibling
- Deletion via method 1: Double black method (bottom-up)
  - https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13c.pdf
  - https://ebooks.inflibnet.ac.in/csp01/chapter/red-black-trees-ii/
  - if node has no children that are leaf nodes
    find predecessor (or successor)
    put predecessor/successor value in node
    delete predecessor/successor node
    if node was red, color it black
    if node was black:
    - Case 1 if sibling is black and one of sibling's children is red, perform restructure
          - restructure 1-1 (line):
            - single rotate around parent of node/sibling (in direction to bring sibling up)
          - restructure 1-2 (triangle):
            - single rotate around sibling
            - rotate again around parent to bring grandchild up
    - Case 2 if sibling is black and both sibling's children are black
          - recoloring
          - make sibling red
          - continue upwards
    - Case 3: if sibling is red
          - adjustment
          - rotate around parent to bring sibling up
- Deletion via method 2: Multi-case method (top-down)
  - https://www.youtube.com/watch?v=eoQpRtMpA9I
  - 3 nodes to consider: node being deleted, the replacement, x (differs depending on condition)
  - not really recursive, so many cases 0.0 
  - Step 1: delete
    - If node that was deleted has 2 NIL children, then its replacement x is NIL
    - If node that was deleted has 1 NIL and 1 non-NIL child, then its replacement, x, is the non-NIL child
       - Replace node with non-NIL child
       - x is the replacement
    - If node that was deleted has 2 non-NIL children, set x to successor's right child. 
        - Replace node to delete with the successor, delete successor node
        - NOTE! In this case x IS NOT the replacement BUT IS the replacement's RIGHT CHILD
  - Step 2: recolor
    - Case 1: If deleted node is red and its replacement is red - done
    - Case 2: If node we deleted is black and its replacement is red - color replacement black - done
    - Case 3: If node we deleted is red and its replacement is black (not NIL), color replacement red - continue
    - Case 4: If node we deleted is black and its replacement is black, and x is root - done
    - Case 5: If node we deleted is black and its replacement is black, and x is not the root - continue
  - Step 3: fixup
    - Case 0: x is red - Make node black. We are done
    - Case 1: x is black and sibling w is red
      - Color sibling w black
      - Color parent red
      - Rotate parent
        - if x is left child do a left rotation
        - if x is right child do a right rotation
      - Change w
        - If x is left child, w = parent.right
        - If x is right child, w = parent.left
        - Decide on case 2, 3, or 4 with new w
    - Case 2: x is black, w is black, both of w's children are black
      - Color w red
      - Set x = x's parent
        - a. if new x is red, color x black -> done
        - b. if new x is black and is the root -> done
        - c. if new x is black and not root -> call fix up again with new x
    - Case 3: x is black, w is black
      - a. x is left child, w's left child is red, w's left child is black
      - b. x is right child, w's right child is red, w's left child is black
    - Case 4: x is black, w is black
      - a. x is left child, w's right child is red
      - b. x is right child, w's left child is red

References:
- https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
