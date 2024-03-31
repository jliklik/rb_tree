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

            pub fn set_left(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }

            pub fn set_right(self: *Node, left_node: *Node) void {
                self.left = left_node;
            }
        };

        root: ?*Node = null,
        black_neight: u32 = 0,
        allocator: std.mem.Allocator,

        pub fn new(allocator: std.mem.Allocator) Self {
            return .{ .black_neight = 0, .root = null, .allocator = allocator };
        }

        /// Create a new node
        /// By default, new nodes created should be the color red
        fn create_node(self: *Self, data: T) !*Node {
            const node = try self.allocator.create(Node);
            node.* = .{ .data = data, .left = null, .right = null, .color = Color.red, .frequency = 1 };
            return node;
        }

        pub fn insert(self: *Self, data: T) !void {
            self.root = try do_insert(self, data, self.root);
            if (self.root) |root| {
                root.color = Color.black;
            }
        }

        fn do_insert(self: *Self, data: T, node: ?*Node) !*Node {
            if (node) |n| {
                if (data < n.data) {
                    n.left = try do_insert(self, data, n.left);
                    if (n.left) |left| {
                        var new_n = try rebalance(n, left, left.left);
                        new_n = try rebalance(new_n, left, left.right);
                        return new_n;
                    }
                } else if (data > n.data) {
                    n.right = try do_insert(self, data, n.right);
                    if (n.right) |right| {
                        var new_n = try rebalance(n, right, right.left);
                        new_n = try rebalance(new_n, right, right.right);
                        return new_n;
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
                return l;
            } else {
                return RotationError.right_child_is_nil;
            }
        }

        // https://www.youtube.com/watch?v=A3JZinzkMpk
        // https://www.cs.purdue.edu/homes/ayg/CS251/slides/chap13b.pdf
        fn rebalance(self: *Node, child: *Node, grandchild: ?*Node) !*Node {
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
                    return self;
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
                        self.right = try rotate_right(child);
                        const node_to_return = try rotate_left(self);
                        child.color = Color.black;
                        self.color = Color.red;
                        return node_to_return;
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
                        child.color = Color.black;
                        self.color = Color.red;
                        return node_to_return;
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
                        return node_to_return;
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
                        child.color = Color.black;
                        self.color = Color.red;
                        return node_to_return;
                    }
                }
                return self;
            } else {
                return self;
            }
        }

        pub fn level_order_transversal(self: *Self) !void {
            std.debug.print("{s} ", .{" || "});

            if (self.root) |root| {
                var q = queue.Queue(*Node).new(self.allocator);
                try q.push(root);

                while (!q.is_empty()) {
                    const rbtree_node = q.pop();
                    if (rbtree_node) |rbn| {
                        var color = "B";
                        if (rbn.color == Color.red) {
                            color = "R";
                        }
                        std.debug.print("{}{s} ", .{ rbn.data, color });
                        if (rbn.left) |left| {
                            try q.push(left);
                        }
                        if (rbn.right) |right| {
                            try q.push(right);
                        }
                    }
                }
            } else {
                return;
            }
        }
    };
}

test "create red black tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var rbtree = RedBlackTree(u32).new(allocator);
    try rbtree.insert(5);
    try rbtree.level_order_transversal();
    try rbtree.insert(3);
    try rbtree.level_order_transversal();
    try rbtree.insert(2);
    try rbtree.level_order_transversal();
    try rbtree.insert(4);
    try rbtree.level_order_transversal();
    try rbtree.insert(7);
    try rbtree.level_order_transversal();
}
