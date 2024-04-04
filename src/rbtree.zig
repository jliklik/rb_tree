const std = @import("std");
const queue = @import("queue.zig");

pub fn RedBlackTree(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Color = enum { black, red };

        pub const RotationError = error{ right_child_is_nil, left_child_is_nil };

        pub const Node = struct {
            left: ?*Node = null,
            right: ?*Node = null,
            data: T,
            color: Color = Color.black,
            frequency: u32 = 1,
            height: u32 = 0,

            pub fn set_left(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }

            pub fn set_right(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }
        };

        root: ?*Node = null,
        black_height: u32 = 0,
        allocator: std.mem.Allocator,

        pub fn new(allocator: std.mem.Allocator) Self {
            return .{ .black_height = 0, .root = null, .allocator = allocator };
        }

        /// Returns the height of a node
        fn height(left: ?*Node, right: ?*Node) u32 {
            if (left) |l| {
                if (right) |r| {
                    if (l.height > r.height) {
                        return l.height + 1;
                    }
                    return r.height + 1;
                }
                return l.height + 1;
            } else if (right) |r| {
                return r.height + 1;
            } else {
                return 0; // both left and right are null
            }
        }

        /// Create a new node
        /// By default, new nodes created should be the color red
        fn create_node(self: *Self, data: T) !*Node {
            const node = try self.allocator.create(Node);
            node.* = .{ .data = data, .left = null, .right = null, .color = Color.red, .frequency = 1, .height = 0 };
            return node;
        }

        pub fn insert(self: *Self, data: T) !void {
            self.root = try do_insert(self, data, self.root);
            if (self.root) |root| {
                root.color = Color.black; // Root is always black - recolor it if it isn't
            }
        }

        fn do_insert(self: *Self, data: T, node: ?*Node) !*Node {
            if (node) |n| {
                // std.debug.print("At node: {} ", .{n.data});
                if (data < n.data) {
                    n.left = try do_insert(self, data, n.left);
                    if (n.left) |left| {
                        var new_n = n;
                        new_n.height = height(left, n.right);
                        // std.debug.print("{s} ", .{" < "});
                        // _ = try self.do_level_order_transversal(new_n);
                        // std.debug.print("{s} ", .{" << "});
                        var rebalanced = try rebalance(new_n, left, left.left);
                        var rebalanced_n = rebalanced.node;
                        // _ = try self.do_level_order_transversal(rebalanced_n);
                        if (!rebalanced.modified) {
                            // std.debug.print("{s} ", .{" <<< "});
                            rebalanced = try rebalance(new_n, left, left.right);
                            rebalanced_n = rebalanced.node;
                            // _ = try self.do_level_order_transversal(rebalanced_n);
                            return rebalanced_n;
                        }
                        return rebalanced_n;
                    }
                } else if (data > n.data) {
                    n.right = try do_insert(self, data, n.right);
                    if (n.right) |right| {
                        var new_n = n;
                        new_n.height = height(n.left, right);
                        // std.debug.print("{s} ", .{" > "});
                        // _ = try self.do_level_order_transversal(new_n);
                        // std.debug.print("{s} ", .{" >> "});
                        var rebalanced = try rebalance(n, right, right.left);
                        var rebalanced_n = rebalanced.node;
                        // _ = try self.do_level_order_transversal(rebalanced_n);
                        if (!rebalanced.modified) {
                            // std.debug.print("{s} ", .{" >>> "});
                            rebalanced = try rebalance(new_n, right, right.right);
                            rebalanced_n = rebalanced.node;
                            // _ = try self.do_level_order_transversal(rebalanced_n);
                            return rebalanced_n;
                        }
                        return rebalanced_n;
                    }
                } else {
                    n.frequency += 1;
                }
                return n;
            } else {
                const new_node = try create_node(self, data);
                return new_node;
            }
        }

        fn get_sibling(parent: *Node, node: *Node) ?*Node {
            if (parent.left == node) {
                return parent.right;
            } else {
                return parent.left;
            }
        }

        fn red(node: ?*Node) bool {
            if (node) |n| {
                return (n.color == Color.red);
            } else {
                return false;
            }
        }

        // https://www.happycoders.eu/algorithms/avl-tree-java/
        //     N             R
        //    / \           / \
        //   L   R         N   RR
        //      / \       / \
        //    RL   RR    L   RL
        // Step 1: N right child becomes RL
        // Step 2: R left child becomes node
        fn rotate_left(node: *Node) !*Node {
            const right_child = node.right;
            if (right_child) |r| {
                node.right = r.left;
                r.left = node;
                // update heights of N and R
                node.height = height(node.left, node.right);
                r.height = height(r.left, r.right);
                return r;
            } else {
                return RotationError.right_child_is_nil;
            }
        }

        // https://www.happycoders.eu/algorithms/avl-tree-java/
        //         N             L
        //        / \           / \
        //       L   R         LL  N
        //      / \               / \
        //     LL  LR            LR  R
        // Step 1: N left child becomes LR
        // Step 2: L right child becomes node
        fn rotate_right(node: *Node) !*Node {
            const left_child = node.left;
            if (left_child) |l| {
                node.left = l.right;
                l.right = node;
                // update heights of N and L
                node.height = height(node.left, node.right);
                l.height = height(l.left, l.right);
                return l;
            } else {
                return RotationError.right_child_is_nil;
            }
        }

        /// https://www.youtube.com/watch?v=A3JZinzkMpk
        /// https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
        /// Returns struct of .{modified? (T/F), new grandparent node}
        fn rebalance(self: *Node, child: *Node, grandchild: ?*Node) !struct { modified: bool, node: *Node } {
            if (grandchild) |gc| {
                // Case 1: Both parent and uncle are red
                //
                //      Before:                  After:
                //
                //      GP(B)                   GP(R!)
                //     /    \                  /     \
                //    P(R)   U(R)            P(B!)   U(B!)
                //   /                      /
                //  Z(R)                  Z(R)
                //
                // Set P and U to black
                // Set GP to Red
                const uncle = get_sibling(self, child);
                if (red(gc) and red(uncle)) {
                    child.color = Color.black;
                    if (uncle) |u| {
                        u.color = Color.black;
                    }
                    self.color = Color.red;
                    std.debug.print("{s} ", .{"Case 1"});
                    return .{ .modified = true, .node = self };
                } else if (red(gc) and red(child) and !red(uncle)) {
                    // Case 2-1: L uncle's is black and P, GP, L form a triangle (double rotation)
                    //
                    //          Before:           After rotate right on P:     After rotate left on GP:          Recolor:
                    //
                    //           GP(B)                 GP(B)                          L(R)                         L(B!)
                    //          /   \                 /   \                          /    \                       /    \
                    //        U(B)   P(R)           U(B)   L(R)                    GP(B)   P(R)               GP(R!)    P(R)
                    //               /   \                /   \                    / \     /  \                / \      /  \
                    //             L(R)   R             LL    P(R)              U(B)  LL  LR   R            U(B)  LL   LR   R
                    //            / \                         /  \
                    //          LL   LR                     LR    R
                    //
                    if (gc == child.left and child == self.right) {
                        // Double rotation
                        self.right = try rotate_right(child); // child is P
                        const node_to_return = try rotate_left(self); // self is GP
                        gc.color = Color.black;
                        self.color = Color.red;
                        std.debug.print("{s} ", .{"Case 2-1"});
                        return .{ .modified = true, .node = node_to_return };
                    }
                    // Case 2-2: R uncle's is black and P, GP, R form a triangle (double rotation)
                    //
                    //          Before:           After rotate left on P:     After rotate right on GP:          Recolor:
                    //
                    //          GP(B)                    GP(B)                      R(R)                           R(B!)
                    //          /   \                    /   \                     /   \                          /   \
                    //        P(R)   U(B)              R(R)  U(B)                P(R)  GP(B)                    P(R)  GP(R!)
                    //        /   \                    /  \                     /  \   /  \                    /  \   /  \
                    //       L   R(R)               P(R)   RR                  L   RL RR  U(B)                L   RL RR  U(B)
                    //            / \               /  \
                    //          RL   RR            L    RL
                    //
                    else if (gc == child.right and child == self.left) {
                        // Double rotation
                        self.left = try rotate_left(child);
                        const node_to_return = try rotate_right(self);
                        gc.color = Color.black;
                        self.color = Color.red;
                        std.debug.print("{s} ", .{"Case 2-2"});
                        return .{ .modified = true, .node = node_to_return };
                    }
                    // Case 3-1: L uncle's is black and P, GP, L form a line (single rotation)
                    //
                    //          Before:              After rotate left on GP:         Recolor:
                    //
                    //           GP(B)                     P(R)                         P(B!)
                    //          /   \                     /    \                       /    \
                    //        U(B)   P(R)               GP(B)   R(R)               GP(R!)    R(R)
                    //              /   \               / \     /  \                / \      /  \
                    //             L    R(R)         U(B)  L  RL    RR           U(B)  L   RL    RR
                    //                  /  \
                    //                RL    RR
                    //
                    else if (gc == child.right and child == self.right) {
                        const node_to_return = try rotate_left(self);
                        child.color = Color.black;
                        self.color = Color.red;
                        std.debug.print("{s} ", .{"Case 3-1"});
                        return .{ .modified = true, .node = node_to_return };
                    }
                    // Case 3-2: L uncle's is black and P, GP, L form a line (single rotation)
                    //
                    //          Before:              After rotate right on GP:        Recolor:
                    //
                    //           GP(B)                    P(R)                         P(B!)
                    //          /   \                    /    \                       /    \
                    //        P(R)   U(B)             L(R)     GP(B)               L(R)   GP(R!)
                    //       /   \                    /  \     /  \                / \      /  \
                    //     L(R)   R                 LL   LR   R   U(B)           LL   LR   R   U(B)
                    //     /  \
                    //   LL    LR
                    //
                    else if (gc == child.left and child == self.left) {
                        const node_to_return = try rotate_right(self);
                        child.color = Color.black; // P
                        self.color = Color.red; // GP
                        std.debug.print("{s} ", .{"Case 3-2"});
                        return .{ .modified = true, .node = node_to_return };
                    }
                }
                return .{ .modified = false, .node = self };
            } else {
                return .{ .modified = false, .node = self };
            }
        }

        pub fn delete(self: *Self, data: T) !void {}

        /// Double black case
        /// http://mainline.brynmawr.edu/Courses/cs246/spring2016/lectures/16_RedBlackTrees.pdf
        pub fn do_delete(self: *Self, data: T, node: ?*Node) !*Node {

            // Step 1: Do normal BST deletion
            // - may have to find successor and replace the node's value with the successor's value
            // - then delete the successor node
            // Note: Either we end up deleting the node itself (leaf), or we end up deleting the successor (leaf or only one child)
            // Step 2: Recolor
            // - look at the node to be deleted (this would be the successor if it applies)
            // - Let u be the node to be deleted (either the original node or the successor node) and v be the child that replaces u.
            // - if u has no children, v is NIL and black
            // - if one child, v, the replacement, is u's child
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
            // Step 3: Dealing with DOUBLE BLACKS - when both u and v are black
            // - v becomes DOUBLE BLACK when it replaces u
            // - let the parent of V be P and its sibling be S
            // - 3a: V's sibling, S, is red -> rotate P to bring up S, recolor S and P. Continue to cases 3b, 3c, 3d
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
            // - 3c: S is black, S's child further away from V is RED, other child (closer to V) is any color
            //    - rotate P to bring S up
            //    - swap colors of S and P, make S's RED child BLACK -> DONE
            // - 3d: S is black, S's child further away from V is BLACK, other child (closer to V) is RED
            //    - rotate S to bring up S's RED child
            //    - swap color of S and S's original RED child
            //    - proceed to case 3c
            //
            // So how can you do pointer reinforcement with this method??
            // 1) if have to replace data with data in successor - swap data, but keep recursing until you reach the value to delete (will be in successor) then call DELETE
            // 2) DELETE_FIX_UP should be called on the parent -> this allows us to return the same link for cases 3b, 3c, 3d
            // - (eg. parent checks if child is double black)
            // - But Case 3a causes problems -> we move the problem DOWN THE TREE instead of UP THE TREE, which means we can't get out of recursive call
            //
            // pseudocode
            //
            // fn delete(node) -> node {
            //     if node.value == value {
            //        step 2 - recolor;
            //        return node;
            //     } else if value > node.value {
            //        node.right_child = delete(node.right_child)
            //        return fix_double_black(node, right)
            //     }
            //     else { same thing for left child case }
            //
            //  }
            //
            //  fn fix double_black(node (P), dir) -> node {
            //     if node.dir_child (V) has double black {
            //         case 3b: 3b recolor, return node
            //         case 3c: 3c rotate, recolor, return S in place of P
            //         case 3d: 3d rotate and recolor, return SL in place of P
            //         case 3a: 3a rotate and recolor, node.dir_child = fix_double_black(node.dir_child), return node
            //     }
            // }

        }

        pub fn level_order_transversal(self: *Self) ![]u8 {
            // std.debug.print("{s} ", .{" || "});

            var str: []u8 = "";

            if (self.root) |root| {
                str = try do_level_order_transversal(self, root);
            }
            return str;
        }

        pub fn do_level_order_transversal(self: *Self, node: *Node) ![]u8 {
            var str: []u8 = "";
            var q = queue.Queue(*Node).new(self.allocator);
            try q.push(node);

            while (!q.is_empty()) {
                const rbtree_node = q.pop();
                if (rbtree_node) |rbn| {
                    var color = "B";
                    if (rbn.color == Color.red) {
                        color = "R";
                    }

                    str = try std.fmt.allocPrint(self.allocator, "{s}{}{s}{},", .{ str, rbn.data, color, rbn.height });

                    // std.debug.print("{}{s}{} ", .{ rbn.data, color, rbn.height });
                    if (rbn.left) |left| {
                        try q.push(left);
                    }
                    if (rbn.right) |right| {
                        try q.push(right);
                    }
                }
            }

            return str;
        }
    };
}

