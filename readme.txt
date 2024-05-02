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
- Bottom up method:
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
- Another way of looking at the bottom up method (pure actions, no theory)
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

  Method we choose:

// DELETE Step 1: Do normal BST deletion
// - may have to find successor and replace the node's value with the successor's value
// - then delete the successor node
// Note: Either we end up deleting the node itself (leaf), or we end up deleting the successor (leaf or only one child)

// DELETE Step 2: Recolor
// - look at the node to be deleted (this would be the successor if it applies)
// - Let u be the node to be deleted (either the original node or the successor node) and v be the child that replaces u.
// - if u has no children, v is NIL and black
// - if u has one one child, v, the replacement, is u's child
// - u CANNOT have 2 children, otherwise we have not found the successor properly
// - u AND v cannot be red as then this would not have been a valid rb tree
// - 2a: if u is red and v is black, simply replace u with v - DONE
//    Before:      After:
//     U (R)        V(B)
//      \
//       V (B)
// - 2b: if u is black and v is red, then when v replaces u, mark v as black - DONE
//    Before:      After:         After2:
//     U(B)         V(R)           V(B!)
//      \
//       V(R)
// - 2c: if u is black and v is black - we get a DOUBLE BLACK - proceed to step 3

// Step 3: Dealing with DOUBLE BLACKS - when both U and V are black
// - V becomes DOUBLE BLACK when it replaces U
// - let P = the parent of V
// - let S = the sibling of V

// - 3a: V's sibling, S, is red -> rotate P to bring up S, recolor S and P.
// Continue to cases 3b, 3c, 3d
//
//    Before:               After:            After2:
//        P(B)               S(R)              S(B!)
//      /     \             /   \             /   \
//     V(DB)  S(R)        P(B)  SR          P(R!)  SR
//           /   \       /    \            /    \
//          SL   SR     V(DB)  SL        V(DB)   SL


// - 3b: V's sibling, S, is black and has two black children
//    - recolor S red
//    - if P is red -> make P black (absorbs V's blackness) -> DONE
//    - if P is black -> now P is double black - reiterate up the tree (Call cases 3a-d on P)
//    - or in the case of pointer reinforcement, simply return the parent node as a double black
//
//    Before:              If P was Red:          If P was Black:
//        P(B)                P(B!)                    P(DB!)
//      /     \              /     \                   /   \
//     V(DB)  S(B)         V(B!)  S(R!)             V(B!)  S(R!)
//           /   \                /   \                    /   \
//        SL(B)   SR(B)        SL(B) SR(B)              SL(B) SR(B)

// - 3c: S is black, S's child further away from V is RED, other child (closer to V) is any color
//    - rotate P to bring S up
//    - swap colors of S and P, make S's RED child BLACK -> DONE
//
//       Before:                 After:            After2:
//        P(X)                   S(B)              S(X!)
//       /    \                 /   \             /   \
//     V(DB)  S(B)            P(X)   SR(R)      P(B!)  SR(B!)
//           /   \           /    \            /    \
//          SL   SR(R)    V(DB)    SL        V(B!)    SL

// - 3d: S is black, S's child further away from V is BLACK, other child (closer to V) is RED
//    - rotate S to bring up S's RED child
//    - swap color of S and S's original RED child
//    - proceed to case 3c
//
//

  - So how can you do pointer reinforcement with this method??
  -  If have to replace data with data in successor - swap data, but keep recursing until you reach the value to delete (will be in successor) then call DELETE
  -  DELETE_FIX_UP should be called on the parent -> this allows us to return the same link for cases 3b, 3c, 3d
    - (eg. parent checks if child is double black)
    - But Case 3a causes problems -> we move the problem DOWN THE TREE instead of UP THE TREE, which means we can't get out of recursive call just yet
      - we have to recurse down the tree again, calling delete_fix_up on P again
      
      pseudocode:

      fn delete(node) -> node {
        if node.value == value {
            step 2 - recolor;
            return node;
        } else if value > node.value {
            node.children[Direction.right] = delete(node.children[Direction.right])
            return fix_double_black(node, right)
        }
        else {
            node.children[Direction.left]_child = delete(node.children[Direction.left])
            return fix_double_black(node, left)
        }
              }
              fn fix double_black(node (P), dir) -> node {
        if node.dir_child (V) has double black {
            case 3b: 3b recolor, return node
            case 3c: 3c rotate, recolor, return S in place of P
            case 3d: 3d rotate and recolor, return SL in place of P
            case 3a: 3a rotate and recolor, node.dir_child = fix_double_black(node.dir_child), return node
        }
    }


References:
- https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