test "red black tree insert 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new(allocator);
    try rbtree.insert(5);
    try rbtree.insert(3);
    var res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "5B1,3R0,", res));
    try rbtree.insert(2);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "3B1,2R0,5R0,", res)); // case 3
    try rbtree.insert(4);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "3B2,2B0,5B1,4R0,", res)); // case 1
    try rbtree.insert(10);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "3B2,2B0,5B1,4R0,10R0,", res)); // case 1
    try rbtree.insert(9);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "3B3,2B0,5R2,4B0,10B1,9R0,", res)); // case 1
}

test "red black tree insert 2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new(allocator);
    try rbtree.insert(8);
    try rbtree.insert(5);
    try rbtree.insert(15);
    try rbtree.insert(12);
    try rbtree.insert(19);
    try rbtree.insert(9);
    try rbtree.insert(13);
    try rbtree.insert(23);
    var res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "8B3,5B0,15R2,12B1,19B1,9R0,13R0,23R0,", res));
    try rbtree.insert(10);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "12B3,8R2,15R2,5B0,9B1,13B0,19B1,10R0,23R0,", res));
}

test "red black tree insert 3" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new(allocator);
    try rbtree.insert(8);
    try rbtree.insert(2);
    try rbtree.insert(15);
    try rbtree.insert(1);
    try rbtree.insert(5);
    try rbtree.insert(0);
    try rbtree.insert(3);
    try rbtree.insert(7);
    var res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "8B3,2R2,15B0,1B1,5B1,0R0,3R0,7R0,", res));
    try rbtree.insert(6);
    res = try rbtree.level_order_transversal();
    std.debug.assert(std.mem.eql(u8, "5B3,2R2,8R2,1B1,3B0,7B1,15B0,0R0,6R0,", res));
}
